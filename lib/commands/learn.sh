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

  local lastrun_file="${repo_dir}/.dev-kit/learn-last-run"
  local session_refs
  session_refs="$(dev_kit_learning_all_session_refs "$repo_dir" "$lastrun_file")"

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
    dev_kit_output_list_item "no agent sessions found for this repo"
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
  issue_urls="$(dev_kit_learning_merged_issue_urls "$session_refs" "$repo_dir")"
  if [ -n "$issue_urls" ]; then
    dev_kit_output_section "shared context"
    dev_kit_output_list_item "Use the GitHub issue as the cross-repo context root."
    dev_kit_output_list_from_lines <<EOF
$issue_urls
EOF
  fi

  # write artifact and update last-run
  local artifact_path
  artifact_path="$(dev_kit_learning_write_artifact "$repo_dir" "$session_refs")"
  if [ -n "$artifact_path" ]; then
    dev_kit_output_section "artifact"
    dev_kit_output_list_item "$artifact_path"
  fi

  printf "%d\n" "$(date +%s)" > "$lastrun_file" 2>/dev/null || true

  dev_kit_output_section "send to"
  dev_kit_learning_destinations_text "$workflow_id"
}

# ── artifact writer ───────────────────────────────────────────────────────────

dev_kit_learning_write_artifact() {
  local repo_dir="$1"
  local refs="$2"
  local repo_name date_stamp artifact_path

  repo_name="$(basename "$repo_dir")"
  date_stamp="$(date +%Y-%m-%d)"
  artifact_path="${repo_dir}/.dev-kit/lessons-${repo_name}-${date_stamp}.md"

  mkdir -p "${repo_dir}/.dev-kit" 2>/dev/null || true

  {
    printf '# Lessons — %s — %s\n\n' "$repo_name" "$date_stamp"

    # source summary
    local counts claude_count codex_count
    counts="$(dev_kit_learning_source_counts "$refs")"
    claude_count="$(printf "%s" "$counts" | sed 's/claude:\([0-9]*\).*/\1/')"
    codex_count="$(printf "%s" "$counts" | sed 's/.*codex:\([0-9]*\)/\1/')"
    printf 'Sources: claude (%s session(s)), codex (%s session(s))\n\n' \
      "$claude_count" "$codex_count"

    # session prompts
    local prompts
    prompts="$(dev_kit_learning_merged_user_prompts "$refs" "$repo_dir")"
    if [ -n "$prompts" ]; then
      printf '## Session prompts\n\n'
      while IFS= read -r line; do
        [ -n "$line" ] || continue
        printf -- '- %s\n' "$line"
      done <<EOF
$prompts
EOF
      printf '\n'
    fi

    # operational references (URLs)
    local issue_urls pr_urls
    issue_urls="$(dev_kit_learning_merged_issue_urls "$refs" "$repo_dir")"
    pr_urls="$(dev_kit_learning_merged_pr_urls "$refs" "$repo_dir")"
    if [ -n "$issue_urls" ] || [ -n "$pr_urls" ]; then
      printf '## Operational references\n\n'
      while IFS= read -r url; do
        [ -n "$url" ] || continue
        printf -- '- %s\n' "$url"
      done <<EOF
$issue_urls
$pr_urls
EOF
      printf '\n'
    fi

    # patterns observed
    local flow_matches
    flow_matches="$(dev_kit_learning_merged_flow_matches "$refs" "$repo_dir")"
    if [ -n "$flow_matches" ]; then
      printf '## Patterns observed\n\n'
      while IFS= read -r flow_id; do
        [ -n "$flow_id" ] || continue
        printf -- '- %s\n' "$flow_id"
      done <<EOF
$flow_matches
EOF
      printf '\n'
    fi
  } > "$artifact_path" 2>/dev/null || return 0

  printf "%s" "$artifact_path"
}
