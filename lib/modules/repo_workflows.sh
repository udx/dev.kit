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

  printf "read_repo|Read the highest-priority repo refs first|%s\n" "$(dev_kit_repo_priority_refs "$repo_dir" | dev_kit_lines_to_csv)"

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

  printf "learn|Review lessons-learned and follow-up outputs after changes stabilize|dev.kit learn\n"

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
    if [ "$step_id" = "read_repo" ]; then
      # refs is a CSV of file paths — emit as JSON array with proper escaping
      local refs_json ref_item
      refs_json="["
      local ref_first=1
      while IFS= read -r ref_item; do
        [ -n "$ref_item" ] || continue
        if [ "$ref_first" -eq 0 ]; then refs_json="${refs_json}, "; fi
        refs_json="${refs_json}\"$(dev_kit_json_escape "$ref_item")\""
        ref_first=0
      done <<REFS
$(printf '%s\n' "$command" | awk '{ n=split($0,a,", "); for(i=1;i<=n;i++) if(a[i]!="") print a[i] }')
REFS
      refs_json="${refs_json}]"
      printf '{ "id": "%s", "label": "%s", "refs": %s }' \
        "$(dev_kit_json_escape "$step_id")" \
        "$(dev_kit_json_escape "$label")" \
        "$refs_json"
    else
      printf '{ "id": "%s", "label": "%s", "command": "%s" }' \
        "$(dev_kit_json_escape "$step_id")" \
        "$(dev_kit_json_escape "$label")" \
        "$(dev_kit_json_escape "$command")"
    fi
    first=0
  done <<EOF
$(dev_kit_repo_workflow_steps "$repo_dir")
EOF
  printf "]"
}
