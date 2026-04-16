#!/usr/bin/env bash

# Session references are typed: "codex:<uuid>" or "claude:<uuid>"
# Plain UUIDs (legacy callers) are treated as codex.

DEV_KIT_SESSION_PATH_CACHE_KEY=""
DEV_KIT_SESSION_PATH_CACHE_VALUE=""
DEV_KIT_DISCOVERED_SESSION_CACHE_KEY=""
DEV_KIT_DISCOVERED_SESSION_CACHE_VALUE=""
DEV_KIT_SESSION_CONTENT_CACHE_KEY=""
DEV_KIT_SESSION_CONTENT_CACHE_VALUE=""

# ── ref helpers ────────────────────────────────────────────────────────────────

dev_kit_learning_ref_source() {
  case "$1" in
    claude:*) printf "claude" ;;
    codex:*)  printf "codex"  ;;
    *)        printf "codex"  ;;  # backward compat: plain UUID = codex
  esac
}

dev_kit_learning_ref_id() {
  printf "%s" "${1#*:}"
}

# ── path expansion ─────────────────────────────────────────────────────────────

dev_kit_learning_expand_path() {
  local value="$1"
  value="${value/\$CODEX_HOME/${CODEX_HOME:-$HOME/.codex}}"
  value="${value/\$CLAUDE_PROJECTS_ROOT/${CLAUDE_PROJECTS_ROOT:-}}"
  case "$value" in
    "~"*) value="${HOME}${value#\~}" ;;
  esac
  printf "%s\n" "$value"
}

# ── enabled sources ────────────────────────────────────────────────────────────

dev_kit_learning_enabled_sources() {
  # DEV_KIT_LEARN_SOURCES env var overrides config (comma or space separated)
  if [ -n "${DEV_KIT_LEARN_SOURCES:-}" ]; then
    printf "%s\n" "$DEV_KIT_LEARN_SOURCES" | tr ',' '\n' | tr ' ' '\n' | grep -v '^$'
    return 0
  fi
  dev_kit_learning_config_enabled_sources 2>/dev/null || printf "claude\ncodex\n"
}

# ── codex session discovery ────────────────────────────────────────────────────

dev_kit_learning_session_roots() {
  local root=""
  while IFS= read -r root; do
    [ -n "$root" ] || continue
    dev_kit_learning_expand_path "$root"
  done <<EOF
$(dev_kit_learning_source_discovery_list "local_session_roots")
EOF
}

dev_kit_learning_codex_recent_session_paths() {
  local lastrun_file="${1:-}"
  local max_recent="${2:-6}"
  local root=""

  {
    while IFS= read -r root; do
      [ -d "$root" ] || continue
      if [ -n "$lastrun_file" ] && [ -f "$lastrun_file" ]; then
        find "$root" -type f -name '*.jsonl' -newer "$lastrun_file" -print 2>/dev/null
      else
        find "$root" -type f -name '*.jsonl' -print 2>/dev/null
      fi
    done <<EOF
$(dev_kit_learning_session_roots)
EOF
  } | sort -r | awk '!seen[$0]++' | head -"$max_recent"
}

dev_kit_learning_codex_session_id_from_path() {
  basename "$1" | sed -E 's/.*-([0-9a-f-]{36})\.jsonl/\1/'
}

dev_kit_learning_codex_session_path_for_id() {
  local session_id="$1"
  local session_path=""

  [ -n "$session_id" ] || return 1

  if [ "$DEV_KIT_SESSION_PATH_CACHE_KEY" = "codex:${session_id}" ]; then
    printf "%s" "$DEV_KIT_SESSION_PATH_CACHE_VALUE"
    return 0
  fi

  while IFS= read -r session_path; do
    [ -n "$session_path" ] || continue
    if [ "$(dev_kit_learning_codex_session_id_from_path "$session_path")" = "$session_id" ]; then
      DEV_KIT_SESSION_PATH_CACHE_KEY="codex:${session_id}"
      DEV_KIT_SESSION_PATH_CACHE_VALUE="$session_path"
      printf "%s" "$session_path"
      return 0
    fi
  done <<EOF
$(dev_kit_learning_codex_recent_session_paths)
EOF

  DEV_KIT_SESSION_PATH_CACHE_KEY="codex:${session_id}"
  DEV_KIT_SESSION_PATH_CACHE_VALUE=""
}

