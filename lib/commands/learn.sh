#!/usr/bin/env bash

# @description: Collect lessons from recent agent sessions and write a lessons artifact

dev_kit_cmd_learn() {
  local format="${1:-text}"
  shift || true
  local repo_dir
  repo_dir="$(pwd)"
  local workflow_id="$DEV_KIT_LEARNING_DEFAULT_WORKFLOW"
  local arg=""

  while [ "$#" -gt 0 ]; do
    arg="$1"
    case "$arg" in
      --workflow)
        shift
        [ "$#" -gt 0 ] || break
        workflow_id="$1"
        ;;
      --sources)
        shift
        [ "$#" -gt 0 ] || break
        export DEV_KIT_LEARN_SOURCES="$1"
        ;;
      *)
        repo_dir="$arg"
        ;;
    esac
    shift || true
  done

  local repo_root _norm
  repo_root="$(dev_kit_repo_root "$repo_dir")"
  repo_dir="${repo_root:-$repo_dir}"
  # Normalize path — macOS TMPDIR has trailing slash creating // which pwd resolves
  _norm="$(cd "$repo_dir" 2>/dev/null && pwd || true)"
  [ -n "$_norm" ] && repo_dir="$_norm"

  local lastrun_file="${repo_dir}/.rabbit/dev.kit/learn-last-run"
  local latest_artifact
  latest_artifact="$(dev_kit_learning_latest_artifact_path "$repo_dir")"
  local session_refs
  if [ -n "$latest_artifact" ] && [ -f "$latest_artifact" ]; then
    session_refs="$(dev_kit_learning_all_session_refs "$repo_dir" "$lastrun_file")"
  else
    # No durable lessons artifact means there is no incremental baseline yet.
    session_refs="$(dev_kit_learning_all_session_refs "$repo_dir" "")"
  fi

  if [ "$format" = "json" ]; then
    local observed_json flow_json shared_context_json
    observed_json="$(dev_kit_learning_observed_sources_json "$session_refs" "$repo_dir")"
    flow_json="$(dev_kit_learning_merged_flow_json "$session_refs" "$repo_dir")"
    shared_context_json="$(dev_kit_learning_merged_shared_context_json "$session_refs" "$repo_dir")"

    dev_kit_template_render "learn.json" \
      "command=learn" \
      "repo=$(dev_kit_json_escape "$repo_dir")" \
      "workflow_id=$(dev_kit_json_escape "$workflow_id")" \
      "workflow_name=$(dev_kit_json_escape "$(dev_kit_learning_workflow_name "$workflow_id")")" \
      "description=$(dev_kit_json_escape "$(dev_kit_learning_workflow_description "$workflow_id")")" \
      "sources=$(dev_kit_learning_workflow_sources "$workflow_id" | dev_kit_lines_to_json_array)" \
      "observed_sources=$observed_json" \
      "destinations=$(dev_kit_learning_destinations_json "$workflow_id")" \
      "session=null" \
      "flow=$flow_json" \
      "shared_context=$shared_context_json" \
      "knowledge_base=$(dev_kit_knowledge_hierarchy_json)" \
      "knowledge_sources=$(dev_kit_knowledge_preferred_sources | dev_kit_lines_to_json_array)"
    return 0
  fi

  # ── text mode ────────────────────────────────────────────────────────────────

  dev_kit_output_title "dev.kit learn"
  dev_kit_output_summary "$(dev_kit_learning_workflow_name "$workflow_id") • lessons from agent sessions"
  dev_kit_output_section "summary"
  dev_kit_output_row "repo"     "$repo_dir"
  dev_kit_output_row "workflow" "$(dev_kit_learning_workflow_description "$workflow_id")"

  # source availability
  dev_kit_output_section "sources"
  local counts
  counts="$(dev_kit_learning_source_counts "$session_refs")"
  local claude_count codex_count
  claude_count="$(printf "%s" "$counts" | sed 's/claude:\([0-9]*\).*/\1/')"
  codex_count="$(printf "%s" "$counts" | sed 's/.*codex:\([0-9]*\)/\1/')"
  dev_kit_output_row "claude" "${claude_count} session(s) found"
  dev_kit_output_row "codex"  "${codex_count} session(s) found"

  if [ -z "$session_refs" ]; then
    dev_kit_output_section "observed"
    if [ -n "$latest_artifact" ] && [ -f "$latest_artifact" ]; then
      dev_kit_output_list_item "no new agent sessions found since the latest lessons artifact"
      dev_kit_output_section "artifact"
      dev_kit_output_list_item "$latest_artifact"
    else
      dev_kit_output_list_item "no agent sessions found for this repo"
    fi
    dev_kit_output_section "send to"
    dev_kit_learning_destinations_text "$workflow_id"
    return 0
  fi

  # sessions observed
  dev_kit_output_section "observed"
  local ref
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    local src id
    src="$(dev_kit_learning_ref_source "$ref")"
    id="$(dev_kit_learning_ref_id "$ref")"
    dev_kit_output_list_item "[${src}] ${id}"
  done <<EOF
