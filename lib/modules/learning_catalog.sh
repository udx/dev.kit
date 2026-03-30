#!/usr/bin/env bash

DEV_KIT_LEARNING_CONFIG_FILE="src/configs/learning-workflows.yaml"
DEV_KIT_LEARNING_DEFAULT_WORKFLOW="pr-lessons"

dev_kit_learning_config_path() {
  printf "%s" "$REPO_DIR/$DEV_KIT_LEARNING_CONFIG_FILE"
}

dev_kit_learning_workflow_name() {
  dev_kit_yaml_named_block_scalar "$(dev_kit_learning_config_path)" "workflows" "$1" "name"
}

dev_kit_learning_workflow_description() {
  dev_kit_yaml_named_block_scalar "$(dev_kit_learning_config_path)" "workflows" "$1" "description"
}

dev_kit_learning_workflow_list_values() {
  dev_kit_yaml_named_block_list "$(dev_kit_learning_config_path)" "workflows" "$1" "$2"
}

dev_kit_learning_workflow_sources() {
  dev_kit_learning_workflow_list_values "$1" "sources"
}

dev_kit_learning_workflow_destinations() {
  dev_kit_learning_workflow_list_values "$1" "destinations"
}

dev_kit_learning_workflow_sources_text() {
  dev_kit_learning_workflow_sources "$1" | dev_kit_lines_to_csv
}

dev_kit_learning_workflow_destinations_text() {
  dev_kit_learning_workflow_destinations "$1" | dev_kit_lines_to_csv
}

dev_kit_learning_destination_status() {
  local destination="$1"

  case "$destination" in
    gh_issue)
      if ! dev_kit_sync_can_run_gh; then
        printf "%s" "requires gh"
      elif [ "$(dev_kit_sync_gh_auth_state)" = "available" ]; then
        printf "%s" "ready"
      else
        printf "%s" "requires gh auth"
      fi
      ;;
    wiki|slack)
      printf "%s" "planned"
      ;;
    lessons_report)
      printf "%s" "ready"
      ;;
    *)
      printf "%s" "planned"
      ;;
  esac
}

dev_kit_learning_destinations_text() {
  local workflow_id="$1"
  local destination=""

  while IFS= read -r destination; do
    [ -n "$destination" ] || continue
    printf '  - %s: %s\n' "$destination" "$(dev_kit_learning_destination_status "$destination")"
  done <<EOF
$(dev_kit_learning_workflow_destinations "$workflow_id")
EOF
}

dev_kit_learning_destinations_json() {
  local workflow_id="$1"
  local destination=""
  local first=1

  printf "["
  while IFS= read -r destination; do
    [ -n "$destination" ] || continue
    if [ "$first" -eq 0 ]; then
      printf ", "
    fi
    printf '{ "id": "%s", "status": "%s" }' \
      "$(dev_kit_json_escape "$destination")" \
      "$(dev_kit_json_escape "$(dev_kit_learning_destination_status "$destination")")"
    first=0
  done <<EOF
$(dev_kit_learning_workflow_destinations "$workflow_id")
EOF
  printf "]"
}
