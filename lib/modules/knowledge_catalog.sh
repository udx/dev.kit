#!/usr/bin/env bash

DEV_KIT_KNOWLEDGE_CONFIG_FILE="src/configs/knowledge-base.yaml"

dev_kit_knowledge_config_path() {
  printf "%s" "$REPO_DIR/$DEV_KIT_KNOWLEDGE_CONFIG_FILE"
}

dev_kit_knowledge_local_repos_root() {
  dev_kit_yaml_mapping_scalar "$(dev_kit_knowledge_config_path)" "hierarchy" "local_repos_root"
}

dev_kit_knowledge_remote_org_root() {
  dev_kit_yaml_mapping_scalar "$(dev_kit_knowledge_config_path)" "hierarchy" "remote_org_root"
}

dev_kit_knowledge_hierarchy_json() {
  printf '{ "local_repos_root": "%s", "remote_org_root": "%s" }' \
    "$(dev_kit_json_escape "$(dev_kit_knowledge_local_repos_root)")" \
    "$(dev_kit_json_escape "$(dev_kit_knowledge_remote_org_root)")"
}

dev_kit_knowledge_preferred_sources() {
  dev_kit_yaml_nested_mapping_list "$(dev_kit_knowledge_config_path)" "sources" "preferred" "items"
}

dev_kit_knowledge_preferred_sources_text() {
  dev_kit_knowledge_preferred_sources | dev_kit_lines_to_csv
}