$session_refs
EOF

  # flow patterns matched
  local flow_matches
  flow_matches="$(dev_kit_learning_merged_flow_matches "$session_refs" "$repo_dir")"
  if [ -n "$flow_matches" ]; then
    dev_kit_output_section "workflow"
    dev_kit_output_list_from_lines <<EOF
$(
while IFS= read -r flow_id; do
  [ -n "$flow_id" ] || continue
  dev_kit_learning_session_flow_message "$flow_id"
done <<INNER
$flow_matches
INNER
)
EOF
  fi

  # rule-based lessons
  local rule_matches
  rule_matches="$(dev_kit_learning_merged_rule_matches "$session_refs" "$repo_dir")"
  if [ -n "$rule_matches" ]; then
    dev_kit_output_section "learned"
    dev_kit_output_list_from_lines <<EOF
$(
while IFS= read -r rule_id; do
  [ -n "$rule_id" ] || continue
  dev_kit_learning_session_rule_message "$rule_id"
done <<INNER
$rule_matches
INNER
)
EOF
  fi

  # referenced GitHub issues
  local issue_urls
  issue_urls="$(dev_kit_learning_merged_issue_urls "$session_refs" "$repo_dir" | awk '!seen[$0]++')"
  if [ -n "$issue_urls" ]; then
    dev_kit_output_section "shared context"
    dev_kit_output_list_item "Use the GitHub issue as the cross-repo context root."
    dev_kit_output_list_from_lines <<EOF
$issue_urls
EOF
  fi

  # write artifact and update last-run
  dev_kit_spinner_start "writing lessons artifact"
  local artifact_path
  artifact_path="$(dev_kit_learning_write_artifact "$repo_dir" "$session_refs" "$latest_artifact")"
  dev_kit_spinner_stop "artifact saved"

  if [ -n "$artifact_path" ]; then
    dev_kit_output_section "artifact"
    dev_kit_output_list_item "$artifact_path"
  fi

  mkdir -p "$(dirname "$lastrun_file")" 2>/dev/null || true
  printf "%d\n" "$(date +%s)" > "$lastrun_file" 2>/dev/null || true

  dev_kit_output_section "send to"
  dev_kit_learning_destinations_text "$workflow_id"

  dev_kit_output_section "next"
  dev_kit_output_row "refresh context" "dev.kit repo"
  dev_kit_output_row "update agent" "dev.kit agent"
}

dev_kit_learning_latest_artifact_path() {
  local repo_dir="$1"
  local latest_path=""
  [ -d "${repo_dir}/.rabbit/dev.kit" ] || return 0

  latest_path="$(
    find "${repo_dir}/.rabbit/dev.kit" -maxdepth 1 -type f -name 'lessons-*.md' 2>/dev/null \
      | sort \
      | tail -n 1
  )"

  [ -n "$latest_path" ] && printf "%s" "$latest_path"
  return 0
}

# ── artifact writer ───────────────────────────────────────────────────────────

