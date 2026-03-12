#!/usr/bin/env bash

dev_kit_detection_catalog_path() {
  printf "%s" "$REPO_DIR/src/configs/detection-patterns.yaml"
}

dev_kit_detection_signals_path() {
  printf "%s" "$REPO_DIR/src/configs/detection-signals.yaml"
}

dev_kit_detection_pattern() {
  local kind="$1"
  local catalog_path=""

  catalog_path="$(dev_kit_detection_catalog_path)"
  dev_kit_yaml_mapping_scalar "$catalog_path" "command_patterns" "$kind"
}

dev_kit_detection_list() {
  local list_name="$1"
  local catalog_path=""

  catalog_path="$(dev_kit_detection_signals_path)"
  dev_kit_yaml_mapping_list "$catalog_path" "lists" "$list_name"
}

dev_kit_detection_scalar() {
  local key="$1"
  local catalog_path=""

  catalog_path="$(dev_kit_detection_signals_path)"
  dev_kit_yaml_mapping_scalar "$catalog_path" "scalars" "$key"
}