dev_kit_learning_codex_session_cwd() {
  local session_path="$1"
  [ -n "$session_path" ] || return 0

  awk '
    $0 ~ /"type":"session_meta"/ && match($0, /"cwd":"[^"]*"/) {
      value = substr($0, RSTART, RLENGTH)
      sub(/^"cwd":"/, "", value)
      sub(/"$/, "", value)
      print value
      exit
    }
  ' "$session_path"
}

# ── claude session discovery ───────────────────────────────────────────────────

dev_kit_learning_claude_projects_root_path() {
  # CLAUDE_PROJECTS_ROOT env var overrides config
  if [ -n "${CLAUDE_PROJECTS_ROOT:-}" ]; then
    printf "%s\n" "$CLAUDE_PROJECTS_ROOT"
    return 0
  fi
  local root
  root="$(dev_kit_learning_claude_projects_root 2>/dev/null || true)"
  [ -n "$root" ] || root="~/.claude/projects"
  dev_kit_learning_expand_path "$root"
}

dev_kit_learning_claude_history_path() {
  local path="${CLAUDE_HISTORY_FILE:-$HOME/.claude/history.jsonl}"
  dev_kit_learning_expand_path "$path"
}

dev_kit_learning_claude_project_id() {
  # Claude project dirs are path-shaped but sanitize punctuation like dots:
  # /a/b/dev.kit -> -a-b-dev-kit
  printf "%s" "$1" | sed -E 's|/|-|g; s|[^[:alnum:]_-]|-|g; s|-+|-|g'
}

dev_kit_learning_claude_project_dir() {
  local repo_dir="$1"
  printf "%s/%s" \
    "$(dev_kit_learning_claude_projects_root_path)" \
    "$(dev_kit_learning_claude_project_id "$repo_dir")"
}

dev_kit_learning_claude_recent_session_paths() {
  local repo_dir="$1"
  local lastrun_file="${2:-}"
  local max_recent="${3:-6}"
  local history_path since_epoch
  history_path="$(dev_kit_learning_claude_history_path)"
  since_epoch="0"

  if [ -n "$lastrun_file" ] && [ -f "$lastrun_file" ]; then
    since_epoch="$(cat "$lastrun_file" 2>/dev/null || printf '0')"
  fi

  if [ -f "$history_path" ]; then
    dev_kit_learning_claude_recent_session_paths_from_history "$repo_dir" "$since_epoch" "$max_recent"
    return 0
  fi

  dev_kit_learning_claude_recent_session_paths_from_project_dir "$repo_dir" "$lastrun_file" "$max_recent"
}

dev_kit_learning_claude_recent_session_paths_from_project_dir() {
  local repo_dir="$1"
  local lastrun_file="${2:-}"
  local max_recent="${3:-6}"
  local project_dir

  project_dir="$(dev_kit_learning_claude_project_dir "$repo_dir")"
  [ -d "$project_dir" ] || return 0

  if [ -n "$lastrun_file" ] && [ -f "$lastrun_file" ]; then
    find "$project_dir" -maxdepth 1 -type f -name '*.jsonl' -newer "$lastrun_file" -print 2>/dev/null
  else
    find "$project_dir" -maxdepth 1 -type f -name '*.jsonl' -print 2>/dev/null
  fi | sort -r | head -"$max_recent"
}

dev_kit_learning_claude_recent_session_paths_from_history() {
  local repo_dir="$1"
  local since_epoch="${2:-0}"
  local max_recent="${3:-6}"
  local history_path projects_root

  history_path="$(dev_kit_learning_claude_history_path)"
  projects_root="$(dev_kit_learning_claude_projects_root_path)"
  [ -f "$history_path" ] || return 0
  [ -d "$projects_root" ] || return 0

  awk -v project="$repo_dir" -v since_epoch="$since_epoch" '
    index($0, "\"project\":\"" project "\"") {
      ts = ""
      sid = ""
      if (match($0, /"timestamp":[0-9]+/)) {
        ts = substr($0, RSTART + 12, RLENGTH - 12)
      }
      if (match($0, /"sessionId":"[^"]+"/)) {
        sid = substr($0, RSTART + 13, RLENGTH - 14)
      }
      if (sid == "" || ts == "") next
      if ((ts / 1000) < since_epoch) next
      if (!seen[sid] || ts > seen_ts[sid]) {
        seen[sid] = 1
        seen_ts[sid] = ts
      }
    }
    END {
      for (sid in seen) {
        printf "%s|%s\n", seen_ts[sid], sid
      }
    }
  ' "$history_path" \
    | sort -t'|' -k1,1nr \
    | head -"$max_recent" \
    | while IFS='|' read -r _ts sid; do
        [ -n "$sid" ] || continue
        dev_kit_learning_claude_session_path_for_id "$sid" "$repo_dir"
        printf '\n'
      done \
    | awk 'NF && !seen[$0]++'
}

dev_kit_learning_claude_session_path_for_id() {
  local session_id="$1"
  local repo_dir="${2:-$(pwd)}"
  local path

  [ -n "$session_id" ] || return 0

  path="$(dev_kit_learning_claude_project_dir "$repo_dir")/${session_id}.jsonl"
  if [ -f "$path" ]; then
    printf "%s" "$path"
    return 0
  fi

  path="$(
    find "$(dev_kit_learning_claude_projects_root_path)" -maxdepth 2 -type f -name "${session_id}.jsonl" 2>/dev/null \
      | head -n 1
  )"
  [ -f "$path" ] && printf "%s" "$path"
}

