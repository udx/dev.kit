#!/usr/bin/env bash

DEV_KIT_KNOWLEDGE_CONFIG_FILE="src/configs/knowledge-base.yaml"
DEV_KIT_LEARNING_CONFIG_FILE="src/configs/learning-workflows.yaml"
DEV_KIT_LEARNING_DEFAULT_WORKFLOW="pr-lessons"
DEV_KIT_PRACTICES_CONFIG_FILE="src/configs/development-practices.yaml"
DEV_KIT_WORKFLOW_CONFIG_FILE="src/configs/development-workflows.yaml"

dev_kit_config_path() {
  printf "%s/%s" "$REPO_DIR" "$1"
}

dev_kit_archetype_signals_path() {
  dev_kit_config_path "src/configs/archetype-signals.yaml"
}

dev_kit_archetype_rules_path() {
  dev_kit_config_path "src/configs/archetype-rules.yaml"
}

dev_kit_archetype_signal_list() {
  dev_kit_yaml_mapping_list "$(dev_kit_archetype_signals_path)" "lists" "$1"
}

dev_kit_archetype_rule_list() {
  dev_kit_yaml_mapping_list "$(dev_kit_archetype_rules_path)" "lists" "$1"
}

dev_kit_archetype_facets() {
  dev_kit_yaml_nested_mapping_list "$(dev_kit_archetype_rules_path)" "archetypes" "$1" "$2"
}

dev_kit_context_config_path() {
  dev_kit_config_path "src/configs/context-config.yaml"
}

dev_kit_context_list() {
  dev_kit_yaml_mapping_list "$(dev_kit_context_config_path)" "lists" "$1"
}

dev_kit_context_marker_group_ids() {
  dev_kit_yaml_named_block_ids "$(dev_kit_context_config_path)" "marker_groups"
}

dev_kit_context_marker_group_field() {
  dev_kit_yaml_named_block_scalar "$(dev_kit_context_config_path)" "marker_groups" "$1" "$2"
}

dev_kit_context_marker_group_paths() {
  dev_kit_yaml_named_block_list "$(dev_kit_context_config_path)" "marker_groups" "$1" "paths"
}

dev_kit_repo_priority_refs_json() {
  dev_kit_repo_priority_refs "$1" | dev_kit_lines_to_json_array
}

dev_kit_repo_priority_list() {
  local repo_dir="${1:-$(pwd)}"
  local list_name="$2"
  local path=""
  local refs=""

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if [ -e "$repo_dir/$path" ]; then
      refs="${refs}./${path}
"
    fi
  done <<EOF
$(dev_kit_context_list "$list_name")
EOF

  printf "%s" "$refs" | dev_kit_unique_lines_ci
}

dev_kit_repo_priority_refs() {
  dev_kit_repo_priority_list "${1:-$(pwd)}" "priority_paths"
}

dev_kit_repo_doc_refs() {
  dev_kit_repo_priority_list "${1:-$(pwd)}" "repo_doc_paths"
}

