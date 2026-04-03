#!/usr/bin/env bash

DEV_KIT_SESSION_PATH_CACHE_KEY=""
DEV_KIT_SESSION_PATH_CACHE_VALUE=""
DEV_KIT_DISCOVERED_SESSION_CACHE_KEY=""
DEV_KIT_DISCOVERED_SESSION_CACHE_VALUE=""

dev_kit_learning_expand_path() {
  local value="$1"

  value="${value/\$CODEX_HOME/${CODEX_HOME:-$HOME/.codex}}"
  case "$value" in
    "~"*) value="${HOME}${value#\~}" ;;
  esac
  printf "%s\n" "$value"
}

dev_kit_learning_session_roots() {
  local root=""

  while IFS= read -r root; do
    [ -n "$root" ] || continue
    dev_kit_learning_expand_path "$root"
  done <<EOF
$(dev_kit_learning_source_discovery_list "local_session_roots")
EOF
}

dev_kit_learning_recent_session_paths() {
  local root=""
  local max_recent=""

  max_recent="$(dev_kit_learning_source_discovery_scalar "max_recent_sessions")"
  [ -n "$max_recent" ] || max_recent="12"

  while IFS= read -r root; do
    [ -d "$root" ] || continue
    find "$root" -type f -name '*.jsonl' -print 2>/dev/null
  done <<EOF
$(dev_kit_learning_session_roots)
EOF
  awk '!seen[$0]++' | sort -r | sed -n "1,${max_recent}p"
}

dev_kit_learning_session_id_from_path() {
  local session_path="$1"
  basename "$session_path" | sed -E 's/.*-([0-9a-f-]{36})\.jsonl/\1/'
}

dev_kit_learning_session_path() {
  local session_id="$1"
  local session_path=""

  [ -n "$session_id" ] || return 1

  if [ "$DEV_KIT_SESSION_PATH_CACHE_KEY" = "$session_id" ]; then
    printf "%s" "$DEV_KIT_SESSION_PATH_CACHE_VALUE"
    return 0
  fi

  while IFS= read -r session_path; do
    [ -n "$session_path" ] || continue
    if [ "$(dev_kit_learning_session_id_from_path "$session_path")" = "$session_id" ]; then
      DEV_KIT_SESSION_PATH_CACHE_KEY="$session_id"
      DEV_KIT_SESSION_PATH_CACHE_VALUE="$session_path"
      printf "%s" "$session_path"
      return 0
    fi
  done <<EOF
$(dev_kit_learning_recent_session_paths)
EOF

  DEV_KIT_SESSION_PATH_CACHE_KEY="$session_id"
  DEV_KIT_SESSION_PATH_CACHE_VALUE=""
}

dev_kit_learning_session_field() {
  local session_id="$1"
  local field_name="$2"
  local session_path=""

  session_path="$(dev_kit_learning_session_path "$session_id")"
  [ -n "$session_path" ] || return 0

  awk -v field_name="$field_name" '
    $0 ~ /"type":"session_meta"/ && match($0, "\"" field_name "\":\"[^\"]*\"") {
      value = substr($0, RSTART, RLENGTH)
      sub("^\"" field_name "\":\"", "", value)
      sub("\"$", "", value)
      print value
      exit
    }
  ' "$session_path"
}

dev_kit_learning_session_cwd() {
  dev_kit_learning_session_field "$1" "cwd"
}

dev_kit_learning_discovered_session_id() {
  local repo_dir="$1"
  local session_path=""
  local session_id=""
  local session_cwd=""

  if [ "$DEV_KIT_DISCOVERED_SESSION_CACHE_KEY" = "$repo_dir" ]; then
    printf "%s" "$DEV_KIT_DISCOVERED_SESSION_CACHE_VALUE"
    return 0
  fi

  while IFS= read -r session_path; do
    [ -n "$session_path" ] || continue
    session_id="$(dev_kit_learning_session_id_from_path "$session_path")"
    session_cwd="$(dev_kit_learning_session_cwd "$session_id")"
    if [ -n "$session_cwd" ] && [ "$session_cwd" = "$repo_dir" ]; then
      DEV_KIT_DISCOVERED_SESSION_CACHE_KEY="$repo_dir"
      DEV_KIT_DISCOVERED_SESSION_CACHE_VALUE="$session_id"
      printf "%s" "$session_id"
      return 0
    fi
  done <<EOF
$(dev_kit_learning_recent_session_paths)
EOF

  DEV_KIT_DISCOVERED_SESSION_CACHE_KEY="$repo_dir"
  DEV_KIT_DISCOVERED_SESSION_CACHE_VALUE=""
}