# ── unified session path resolution ───────────────────────────────────────────

dev_kit_learning_session_path() {
  local ref="$1"
  local repo_dir="${2:-$(pwd)}"
  local source id

  source="$(dev_kit_learning_ref_source "$ref")"
  id="$(dev_kit_learning_ref_id "$ref")"

  if [ "$DEV_KIT_SESSION_PATH_CACHE_KEY" = "${source}:${id}" ]; then
    printf "%s" "$DEV_KIT_SESSION_PATH_CACHE_VALUE"
    return 0
  fi

  local path=""
  case "$source" in
    claude) path="$(dev_kit_learning_claude_session_path_for_id "$id" "$repo_dir")" ;;
    *)      path="$(dev_kit_learning_codex_session_path_for_id "$id")" ;;
  esac

  DEV_KIT_SESSION_PATH_CACHE_KEY="${source}:${id}"
  DEV_KIT_SESSION_PATH_CACHE_VALUE="$path"
  printf "%s" "$path"
}

# ── multi-source session collection ───────────────────────────────────────────

# Returns "source:id" lines for all enabled sources, capped per-source,
# filtering sessions older than lastrun_file when provided.
dev_kit_learning_all_session_refs() {
  local repo_dir="${1:-$(pwd)}"
  local lastrun_file="${2:-}"
  local max_recent source session_path session_id

  max_recent="$(dev_kit_learning_source_discovery_scalar "max_recent_sessions" 2>/dev/null || true)"
  [ -n "$max_recent" ] || max_recent="6"

  while IFS= read -r source; do
    [ -n "$source" ] || continue
    case "$source" in
      codex)
        while IFS= read -r session_path; do
          [ -n "$session_path" ] || continue
          session_id="$(dev_kit_learning_codex_session_id_from_path "$session_path")"
          [ -n "$session_id" ] || continue
          # verify cwd matches repo
          local cwd
          cwd="$(dev_kit_learning_codex_session_cwd "$session_path")"
          [ "$cwd" = "$repo_dir" ] || continue
          printf "codex:%s\n" "$session_id"
        done <<EOF
$(dev_kit_learning_codex_recent_session_paths "$lastrun_file" "$max_recent")
EOF
        ;;
      claude)
        while IFS= read -r session_path; do
          [ -n "$session_path" ] || continue
          session_id="$(basename "$session_path" .jsonl)"
          [ -n "$session_id" ] || continue
          printf "claude:%s\n" "$session_id"
        done <<EOF
$(dev_kit_learning_claude_recent_session_paths "$repo_dir" "$lastrun_file" "$max_recent")
EOF
        ;;
    esac
  done <<EOF
$(dev_kit_learning_enabled_sources)
EOF
}

# ── session content & field extraction ────────────────────────────────────────

dev_kit_learning_session_content() {
  local ref="$1"
  local repo_dir="${2:-$(pwd)}"

  if [ "$DEV_KIT_SESSION_CONTENT_CACHE_KEY" = "$ref" ]; then
    printf "%s" "$DEV_KIT_SESSION_CONTENT_CACHE_VALUE"
    return 0
  fi

  local path
  path="$(dev_kit_learning_session_path "$ref" "$repo_dir")"
  [ -f "$path" ] || return 0

  local content
  content="$(tr '[:upper:]' '[:lower:]' < "$path")"
  DEV_KIT_SESSION_CONTENT_CACHE_KEY="$ref"
  DEV_KIT_SESSION_CONTENT_CACHE_VALUE="$content"
  printf "%s" "$content"
}

dev_kit_learning_session_cwd() {
  local ref="$1"
  local repo_dir="${2:-$(pwd)}"
  local source
  source="$(dev_kit_learning_ref_source "$ref")"

  case "$source" in
    claude)
      # CWD is derivable from project dir — no file read needed
      printf "%s" "$repo_dir"
      ;;
    *)
      local path
      path="$(dev_kit_learning_session_path "$ref" "$repo_dir")"
      [ -n "$path" ] || return 0
      dev_kit_learning_codex_session_cwd "$path"
      ;;
  esac
}

