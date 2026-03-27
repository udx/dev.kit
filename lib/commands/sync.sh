#!/usr/bin/env bash

# @description: Evaluate the configured development sync workflow

dev_kit_cmd_sync() {
  local format="${1:-text}"
  local repo_dir="$(pwd)"
  local workflow_id="$DEV_KIT_SYNC_DEFAULT_WORKFLOW"
  local mode="$DEV_KIT_SYNC_DEFAULT_MODE"
  local arg=""
  local positional_seen=0

  shift || true

  while [ "$#" -gt 0 ]; do
    arg="$1"
    case "$arg" in
      --dev)
        mode="dev"
        ;;
      --ci)
        mode="ci"
        ;;
      --pr)
        mode="pr"
        ;;
      *)
        if [ "$positional_seen" -eq 0 ]; then
          repo_dir="$arg"
          positional_seen=1
        elif [ "$positional_seen" -eq 1 ]; then
          workflow_id="$arg"
          positional_seen=2
        fi
        ;;
    esac
    shift
  done

  if ! dev_kit_sync_has_git_repo "$repo_dir"; then
    echo "Current directory is not a git repository: $repo_dir" >&2
    return 1
  fi

  if [ "$format" = "json" ]; then
    dev_kit_template_render "sync.json" \
      "command=sync" \
      "repo=$(dev_kit_json_escape "$repo_dir")" \
      "workflow=$(dev_kit_json_escape "$workflow_id")" \
      "mode=$(dev_kit_json_escape "$mode")" \
      "behavior=$(dev_kit_json_escape "$DEV_KIT_SYNC_BEHAVIOR")" \
      "description=$(dev_kit_json_escape "$(dev_kit_workflow_description "$workflow_id")")" \
      "capabilities=$(dev_kit_sync_capabilities_json "$repo_dir")" \
      "steps=$(dev_kit_sync_steps_json "$repo_dir" "$workflow_id" "$mode")"
    return 0
  fi

  dev_kit_template_render "sync.txt" \
    "repo_dir=$repo_dir" \
    "workflow_id=$workflow_id" \
    "mode=$mode" \
    "behavior=$DEV_KIT_SYNC_BEHAVIOR" \
    "description=$(dev_kit_workflow_description "$workflow_id")" \
    "capabilities_text=$(dev_kit_sync_capabilities_text "$repo_dir")" \
    "steps_text=$(dev_kit_sync_steps_text "$repo_dir" "$workflow_id" "$mode")"
}