dev_kit_learning_write_artifact() {
  local repo_dir="$1"
  local refs="$2"
  local previous_artifact="${3:-}"
  local repo_name date_stamp artifact_path
  local previous_workflow_rules previous_references previous_templates previous_evidence

  repo_name="$(basename "$repo_dir")"
  date_stamp="$(date +%Y-%m-%d)"
  artifact_path="${repo_dir}/.rabbit/dev.kit/lessons-${repo_name}-${date_stamp}.md"

  mkdir -p "${repo_dir}/.rabbit/dev.kit" 2>/dev/null || true
  previous_workflow_rules="$(dev_kit_learning_previous_section_lines "$previous_artifact" "Workflow rules")"
  previous_references="$(dev_kit_learning_previous_section_lines "$previous_artifact" "Operational references")"
  previous_templates="$(dev_kit_learning_previous_section_lines "$previous_artifact" "Ready templates")"
  previous_evidence="$(dev_kit_learning_previous_section_lines "$previous_artifact" "Evidence highlights")"

  {
    printf '# Lessons — %s — %s\n\n' "$repo_name" "$date_stamp"

    # source summary
    local counts claude_count codex_count
    counts="$(dev_kit_learning_source_counts "$refs")"
    claude_count="$(printf "%s" "$counts" | sed 's/claude:\([0-9]*\).*/\1/')"
    codex_count="$(printf "%s" "$counts" | sed 's/.*codex:\([0-9]*\)/\1/')"
    printf 'Sources: claude (%s session(s)), codex (%s session(s))\n\n' \
      "$claude_count" "$codex_count"

    local evidence_lines rule_matches theme_matches flow_matches
    local workflow_rules references templates
    evidence_lines="$(dev_kit_learning_merge_unique_lines \
      "$previous_evidence" \
      "$(dev_kit_learning_evidence_highlights "$refs" "$repo_dir")" \
      | sed -n '1,8p')"
    rule_matches="$(dev_kit_learning_merged_rule_matches "$refs" "$repo_dir")"
    theme_matches="$(dev_kit_learning_prompt_theme_ids "$refs" "$repo_dir")"
    flow_matches="$(dev_kit_learning_merged_flow_matches "$refs" "$repo_dir")"
    workflow_rules="$(dev_kit_learning_merge_unique_lines \
      "$previous_workflow_rules" \
      "$(
        while IFS= read -r rule_id; do
          [ -n "$rule_id" ] || continue
          printf '%s\n' "$(dev_kit_learning_session_rule_message "$rule_id")"
        done <<EOF
$rule_matches
EOF
        while IFS= read -r theme_id; do
          [ -n "$theme_id" ] || continue
          printf '%s\n' "$(dev_kit_learning_prompt_theme_message "$theme_id")"
        done <<EOF
$theme_matches
EOF
      )")"

    if [ -n "$workflow_rules" ]; then
      printf '## Workflow rules\n\n'
      while IFS= read -r line; do
        [ -n "$line" ] || continue
        printf -- '- %s\n' "$line"
      done <<EOF
$workflow_rules
EOF
      printf '\n'
    fi

    # operational references (URLs)
    local issue_urls pr_urls
    issue_urls="$(dev_kit_learning_merged_issue_urls "$refs" "$repo_dir")"
    pr_urls="$(dev_kit_learning_merged_pr_urls "$refs" "$repo_dir")"
    references="$(dev_kit_learning_merge_unique_lines \
      "$previous_references" \
      "$issue_urls" \
      "$pr_urls")"
    if [ -n "$references" ]; then
      printf '## Operational references\n\n'
      while IFS= read -r url; do
        [ -n "$url" ] || continue
        printf -- '- %s\n' "$url"
      done <<EOF
$references
EOF
      printf '\n'
    fi

    templates="$(dev_kit_learning_merge_unique_lines \
      "$previous_templates" \
      "$(
        while IFS= read -r flow_id; do
          [ -n "$flow_id" ] || continue
          printf '%s\n' "$(dev_kit_learning_flow_template "$flow_id")"
        done <<EOF
$flow_matches
EOF
        while IFS= read -r theme_id; do
          [ -n "$theme_id" ] || continue
          printf '%s\n' "$(dev_kit_learning_prompt_theme_template "$theme_id")"
        done <<EOF
$theme_matches
EOF
      )")"
    if [ -n "$templates" ]; then
      printf '## Ready templates\n\n'
      while IFS= read -r line; do
        [ -n "$line" ] || continue
        printf -- '- %s\n' "$line"
      done <<EOF
$templates
EOF
      printf '\n'
    fi

    if [ -n "$evidence_lines" ]; then
      printf '## Evidence highlights\n\n'
      while IFS= read -r line; do
        [ -n "$line" ] || continue
        printf -- '- %s\n' "$line"
      done <<EOF
$evidence_lines
EOF
      printf '\n'
    fi
  } > "$artifact_path" 2>/dev/null || return 0

  printf "%s" "$artifact_path"
}

dev_kit_learning_previous_section_lines() {
  local artifact_path="${1:-}"
  local heading="$2"
  [ -n "$artifact_path" ] || return 0
  [ -f "$artifact_path" ] || return 0

  awk -v heading="$heading" '
    $0 == "## " heading { in_section = 1; next }
    /^## / && in_section { exit }
    in_section && /^- / {
      sub(/^- /, "", $0)
      print
    }
  ' "$artifact_path"
}

