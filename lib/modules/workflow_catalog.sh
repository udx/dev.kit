#!/usr/bin/env bash

DEV_KIT_WORKFLOW_CONFIG_FILE="src/configs/development-workflows.yaml"

dev_kit_workflow_config_path() {
  printf "%s" "$REPO_DIR/$DEV_KIT_WORKFLOW_CONFIG_FILE"
}

dev_kit_workflow_list() {
  local file_path=""

  file_path="$(dev_kit_workflow_config_path)"
  awk '
    $1 == "config:" { in_config = 1; next }
    in_config && $0 ~ /^  workflows:/ { in_workflows = 1; next }
    in_workflows && $0 ~ /^    [A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      print current
    }
  ' "$file_path"
}

dev_kit_workflow_description() {
  local workflow_id="$1"
  local file_path=""

  file_path="$(dev_kit_workflow_config_path)"
  awk -v workflow_id="$workflow_id" '
    $1 == "config:" { in_config = 1; next }
    in_config && $0 ~ /^  workflows:/ { in_workflows = 1; next }
    in_workflows && $0 ~ /^    [A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      in_target = (current == workflow_id)
      next
    }
    in_target && $0 ~ /^      description:/ {
      sub(/^[[:space:]]*description:[[:space:]]*/, "", $0)
      print
      exit
    }
  ' "$file_path"
}

dev_kit_workflow_step_lines() {
  local workflow_id="$1"
  local file_path=""

  file_path="$(dev_kit_workflow_config_path)"
  awk -v workflow_id="$workflow_id" '
    $1 == "config:" { in_config = 1; next }
    in_config && $0 ~ /^  workflows:/ { in_workflows = 1; next }
    in_workflows && $0 ~ /^    [A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      in_target = (current == workflow_id)
      in_steps = 0
      step_id = ""
      step_label = ""
      step_check = ""
      step_optional = ""
      next
    }
    in_target && $0 ~ /^      steps:/ {
      in_steps = 1
      next
    }
    in_steps && $0 ~ /^        - id:/ {
      if (step_id != "") {
        printf "%s|%s|%s|%s|%s\n", step_id, step_label, step_check, step_min_mode, step_optional
      }
      sub(/^[[:space:]]*-[[:space:]]*id:[[:space:]]*/, "", $0)
      step_id = $0
      step_label = ""
      step_check = ""
      step_min_mode = "dev"
      step_optional = "false"
      next
    }
    in_steps && $0 ~ /^          label:/ {
      sub(/^[[:space:]]*label:[[:space:]]*/, "", $0)
      step_label = $0
      next
    }
    in_steps && $0 ~ /^          check:/ {
      sub(/^[[:space:]]*check:[[:space:]]*/, "", $0)
      step_check = $0
      next
    }
    in_steps && $0 ~ /^          min_mode:/ {
      sub(/^[[:space:]]*min_mode:[[:space:]]*/, "", $0)
      step_min_mode = $0
      next
    }
    in_steps && $0 ~ /^          optional:/ {
      sub(/^[[:space:]]*optional:[[:space:]]*/, "", $0)
      step_optional = $0
      next
    }
    END {
      if (step_id != "") {
        printf "%s|%s|%s|%s|%s\n", step_id, step_label, step_check, step_min_mode, step_optional
      }
    }
  ' "$file_path"
}