dev_kit_learning_session_user_prompts() {
  local ref="$1"
  local repo_dir="${2:-$(pwd)}"
  local path source

  source="$(dev_kit_learning_ref_source "$ref")"
  path="$(dev_kit_learning_session_path "$ref" "$repo_dir")"
  [ -f "$path" ] || return 0

  case "$source" in
    claude)
      # Prefer Claude history display lines because they are the stable,
      # user-facing prompt index keyed by project + sessionId.
      local history_lines
      history_lines="$(dev_kit_learning_claude_history_display_lines "$(dev_kit_learning_ref_id "$ref")" "$repo_dir" || true)"
      if [ -n "$history_lines" ]; then
        printf '%s\n' "$history_lines" \
          | dev_kit_learning_clean_prompt_lines \
          | awk 'NF && !seen[$0]++'
      else
        # Fallback to raw transcript parsing when history is unavailable.
        awk '
          /"type":"user"/ && /"promptId":"/ && /"isMeta":false/ {
            if (match($0, /"content":"([^"\\]|\\.)*"/)) {
              value = substr($0, RSTART + 11, RLENGTH - 12)
              gsub(/\\n/, " ", value)
              gsub(/\\"/, "\"", value)
              if (length(value) > 3) print value
            }
          }
        ' "$path" \
          | dev_kit_learning_clean_prompt_lines \
          | awk 'NF && !seen[$0]++'
      fi
      ;;
    *)
      # Codex supports both legacy top-level message lines and current
      # response_item payloads containing input_text blocks.
      awk '
        {
          is_user_message = 0

          if ($0 ~ /"type":"response_item"/ && $0 ~ /"payload":\{"type":"message","role":"user"/) {
            is_user_message = 1
          } else if ($0 ~ /"type":"message","role":"user"/) {
            is_user_message = 1
          }

          if (is_user_message && match($0, /"text":"([^"\\]|\\.)*"/)) {
            value = substr($0, RSTART + 8, RLENGTH - 9)
            gsub(/\\n/, " ", value)
            gsub(/\\"/, "\"", value)
            print value
          }
        }
      ' "$path" \
        | dev_kit_learning_clean_prompt_lines \
        | awk 'NF && !seen[$0]++'
      ;;
  esac
}

dev_kit_learning_claude_history_display_lines() {
  local session_id="$1"
  local repo_dir="${2:-$(pwd)}"
  local history_path

  history_path="$(dev_kit_learning_claude_history_path)"
  [ -f "$history_path" ] || return 1
  [ -n "$session_id" ] || return 1

  awk -v project="$repo_dir" -v session_id="$session_id" '
    index($0, "\"project\":\"" project "\"") && index($0, "\"sessionId\":\"" session_id "\"") {
      if (match($0, /"display":"([^"\\]|\\.)*"/)) {
        value = substr($0, RSTART + 11, RLENGTH - 12)
        gsub(/\\n/, " ", value)
        gsub(/\\"/, "\"", value)
        print value
      }
    }
  ' "$history_path"
}