dev_kit_learning_merge_unique_lines() {
  while [ "$#" -gt 0 ]; do
    printf '%s\n' "$1"
    shift
  done | awk '
    {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      if ($0 == "") next
      if (seen[$0]++) next
      print
    }
  '
}

dev_kit_learning_evidence_highlights() {
  local refs="$1"
  local repo_dir="${2:-$(pwd)}"
  dev_kit_learning_merged_user_prompts "$refs" "$repo_dir" | sed -n '1,5p'
}

dev_kit_learning_prompt_theme_ids() {
  local refs="$1"
  local repo_dir="${2:-$(pwd)}"
  local prompts

  prompts="$(dev_kit_learning_merged_user_prompts "$refs" "$repo_dir" | tr '[:upper:]' '[:lower:]')"

  printf '%s\n' "$prompts" | grep -Eq 'readme|docs|good docs|docs first' && printf 'docs-first\n'
  printf '%s\n' "$prompts" | grep -Eq 'smoke tests|github actions|don'\''t run tests locally|talking too long each time|performance.*tests' && printf 'verification-scope\n'
  printf '%s\n' "$prompts" | grep -Eq 'cleanup|legacy|archive|leftovers' && printf 'cleanup-legacy\n'
  printf '%s\n' "$prompts" | grep -Eq 'separate configuration[s]? from code|configuration separate from code|configurations? from code|yml \+ shell|yaml \+ shell' && printf 'config-over-code\n'
  printf '%s\n' "$prompts" | grep -Eq 'agent.*repo context|engineering drift|repo-centric|dev\.kit agent' && printf 'repo-centric-agent-context\n'
}

dev_kit_learning_prompt_theme_message() {
  case "$1" in
    docs-first)
      printf '%s' 'Use README, docs, and tests as the first alignment surface before broad refactors so the implementation stays anchored to an explicit workflow.'
      ;;
    verification-scope)
      printf '%s' 'Keep local verification targeted and lightweight during iteration, then move broader or slower validation into GitHub Actions or other CI gates.'
      ;;
    cleanup-legacy)
      printf '%s' 'Treat cleanup of legacy modules, configs, and leftovers as part of the feature work so the repo keeps converging on the new operating model.'
      ;;
    config-over-code)
      printf '%s' 'Prefer reusable YAML/manifests plus small shell wrappers over embedding policy directly into imperative scripts.'
      ;;
    repo-centric-agent-context)
      printf '%s' 'Package agent context from repo artifacts and manifests so the workflow stays repo-centric and does not depend on ad hoc prompt memory.'
      ;;
  esac
}

dev_kit_learning_prompt_theme_template() {
  case "$1" in
    docs-first)
      printf '%s' '`Docs-first cleanup loop`: review README/docs/tests, restate the target workflow, then simplify code and remove mismatched legacy paths in the same pass.'
      ;;
    verification-scope)
      printf '%s' '`Verification scope`: run the smallest local check that proves the current change, defer heavyweight smoke coverage to CI, and call that tradeoff out explicitly.'
      ;;
    cleanup-legacy)
      printf '%s' '`Legacy reduction`: when a new direction is accepted, archive or delete conflicting old modules/configs instead of carrying both models forward.'
      ;;
    config-over-code)
      printf '%s' '`Config-over-code`: express repo rules in YAML/manifests first, then keep shell glue thin and composable.'
      ;;
    repo-centric-agent-context)
      printf '%s' '`Agent handoff`: refresh repo context, manifest, and AGENTS instructions before deeper agent work so the repo contract is the source of truth.'
      ;;
  esac
}

dev_kit_learning_flow_template() {
  case "$1" in
    issue-scope)
      printf '%s' '`Issue-to-scope`: start from the linked issue, confirm repo/workspace match, and restate the exact scope before changing code.'
      ;;
    workflow-source)
      printf '%s' '`Workflow tracing`: locate the actual workflow file or deploy source first, then trace the commands and supporting docs that really drive execution.'
      ;;
    verify-before-sync)
      printf '%s' '`Verify-before-sync`: run the relevant local build/test check before syncing, reporting completion, or preparing the PR.'
      ;;
    pr-chain)
      printf '%s' '`Delivery chain`: sync the branch, prepare the PR in repo style, and connect the related issue before close-out.'
      ;;
    post-follow-up)
      printf '%s' '`Post-merge follow-up`: gather release/workflow evidence and post a concise update with links, findings delta, and next steps.'
      ;;
    *)
      printf '%s' "$1"
      ;;
  esac
}
