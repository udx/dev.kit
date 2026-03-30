#!/usr/bin/env bash

dev_kit_repo_workflow_steps() {
  local repo_dir="$1"
  local verify_cmd=""
  local build_cmd=""
  local run_cmd=""

  printf "read_repo|Read the highest-priority repo refs first|%s\n" "$(dev_kit_repo_priority_refs "$repo_dir" | dev_kit_lines_to_csv)"
  printf "read_tooling|Inspect shared tooling and dependency repos when workflows depend on them|%s\n" "$(dev_kit_tooling_repo_lines | awk -F'|' '{print $1}' | dev_kit_lines_to_csv)"

  verify_cmd="$(dev_kit_repo_factor_entrypoint "$repo_dir" "verification" || true)"
  if [ -n "$verify_cmd" ]; then
    printf "verify|Run the canonical verification command|%s\n" "$verify_cmd"
  fi

  build_cmd="$(dev_kit_repo_factor_entrypoint "$repo_dir" "build_release_run" || true)"
  if [ -n "$build_cmd" ]; then
    printf "build|Run the canonical build command when needed|%s\n" "$build_cmd"
  fi

  run_cmd="$(dev_kit_repo_factor_entrypoint "$repo_dir" "runtime" || true)"
  if [ -n "$run_cmd" ]; then
    printf "run|Use the canonical runtime command instead of ad hoc startup paths|%s\n" "$run_cmd"
  fi

  if dev_kit_sync_has_git_repo "$repo_dir" >/dev/null 2>&1; then
    printf "action|Evaluate the git workflow before pushing or opening review|dev.kit action\n"
  fi

  printf "learn|Review lessons-learned and follow-up outputs after changes stabilize|dev.kit learn\n"

  if dev_kit_repo_has_saved_context "$repo_dir"; then
    printf "refresh_context|Refresh repo-local continuity files after structural changes|dev.kit action --refresh-context --yes\n"
  fi
}

dev_kit_repo_workflow_text() {
  local repo_dir="$1"
  local line=""
  local step_id=""
  local label=""
  local command=""

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    step_id="${line%%|*}"
    line="${line#*|}"
    label="${line%%|*}"
    command="${line#*|}"
    printf '  - %s: %s\n' "$step_id" "$label"
    printf '    command: %s\n' "$command"
  done <<EOF
$(dev_kit_repo_workflow_steps "$repo_dir")
EOF
}

dev_kit_repo_workflow_json() {
  local repo_dir="$1"
  local line=""
  local step_id=""
  local label=""
  local command=""
  local first=1

  printf "["
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    step_id="${line%%|*}"
    line="${line#*|}"
    label="${line%%|*}"
    command="${line#*|}"
    if [ "$first" -eq 0 ]; then
      printf ", "
    fi
    printf '{ "id": "%s", "label": "%s", "command": "%s" }' \
      "$(dev_kit_json_escape "$step_id")" \
      "$(dev_kit_json_escape "$label")" \
      "$(dev_kit_json_escape "$command")"
    first=0
  done <<EOF
$(dev_kit_repo_workflow_steps "$repo_dir")
EOF
  printf "]"
}