dev_kit_learning_clean_prompt_lines() {
  awk '
    function trim(value) {
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      return value
    }
    function normalize(value) {
      gsub(/[[:space:]]+/, " ", value)
      return trim(value)
    }
    function clip_before_markers(value, marker_pos) {
      marker_pos = index(value, " fq // ")
      if (marker_pos > 0) value = substr(value, 1, marker_pos - 1)
      marker_pos = index(value, " jonyfq@")
      if (marker_pos > 0) value = substr(value, 1, marker_pos - 1)
      marker_pos = index(value, " $ ")
      if (marker_pos > 0) value = substr(value, 1, marker_pos - 1)
      marker_pos = index(value, " [summary]")
      if (marker_pos > 0) value = substr(value, 1, marker_pos - 1)
      return trim(value)
    }
    {
      line = normalize($0)
      line = clip_before_markers(line)
      lower = tolower(line)

      if (line == "") next
      if (lower ~ /^<image name=/) next
      if (lower ~ /ag[[:space:]]*ents\.md instructions/) next
      if (lower ~ /<instructions>/) next
      if (lower ~ /<environment_context>/) next
      if (lower ~ /<local-command-caveat>/) next
      if (lower ~ /<turn_aborted>/) next
      if (lower ~ /^fq[[:space:]]*\/\//) next
      if (lower ~ /^jonyfq@.*>[[:space:]]/) next
      if (lower ~ /^[[]summary[]]$/) next
      if (lower ~ /^[[]sources[]]$/) next
      if (lower ~ /^[[]observed[]]$/) next
      if (lower ~ /^[[]workflow[]]$/) next
      if (lower ~ /^[[]learned[]]$/) next
      if (lower ~ /^[[]artifact[]]$/) next
      if (lower ~ /^[[]send to[]]$/) next
      if (lower ~ /^dev\.kit learn$/) next
      if (lower ~ /^installed dev\.kit$/) next
      if (lower ~ /^find all codex sessions/) next
      if (lower ~ /^find all claude sessions/) next
      if (lower ~ /^human-first raw output/) next
      if (lower ~ /^path:[[:space:]]*~/) next
      if (lower ~ /^repo:[[:space:]]/) next
      if (lower ~ /^available:[[:space:]]*$/) next
      if (lower ~ /^\$[[:space:]]/) next
      if (lower ~ /^-[[:space:]]+\//) next
      if (lower ~ /^\/[a-z]/) next
      if (length(line) > 320) line = substr(line, 1, 317) "..."

      print line
    }
  '
}

# ── URL extraction (works on raw text, same for both sources) ─────────────────

dev_kit_learning_sanitize_url_lines() {
  awk '
    {
      # Split on literal \n (JSON-escaped newlines that join multiple URLs)
      n = split($0, segs, /\\n/)
      for (i = 1; i <= n; i++) {
        url = segs[i]
        gsub(/\\+$/, "", url)
        gsub(/[")]+$/, "", url)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", url)
        # Skip placeholder/example URLs from prompts and docs
        if (url ~ /github\.com\/(test|example|org|owner|user)\//) url = ""
        if (url ~ /github\.com\/[^\/]+\/repo[\/"]/) url = ""
        if (url != "" && !seen[url]++) print url
      }
    }
  '
}

dev_kit_learning_session_issue_urls() {
  local ref="$1"
  local repo_dir="${2:-$(pwd)}"
  local path
  path="$(dev_kit_learning_session_path "$ref" "$repo_dir")"
  [ -f "$path" ] || return 0
  awk '
    match($0, /https:\/\/github\.com\/[^"[:space:]]+\/issues\/[0-9]+/) {
      print substr($0, RSTART, RLENGTH)
    }
  ' "$path" | dev_kit_learning_sanitize_url_lines
}

dev_kit_learning_session_pr_urls() {
  local ref="$1"
  local repo_dir="${2:-$(pwd)}"
  local path
  path="$(dev_kit_learning_session_path "$ref" "$repo_dir")"
  [ -f "$path" ] || return 0
  awk '
    match($0, /https:\/\/github\.com\/[^"[:space:]]+\/pull\/[0-9]+/) {
      print substr($0, RSTART, RLENGTH)
    }
  ' "$path" | dev_kit_learning_sanitize_url_lines
}

dev_kit_learning_session_release_urls() {
  local ref="$1"
  local repo_dir="${2:-$(pwd)}"
  local path
  path="$(dev_kit_learning_session_path "$ref" "$repo_dir")"
  [ -f "$path" ] || return 0
  awk '
    match($0, /https:\/\/github\.com\/[^"[:space:]\\)]+\/releases\/tag\/[^"[:space:]\\)]+/) {
      print substr($0, RSTART, RLENGTH)
    }
  ' "$path" | dev_kit_learning_sanitize_url_lines
}

# ── merged multi-source output ─────────────────────────────────────────────────

dev_kit_learning_merged_user_prompts() {
  local refs="$1"
  local repo_dir="${2:-$(pwd)}"
  local ref source

  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    source="$(dev_kit_learning_ref_source "$ref")"
    dev_kit_learning_session_user_prompts "$ref" "$repo_dir" \
      | sed "s|^|[${source}] |"
  done <<EOF
$refs
EOF
}

dev_kit_learning_merged_issue_urls() {
  local refs="$1"
  local repo_dir="${2:-$(pwd)}"
  local ref
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    dev_kit_learning_session_issue_urls "$ref" "$repo_dir"
  done <<EOF
$refs
EOF
}

dev_kit_learning_merged_pr_urls() {
  local refs="$1"
  local repo_dir="${2:-$(pwd)}"
  local ref
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    dev_kit_learning_session_pr_urls "$ref" "$repo_dir"
  done <<EOF
$refs
EOF
}

# ── flow & rule matching (multi-source) ───────────────────────────────────────

dev_kit_learning_merged_flow_matches() {
  local refs="$1"
  local repo_dir="${2:-$(pwd)}"
  local ref flow_id threshold pattern matched_count content

  while IFS= read -r flow_id; do
    [ -n "$flow_id" ] || continue
    threshold="$(dev_kit_learning_session_flow_threshold "$flow_id")"
    [ -n "$threshold" ] || threshold="1"
    matched_count=0

    # collect content from all sessions
    content=""
    while IFS= read -r ref; do
      [ -n "$ref" ] || continue
      content="${content}
$(dev_kit_learning_session_content "$ref" "$repo_dir")"
    done <<EOF
$refs
EOF

    while IFS= read -r pattern; do
      [ -n "$pattern" ] || continue
      if grep -Fqi "$pattern" <<<"$content"; then
        matched_count=$((matched_count + 1))
      fi
    done <<EOF
$(dev_kit_learning_session_flow_patterns "$flow_id")
EOF

    if [ "$matched_count" -ge "$threshold" ]; then
      printf "%s\n" "$flow_id"
    fi
  done <<EOF
$(dev_kit_learning_session_flow_ids)
EOF
}

dev_kit_learning_merged_rule_matches() {
  local refs="$1"
  local repo_dir="${2:-$(pwd)}"
  local ref rule_id threshold pattern matched_count content

  while IFS= read -r rule_id; do
    [ -n "$rule_id" ] || continue
    threshold="$(dev_kit_learning_session_rule_threshold "$rule_id")"
    [ -n "$threshold" ] || threshold="1"
    matched_count=0

    content=""
    while IFS= read -r ref; do
      [ -n "$ref" ] || continue
      content="${content}
$(dev_kit_learning_session_content "$ref" "$repo_dir")"
    done <<EOF
$refs
EOF

    while IFS= read -r pattern; do
      [ -n "$pattern" ] || continue
      if grep -Fqi "$pattern" <<<"$content"; then
        matched_count=$((matched_count + 1))
      fi
    done <<EOF
$(dev_kit_learning_session_rule_patterns "$rule_id")
EOF

    if [ "$matched_count" -ge "$threshold" ]; then
      printf "%s\n" "$rule_id"
    fi
  done <<EOF
$(dev_kit_learning_session_rule_ids)
EOF
}

# ── JSON output helpers ────────────────────────────────────────────────────────

dev_kit_learning_observed_sources_json() {
  local refs="$1"
  local repo_dir="${2:-$(pwd)}"
  local ref source id path cwd first=1

  printf "["
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    source="$(dev_kit_learning_ref_source "$ref")"
    id="$(dev_kit_learning_ref_id "$ref")"
    path="$(dev_kit_learning_session_path "$ref" "$repo_dir")"
    cwd="$(dev_kit_learning_session_cwd "$ref" "$repo_dir")"
    [ "$first" -eq 0 ] && printf ", "
    printf '{ "source": "%s", "id": "%s", "cwd": "%s", "path": "%s" }' \
      "$(dev_kit_json_escape "$source")" \
      "$(dev_kit_json_escape "$id")" \
      "$(dev_kit_json_escape "$cwd")" \
      "$(dev_kit_json_escape "$path")"
    first=0
  done <<EOF
$refs
EOF
  printf "]"
}

dev_kit_learning_merged_flow_json() {
  local refs="$1"
  local repo_dir="${2:-$(pwd)}"
  local flow_id first=1

  printf "["
  while IFS= read -r flow_id; do
    [ -n "$flow_id" ] || continue
    [ "$first" -eq 0 ] && printf ", "
    printf '{ "id": "%s", "message": "%s" }' \
      "$(dev_kit_json_escape "$flow_id")" \
      "$(dev_kit_json_escape "$(dev_kit_learning_session_flow_message "$flow_id")")"
    first=0
  done <<EOF
$(dev_kit_learning_merged_flow_matches "$refs" "$repo_dir")
EOF
  printf "]"
}

dev_kit_learning_merged_shared_context_json() {
  local refs="$1"
  local repo_dir="${2:-$(pwd)}"
  local issues

  issues="$(dev_kit_learning_merged_issue_urls "$refs" "$repo_dir" | dev_kit_lines_to_json_array)"
  if [ "$issues" = "[]" ]; then
    printf "null"
    return 0
  fi
  printf '{ "mode": "issue-root", "message": "%s", "issues": %s }' \
    "$(dev_kit_json_escape "Treat the GitHub issue as the shared cross-repo context root, then use each repo'\''s docs, workflows, and tests as the local execution contract.")" \
    "$issues"
}

# ── source status (for text output) ───────────────────────────────────────────

dev_kit_learning_source_counts() {
  local refs="$1"
  local codex_count=0 claude_count=0 ref

  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    case "$(dev_kit_learning_ref_source "$ref")" in
      claude) claude_count=$((claude_count + 1)) ;;
      codex)  codex_count=$((codex_count + 1)) ;;
    esac
  done <<EOF
$refs
EOF
  printf "claude:%d codex:%d" "$claude_count" "$codex_count"
}

# ── backward-compat shims (legacy single-session callers) ─────────────────────

dev_kit_learning_session_id_from_path() {
  dev_kit_learning_codex_session_id_from_path "$1"
}

dev_kit_learning_discovered_session_id() {
  local repo_dir="${1:-$(pwd)}"
  local path session_id cwd

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    session_id="$(dev_kit_learning_codex_session_id_from_path "$path")"
    cwd="$(dev_kit_learning_codex_session_cwd "$path")"
    if [ -n "$cwd" ] && [ "$cwd" = "$repo_dir" ]; then
      DEV_KIT_DISCOVERED_SESSION_CACHE_KEY="$repo_dir"
      DEV_KIT_DISCOVERED_SESSION_CACHE_VALUE="$session_id"
      printf "%s" "$session_id"
      return 0
    fi
  done <<EOF
$(dev_kit_learning_codex_recent_session_paths)
EOF

  DEV_KIT_DISCOVERED_SESSION_CACHE_KEY="$repo_dir"
  DEV_KIT_DISCOVERED_SESSION_CACHE_VALUE=""
}

dev_kit_learning_session_sources_text() {
  local ref="$1"
  local repo_dir="${2:-$(pwd)}"
  local path cwd source id

  source="$(dev_kit_learning_ref_source "$ref")"
  id="$(dev_kit_learning_ref_id "$ref")"
  path="$(dev_kit_learning_session_path "$ref" "$repo_dir")"
  cwd="$(dev_kit_learning_session_cwd "$ref" "$repo_dir")"

  printf "local agent session %s (%s)\n" "$id" "$source"
  printf "session cwd: %s\n" "$cwd"
  printf "session file: %s\n" "$path"
}

dev_kit_learning_session_sources_json() {
  local ref="$1"
  local repo_dir="${2:-$(pwd)}"
  local path cwd source id

  source="$(dev_kit_learning_ref_source "$ref")"
  id="$(dev_kit_learning_ref_id "$ref")"
  path="$(dev_kit_learning_session_path "$ref" "$repo_dir")"
  if [ -z "$path" ]; then
    printf "%s" "[]"
    return 0
  fi
  cwd="$(dev_kit_learning_session_cwd "$ref" "$repo_dir")"
  printf '[{ "source": "%s", "type": "local_agent_session", "id": "%s", "cwd": "%s", "path": "%s" }]' \
    "$(dev_kit_json_escape "$source")" \
    "$(dev_kit_json_escape "$id")" \
    "$(dev_kit_json_escape "$cwd")" \
    "$(dev_kit_json_escape "$path")"
}

# ── GitHub history — dynamic PR/issue pattern detection ───────────────────────
# These functions fetch live data from the GitHub API to detect the user's
# actual PR description and issue update patterns. No storage — real-time only.

dev_kit_learning_github_owner_repo() {
  local repo_dir="${1:-$(pwd)}"
  local origin_url
  origin_url="$(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)"
  if [[ "$origin_url" =~ github\.com[:/]([^/]+/[^/]+)(\.git)?$ ]]; then
    local result="${BASH_REMATCH[1]}"
    printf "%s" "${result%.git}"
  fi
}

# Fetch recent merged PR bodies as delimited blocks.
# Output: ---PR#number title---\nbody\n---PR_END--- per PR
dev_kit_learning_github_recent_pr_bodies() {
  local repo_dir="${1:-$(pwd)}"
  local sample_size="${2:-8}"
  local owner_repo
  owner_repo="$(dev_kit_learning_github_owner_repo "$repo_dir")"
  [ -n "$owner_repo" ] || return 0
  dev_kit_sync_can_run_gh || return 0
  [ "$(dev_kit_sync_gh_auth_state)" = "available" ] || return 0

  gh api "repos/${owner_repo}/pulls?state=closed&sort=updated&direction=desc&per_page=${sample_size}" \
    2>/dev/null | jq -r --argjson n "$sample_size" '
    [.[]? | select(.merged_at != null and (.body // "" | length) > 30)] |
    sort_by(.merged_at) | reverse | .[:$n][] |
    "---PR#\(.number) \(.title)---\n\(.body)\n---PR_END---"
  ' 2>/dev/null || true
}

# Detect common ## headings across PR bodies — returns headings found in 2+ PRs.
dev_kit_learning_github_pr_heading_pattern() {
  local pr_bodies="$1"
  [ -n "$pr_bodies" ] || return 0
  printf '%s\n' "$pr_bodies" | awk '
    /^---PR#/ { pr_idx++; in_pr=1; next }
    /^---PR_END---/ { in_pr=0; next }
    in_pr && /^##[[:space:]]/ {
      heading = $0
      sub(/^##[[:space:]]+/, "", heading)
      sub(/[[:space:]]+$/, "", heading)
      if (heading != "" && !seen[pr_idx,heading]++) count[heading]++
    }
    END {
      for (h in count) {
        if (count[h] >= 2) printf "%d|%s\n", count[h], h
      }
    }
  ' | sort -t'|' -k1,1rn | cut -d'|' -f2
}

# Find the best-structured PR body (most headings) as a reference example.
# Output: PR number on line 1, body on remaining lines.
dev_kit_learning_github_best_pr_example() {
  local pr_bodies="$1"
  [ -n "$pr_bodies" ] || return 0
  printf '%s\n' "$pr_bodies" | awk '
    /^---PR#/ {
      if (heading_count > best_count) {
        best_count = heading_count
        best_title = current_title
        best_body = current_body
      }
      sub(/^---PR#/, "")
      sub(/---$/, "")
      current_title = $0
      current_body = ""
      heading_count = 0
      in_pr = 1
      next
    }
    /^---PR_END---/ {
      if (heading_count > best_count) {
        best_count = heading_count
        best_title = current_title
        best_body = current_body
      }
      in_pr = 0
      next
    }
    in_pr {
      current_body = current_body $0 "\n"
      if ($0 ~ /^##[[:space:]]/) heading_count++
    }
    END {
      if (best_count > 0) {
        print best_title
        n = split(best_body, lines, "\n")
        limit = (n < 60) ? n : 60
        for (i = 1; i <= limit; i++) printf "%s\n", lines[i]
      }
    }
  '
}

# Fetch recent issue comments by the authenticated user.
# Output: delimited comment blocks.
dev_kit_learning_github_recent_issue_comments() {
  local repo_dir="${1:-$(pwd)}"
  local sample_size="${2:-20}"
  local owner_repo gh_user
  owner_repo="$(dev_kit_learning_github_owner_repo "$repo_dir")"
  [ -n "$owner_repo" ] || return 0
  dev_kit_sync_can_run_gh || return 0
  [ "$(dev_kit_sync_gh_auth_state)" = "available" ] || return 0

  gh_user="$(gh api user --jq '.login' 2>/dev/null || true)"
  [ -n "$gh_user" ] || return 0

  gh api "repos/${owner_repo}/issues/comments?sort=created&direction=desc&per_page=${sample_size}" \
    2>/dev/null | jq -r --arg user "$gh_user" --argjson n "$sample_size" '
    [.[]? | select(.user.login == $user and (.body | length) > 40)] | .[:$n][] |
    "---COMMENT_START---\n\(.body)\n---COMMENT_END---"
  ' 2>/dev/null || true
}

# Detect common patterns in issue comments — checklists, status headers, structured updates.
# Returns a short description of the detected pattern.
dev_kit_learning_github_issue_update_detect() {
  local comments="$1"
  [ -n "$comments" ] || return 0
  printf '%s\n' "$comments" | awk '
    /^---COMMENT_START---/ { comment_count++; in_c=1; has_checklist=0; has_heading=0; has_status=0; next }
    /^---COMMENT_END---/ {
      if (has_checklist) checklist_count++
      if (has_heading) heading_count++
      if (has_status) status_count++
      in_c=0; next
    }
    in_c && /^- \[[ x]\]/ { has_checklist=1 }
    in_c && /^##[[:space:]]/ { has_heading=1 }
    in_c && /[Ss]tatus:|[Uu]pdate:|[Pp]rogress:|[Dd]one:|[Nn]ext:/ { has_status=1 }
    END {
      if (comment_count == 0) exit
      if (checklist_count >= 2) printf "checklist-driven updates (%d/%d comments use task checklists)\n", checklist_count, comment_count
      if (heading_count >= 2) printf "structured sections (%d/%d comments use markdown headings)\n", heading_count, comment_count
      if (status_count >= 2) printf "status/progress tracking (%d/%d comments include status labels)\n", status_count, comment_count
    }
  '
}

# Extract a good issue comment example (longest with structure).
dev_kit_learning_github_best_issue_comment() {
  local comments="$1"
  [ -n "$comments" ] || return 0
  printf '%s\n' "$comments" | awk '
    /^---COMMENT_START---/ {
      if (length(current_body) > length(best_body) && current_structure > 0) {
        best_body = current_body
      }
      current_body = ""
      current_structure = 0
      in_c = 1
      next
    }
    /^---COMMENT_END---/ {
      if (length(current_body) > length(best_body) && current_structure > 0) {
        best_body = current_body
      }
      in_c = 0
      next
    }
    in_c {
      current_body = current_body $0 "\n"
      if ($0 ~ /^##[[:space:]]/ || $0 ~ /^- \[[ x]\]/ || $0 ~ /[Ss]tatus:|[Uu]pdate:/) current_structure++
    }
    END {
      if (best_body != "") {
        n = split(best_body, lines, "\n")
        limit = (n < 60) ? n : 60
        for (i = 1; i <= limit; i++) printf "%s\n", lines[i]
      }
    }
  '
}

# Extract lesson artifact workflow rules and templates for AGENTS.md injection.
dev_kit_learning_lesson_rules() {
  local repo_dir="$1"
  local lessons_dir="${repo_dir}/.rabbit/dev.kit"
  [ -d "$lessons_dir" ] || return 0
  local latest
  latest="$(find "$lessons_dir" -maxdepth 1 -type f -name 'lessons-*.md' 2>/dev/null | sort -r | head -1)"
  [ -f "$latest" ] || return 0

  awk '
    /^## Workflow rules/ { in_section=1; next }
    /^## / && in_section { exit }
    in_section && /^- / {
      sub(/^- /, "")
      print
    }
  ' "$latest"
}

dev_kit_learning_lesson_templates() {
  local repo_dir="$1"
  local lessons_dir="${repo_dir}/.rabbit/dev.kit"
  [ -d "$lessons_dir" ] || return 0
  local latest
  latest="$(find "$lessons_dir" -maxdepth 1 -type f -name 'lessons-*.md' 2>/dev/null | sort -r | head -1)"
  [ -f "$latest" ] || return 0

  awk '
    /^## Ready templates/ { in_section=1; next }
    /^## / && in_section { exit }
    in_section && /^- / {
      sub(/^- /, "")
      print
    }
  ' "$latest"
}