dev_kit_learning_session_repo_name() {
  local session_cwd=""

  session_cwd="$(dev_kit_learning_session_cwd "$1")"
  [ -n "$session_cwd" ] || return 0
  basename "$session_cwd"
}

dev_kit_learning_session_issue_urls() {
  local session_id="$1"
  local session_path=""

  session_path="$(dev_kit_learning_session_path "$session_id")"
  [ -n "$session_path" ] || return 0

  awk '
    match($0, /https:\/\/github\.com\/[^"[:space:]]+\/issues\/[0-9]+/) {
      print substr($0, RSTART, RLENGTH)
    }
  ' "$session_path" | dev_kit_learning_sanitize_url_lines
}

dev_kit_learning_session_release_urls() {
  local session_id="$1"
  local session_path=""

  session_path="$(dev_kit_learning_session_path "$session_id")"
  [ -n "$session_path" ] || return 0

  awk '
    match($0, /https:\/\/github\.com\/[^"[:space:]\\)]+\/releases\/tag\/[^"[:space:]\\)]+/) {
      print substr($0, RSTART, RLENGTH)
    }
  ' "$session_path" | dev_kit_learning_sanitize_url_lines
}

dev_kit_learning_session_pr_urls() {
  local session_id="$1"
  local session_path=""

  session_path="$(dev_kit_learning_session_path "$session_id")"
  [ -n "$session_path" ] || return 0

  awk '
    match($0, /https:\/\/github\.com\/[^"[:space:]]+\/pull\/[0-9]+/) {
      print substr($0, RSTART, RLENGTH)
    }
  ' "$session_path" | dev_kit_learning_sanitize_url_lines
}

dev_kit_learning_sanitize_url_lines() {
  awk '
    {
      gsub(/\\+$/, "", $0)
      gsub(/[")]+$/, "", $0)
      if (!seen[$0]++) {
        print
      }
    }
  '
}

dev_kit_learning_session_user_prompts() {
  local session_id="$1"
  local session_path=""

  session_path="$(dev_kit_learning_session_path "$session_id")"
  [ -n "$session_path" ] || return 0

  awk '
    $0 ~ /"type":"message","role":"user"/ && match($0, /"text":"([^"\\]|\\.)*"/) {
      value = substr($0, RSTART + 8, RLENGTH - 9)
      gsub(/\\n/, " ", value)
      gsub(/\\"/, "\"", value)
      print value
    }
  ' "$session_path" | awk 'NF && !seen[$0]++'
}

dev_kit_learning_session_content() {
  local session_id="$1"
  local session_path=""

  session_path="$(dev_kit_learning_session_path "$session_id")"
  [ -n "$session_path" ] || return 0
  tr '[:upper:]' '[:lower:]' < "$session_path"
}

dev_kit_learning_session_rule_matches() {
  local session_id="$1"
  local rule_id=""
  local threshold=""
  local pattern=""
  local content=""
  local matched_count=0

  content="$(dev_kit_learning_session_content "$session_id")"
  [ -n "$content" ] || return 0

  while IFS= read -r rule_id; do
    [ -n "$rule_id" ] || continue
    threshold="$(dev_kit_learning_session_rule_threshold "$rule_id")"
    [ -n "$threshold" ] || threshold="1"
    matched_count=0

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

dev_kit_learning_session_lessons_text() {
  local session_id="$1"
  local rule_id=""

  while IFS= read -r rule_id; do
    [ -n "$rule_id" ] || continue
    dev_kit_learning_session_rule_message "$rule_id"
  done <<EOF
$(dev_kit_learning_session_rule_matches "$session_id")
EOF
}

dev_kit_learning_session_lessons_json() {
  local session_id="$1"
  local rule_id=""
  local first=1

  printf "["
  while IFS= read -r rule_id; do
    [ -n "$rule_id" ] || continue
    if [ "$first" -eq 0 ]; then
      printf ", "
    fi
    printf '{ "id": "%s", "message": "%s" }' \
      "$(dev_kit_json_escape "$rule_id")" \
      "$(dev_kit_json_escape "$(dev_kit_learning_session_rule_message "$rule_id")")"
    first=0
  done <<EOF
$(dev_kit_learning_session_rule_matches "$session_id")
EOF
  printf "]"
}

dev_kit_learning_session_flow_matches() {
  local session_id="$1"
  local flow_id=""
  local threshold=""
  local pattern=""
  local content=""
  local matched_count=0

  content="$(dev_kit_learning_session_content "$session_id")"
  [ -n "$content" ] || return 0

  while IFS= read -r flow_id; do
    [ -n "$flow_id" ] || continue
    threshold="$(dev_kit_learning_session_flow_threshold "$flow_id")"
    [ -n "$threshold" ] || threshold="1"
    matched_count=0

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

dev_kit_learning_session_flow_text() {
  local session_id="$1"
  local flow_id=""

  while IFS= read -r flow_id; do
    [ -n "$flow_id" ] || continue
    dev_kit_learning_session_flow_message "$flow_id"
  done <<EOF
$(dev_kit_learning_session_flow_matches "$session_id")
EOF
}

dev_kit_learning_session_flow_json() {
  local session_id="$1"
  local flow_id=""
  local first=1

  printf "["
  while IFS= read -r flow_id; do
    [ -n "$flow_id" ] || continue
    if [ "$first" -eq 0 ]; then
      printf ", "
    fi
    printf '{ "id": "%s", "message": "%s" }' \
      "$(dev_kit_json_escape "$flow_id")" \
      "$(dev_kit_json_escape "$(dev_kit_learning_session_flow_message "$flow_id")")"
    first=0
  done <<EOF
$(dev_kit_learning_session_flow_matches "$session_id")
EOF
  printf "]"
}

dev_kit_learning_session_sources_text() {
  local session_id="$1"
  local session_path=""
  local session_cwd=""

  session_path="$(dev_kit_learning_session_path "$session_id")"
  [ -n "$session_path" ] || return 0
  session_cwd="$(dev_kit_learning_session_cwd "$session_id")"

  printf "local agent session %s\n" "$session_id"
  printf "session cwd: %s\n" "$session_cwd"
  printf "session file: %s\n" "$session_path"
}

dev_kit_learning_session_sources_json() {
  local session_id="$1"
  local session_path=""
  local session_cwd=""

  session_path="$(dev_kit_learning_session_path "$session_id")"
  if [ -z "$session_path" ]; then
    printf "%s" "[]"
    return 0
  fi

  session_cwd="$(dev_kit_learning_session_cwd "$session_id")"
  printf '[{ "type": "local_agent_session", "id": "%s", "cwd": "%s", "path": "%s" }]' \
    "$(dev_kit_json_escape "$session_id")" \
    "$(dev_kit_json_escape "$session_cwd")" \
    "$(dev_kit_json_escape "$session_path")"
}

dev_kit_learning_session_shared_context_json() {
  local session_id="$1"
  local issues=""

  issues="$(dev_kit_learning_session_issue_urls "$session_id" | dev_kit_lines_to_json_array)"
  if [ "$issues" = "[]" ]; then
    printf "%s" "null"
    return 0
  fi

  printf '{ "mode": "issue-root", "message": "%s", "issues": %s }' \
    "$(dev_kit_json_escape "Treat the GitHub issue as the shared cross-repo context root, then use each repo's docs, workflows, and tests as the local execution contract.")" \
    "$issues"
}

dev_kit_learning_session_summary_json() {
  local session_id="$1"
  local repo_dir="$2"
  local session_path=""
  local session_cwd=""
  local repo_match="false"

  session_path="$(dev_kit_learning_session_path "$session_id")"
  if [ -z "$session_path" ]; then
    printf "%s" "null"
    return 0
  fi

  session_cwd="$(dev_kit_learning_session_cwd "$session_id")"
  if [ -n "$repo_dir" ] && [ "$repo_dir" = "$session_cwd" ]; then
    repo_match="true"
  fi

  printf '{ "id": "%s", "cwd": "%s", "repo_name": "%s", "path": "%s", "matches_current_repo": %s, "issues": %s, "pull_requests": %s, "releases": %s, "flow": %s, "lessons": %s }' \
    "$(dev_kit_json_escape "$session_id")" \
    "$(dev_kit_json_escape "$session_cwd")" \
    "$(dev_kit_json_escape "$(dev_kit_learning_session_repo_name "$session_id")")" \
    "$(dev_kit_json_escape "$session_path")" \
    "$repo_match" \
    "$(dev_kit_learning_session_issue_urls "$session_id" | dev_kit_lines_to_json_array)" \
    "$(dev_kit_learning_session_pr_urls "$session_id" | dev_kit_lines_to_json_array)" \
    "$(dev_kit_learning_session_release_urls "$session_id" | dev_kit_lines_to_json_array)" \
    "$(dev_kit_learning_session_flow_json "$session_id")" \
    "$(dev_kit_learning_session_lessons_json "$session_id")"
}
