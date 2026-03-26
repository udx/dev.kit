#!/usr/bin/env bash

DEV_KIT_CONTEXT_CONFIG_FILE="src/configs/context-config.yaml"

dev_kit_context_config_path() {
  printf "%s" "$REPO_DIR/$DEV_KIT_CONTEXT_CONFIG_FILE"
}

dev_kit_context_list() {
  local list_name="$1"
  local catalog_path=""

  catalog_path="$(dev_kit_context_config_path)"
  dev_kit_yaml_mapping_list "$catalog_path" "lists" "$list_name"
}