dev_kit_knowledge_config_path() {
  dev_kit_config_path "$DEV_KIT_KNOWLEDGE_CONFIG_FILE"
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

dev_kit_learning_config_path() {
  dev_kit_config_path "$DEV_KIT_LEARNING_CONFIG_FILE"
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

dev_kit_learning_source_discovery_scalar() {
  dev_kit_yaml_mapping_scalar "$(dev_kit_learning_config_path)" "source_discovery" "$1"
}

dev_kit_learning_source_discovery_list() {
  dev_kit_yaml_mapping_list "$(dev_kit_learning_config_path)" "source_discovery" "$1"
}

dev_kit_learning_session_rule_ids() {
  dev_kit_yaml_named_block_ids "$(dev_kit_learning_config_path)" "session_rules"
}

dev_kit_learning_session_rule_message() {
  dev_kit_yaml_named_block_scalar "$(dev_kit_learning_config_path)" "session_rules" "$1" "message"
}

dev_kit_learning_session_rule_threshold() {
  dev_kit_yaml_named_block_scalar "$(dev_kit_learning_config_path)" "session_rules" "$1" "threshold"
}

dev_kit_learning_session_rule_patterns() {
  dev_kit_yaml_named_block_list "$(dev_kit_learning_config_path)" "session_rules" "$1" "patterns"
}

dev_kit_learning_session_flow_ids() {
  dev_kit_yaml_named_block_ids "$(dev_kit_learning_config_path)" "session_flow"
}

dev_kit_learning_session_flow_message() {
  dev_kit_yaml_named_block_scalar "$(dev_kit_learning_config_path)" "session_flow" "$1" "message"
}

dev_kit_learning_session_flow_threshold() {
  dev_kit_yaml_named_block_scalar "$(dev_kit_learning_config_path)" "session_flow" "$1" "threshold"
}

dev_kit_learning_session_flow_patterns() {
  dev_kit_yaml_named_block_list "$(dev_kit_learning_config_path)" "session_flow" "$1" "patterns"
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

dev_kit_practices_config_path() {
  dev_kit_config_path "$DEV_KIT_PRACTICES_CONFIG_FILE"
}

dev_kit_practice_message() {
  local practice_id="$1"

  awk -v practice_id="$practice_id" '
    $1 == "config:" { in_config = 1; next }
    in_config && $1 == "practices:" { in_practices = 1; next }
    in_practices && $1 == "-" && $2 == "id:" {
      current_id = $3
      in_target = (current_id == practice_id)
      next
    }
    in_target && $1 == "message:" {
      $1 = ""
      sub(/^ /, "")
      print
      exit
    }
  ' "$(dev_kit_practices_config_path)"
}

dev_kit_practice_message_list() {
  local practice_id=""

  for practice_id in "$@"; do
    [ -n "$practice_id" ] || continue
    dev_kit_practice_message "$practice_id"
  done
}

dev_kit_rule_catalog_path() {
  dev_kit_config_path "src/configs/audit-rules.yaml"
}

dev_kit_rule_field() {
  local rule_id="$1"
  local field_name="$2"

  awk -v rule_id="$rule_id" -v field_name="$field_name" '
    $1 == "config:" {
      in_config = 1
      next
    }
    in_config && $1 == "rules:" {
      in_rules = 1
      next
    }
    in_rules && $1 == "-" && $2 == "id:" {
      current_id = $3
      in_rule = (current_id == rule_id)
      next
    }
    in_rule && $1 == field_name ":" {
      $1 = ""
      sub(/^ /, "")
      print
      exit
    }
  ' "$(dev_kit_rule_catalog_path)"
}

dev_kit_rule_message() {
  dev_kit_rule_field "$1" "message"
}

dev_kit_workflow_config_path() {
  dev_kit_config_path "$DEV_KIT_WORKFLOW_CONFIG_FILE"
}

dev_kit_workflow_default_scalar() {
  dev_kit_yaml_mapping_scalar "$(dev_kit_workflow_config_path)" "defaults" "$1"
}

dev_kit_workflow_default_list() {
  dev_kit_yaml_mapping_list "$(dev_kit_workflow_config_path)" "defaults" "$1"
}

dev_kit_sync_default_workflow() {
  dev_kit_workflow_default_scalar "workflow"
}

dev_kit_sync_behavior() {
  dev_kit_workflow_default_scalar "behavior"
}

dev_kit_sync_default_hooks_dir() {
  dev_kit_workflow_default_scalar "hooks_dir"
}

dev_kit_sync_text_max_next_steps() {
  dev_kit_workflow_default_scalar "text_max_next_steps"
}

dev_kit_sync_branch_role_base() {
  dev_kit_yaml_nested_mapping_scalar "$(dev_kit_workflow_config_path)" "defaults" "branch_roles" "base"
}

dev_kit_sync_branch_role_feature() {
  dev_kit_yaml_nested_mapping_scalar "$(dev_kit_workflow_config_path)" "defaults" "branch_roles" "feature"
}

dev_kit_sync_base_branch_names() {
  dev_kit_workflow_default_list "base_branch_names"
}

dev_kit_workflow_description() {
  dev_kit_yaml_named_block_scalar "$(dev_kit_workflow_config_path)" "workflows" "$1" "description"
}

dev_kit_workflow_name() {
  dev_kit_yaml_named_block_scalar "$(dev_kit_workflow_config_path)" "workflows" "$1" "name"
}

dev_kit_workflow_step_lines() {
  local workflow_id="$1"

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
      next
    }
    in_target && $0 ~ /^      steps:/ {
      in_steps = 1
      next
    }
    in_steps && $0 ~ /^        - id:/ {
      if (step_id != "") {
        printf "%s|%s|%s\n", step_id, step_label, step_check
      }
      sub(/^[[:space:]]*-[[:space:]]*id:[[:space:]]*/, "", $0)
      step_id = $0
      step_label = ""
      step_check = ""
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
    END {
      if (step_id != "") {
        printf "%s|%s|%s\n", step_id, step_label, step_check
      }
    }
  ' "$(dev_kit_workflow_config_path)"
}
