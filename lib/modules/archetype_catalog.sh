#!/usr/bin/env bash

dev_kit_archetype_signals_path() {
  printf "%s" "$REPO_DIR/src/configs/archetype-signals.yaml"
}

dev_kit_archetype_rules_path() {
  printf "%s" "$REPO_DIR/src/configs/archetype-rules.yaml"
}

dev_kit_archetype_signal_list() {
  local list_name="$1"
  local catalog_path=""

  catalog_path="$(dev_kit_archetype_signals_path)"
  dev_kit_yaml_mapping_list "$catalog_path" "lists" "$list_name"
}

dev_kit_archetype_rule_list() {
  local list_name="$1"
  local catalog_path=""

  catalog_path="$(dev_kit_archetype_rules_path)"
  dev_kit_yaml_mapping_list "$catalog_path" "lists" "$list_name"
}

dev_kit_archetype_facets() {
  local archetype="$1"
  local facet_type="$2"
  local catalog_path=""

  catalog_path="$(dev_kit_archetype_rules_path)"
  dev_kit_yaml_nested_mapping_list "$catalog_path" "archetypes" "$archetype" "$facet_type"
}
