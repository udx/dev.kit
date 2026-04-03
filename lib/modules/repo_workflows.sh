#!/usr/bin/env bash

dev_kit_repo_entrypoints_json() {
  local repo_dir="$1"
  local verify_cmd=""
  local build_cmd=""
  local run_cmd=""

  verify_cmd="$(dev_kit_repo_factor_entrypoint "$repo_dir" "verification" || true)"
  build_cmd="$(dev_kit_repo_factor_entrypoint "$repo_dir" "build_release_run" || true)"
  run_cmd="$(dev_kit_repo_factor_entrypoint "$repo_dir" "runtime" || true)"

  printf '{ "verify": %s, "build": %s, "run": %s }' \
    "$(if [ -n "$verify_cmd" ]; then printf '"%s"' "$(dev_kit_json_escape "$verify_cmd")"; else printf 'null'; fi)" \
    "$(if [ -n "$build_cmd" ]; then printf '"%s"' "$(dev_kit_json_escape "$build_cmd")"; else printf 'null'; fi)" \
    "$(if [ -n "$run_cmd" ]; then printf '"%s"' "$(dev_kit_json_escape "$run_cmd")"; else printf 'null'; fi)"
}

dev_kit_repo_workflow_steps() {
  local repo_dir="$1"
  local verify_cmd=""
  local build_cmd=""
  local run_cmd=""
  local dependency_repos=""

  printf "read_repo|Read the highest-priority repo refs first|%s\n" "$(dev_kit_repo_priority_refs "$repo_dir" | dev_kit_lines_to_csv)"

  dependency_repos="$(dev_kit_repo_dependency_repo_text "$repo_dir")"
  if [ "$dependency_repos" != "none" ]; then
    printf "trace_deps|Inspect discovered repo dependencies referenced by workflows, package manifests, or container images|%s\n" "$dependency_repos"
  fi

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
