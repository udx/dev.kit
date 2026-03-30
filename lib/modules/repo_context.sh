#!/usr/bin/env bash

DEV_KIT_CONTEXT_CONFIG_FILE="src/configs/context-config.yaml"

dev_kit_context_config_path() {
  printf "%s" "$REPO_DIR/$DEV_KIT_CONTEXT_CONFIG_FILE"
}

dev_kit_context_list() {
  local list_name="$1"

  dev_kit_yaml_mapping_list "$(dev_kit_context_config_path)" "lists" "$list_name"
}

dev_kit_repo_priority_refs_json() {
  dev_kit_repo_priority_refs "$1" | dev_kit_lines_to_json_array
}

dev_kit_repo_priority_refs() {
  local repo_dir="${1:-$(pwd)}"
  local path=""

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if [ -e "$repo_dir/$path" ]; then
      printf "./%s\n" "$path"
    fi
  done <<EOF
$(dev_kit_context_list "priority_paths")
EOF
}

dev_kit_repo_priority_repo_docs() {
  local repo_dir="${1:-$(pwd)}"
  local path=""

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if [ -e "$repo_dir/$path" ]; then
      printf "./%s\n" "$path"
    fi
  done <<EOF
CLAUDE.md
AGENTS.md
README.md
readme.md
docs/lessons-learned.md
docs/architecture.md
docs
EOF
}
