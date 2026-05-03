#!/usr/bin/env bash

DEV_KIT_LEARNING_CONFIG_FILE="src/configs/learning-workflows.yaml"
DEV_KIT_LEARNING_DEFAULT_WORKFLOW="pr-lessons"

dev_kit_config_path() {
  printf "%s/%s" "$REPO_DIR" "$1"
}

dev_kit_archetypes_path() {
  dev_kit_config_path "src/configs/archetypes.yaml"
}

dev_kit_archetype_rule_ids() {
  dev_kit_yaml_named_block_ids "$(dev_kit_archetypes_path)" "archetypes"
}

dev_kit_archetype_facets() {
  dev_kit_yaml_nested_mapping_list "$(dev_kit_archetypes_path)" "archetypes" "$1" "$2"
}

dev_kit_archetype_description() {
  dev_kit_yaml_named_block_scalar "$(dev_kit_archetypes_path)" "archetypes" "$1" "description"
}

dev_kit_context_config_path() {
  dev_kit_config_path "src/configs/context-config.yaml"
}

dev_kit_context_list() {
  dev_kit_yaml_config_list "$(dev_kit_context_config_path)" "$1"
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

dev_kit_context_section_ids() {
  dev_kit_yaml_named_block_ids "$(dev_kit_context_config_path)" "context_sections"
}

dev_kit_context_section_field() {
  dev_kit_yaml_named_block_scalar "$(dev_kit_context_config_path)" "context_sections" "$1" "$2"
}

dev_kit_context_section_notes() {
  dev_kit_yaml_named_block_list "$(dev_kit_context_config_path)" "context_sections" "$1" "notes"
}

dev_kit_context_section_list() {
  dev_kit_yaml_named_block_list "$(dev_kit_context_config_path)" "context_sections" "$1" "$2"
}

dev_kit_context_section_context_list_values() {
  local section_id="$1"
  local key="$2"
  local list_name=""

  while IFS= read -r list_name; do
    [ -n "$list_name" ] || continue
    dev_kit_context_list "$list_name"
  done <<EOF
$(dev_kit_context_section_list "$section_id" "$key")
EOF
}

dev_kit_context_section_detection_list_values() {
  local section_id="$1"
  local key="$2"
  local list_name=""

  while IFS= read -r list_name; do
    [ -n "$list_name" ] || continue
    dev_kit_detection_list "$list_name"
  done <<EOF
$(dev_kit_context_section_list "$section_id" "$key")
EOF
}

dev_kit_context_section_list_has_value() {
  local section_id="$1"
  local key="$2"
  local expected="$3"
  local value=""

  while IFS= read -r value; do
    [ -n "$value" ] || continue
    [ "$value" = "$expected" ] && return 0
  done <<EOF
$(dev_kit_context_section_list "$section_id" "$key")
EOF

  return 1
}

dev_kit_ref_is_excluded() {
  case "$1" in
    package-lock.json|composer.lock|yarn.lock|pnpm-lock.yaml|bun.lockb|Cargo.lock|Gemfile.lock)
      return 0
      ;;
  esac

  return 1
}

dev_kit_repo_priority_refs_json() {
  dev_kit_repo_priority_refs "$1" | dev_kit_lines_to_json_array
}

dev_kit_repo_priority_list() {
  local repo_dir="${1:-$(pwd)}"
  local list_name="$2"
  local path=""
  local refs=""
  local pattern=""
  local match=""

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    path="${path#\"}"
    path="${path%\"}"
    case "$path" in
      *"*"*|*"?"*|*"["*)
        pattern="${path#./}"
        if [[ "$pattern" == */* ]]; then
          while IFS= read -r match; do
            [ -n "$match" ] || continue
            match="${match#"${repo_dir}/"}"
            case "$match" in
              *_old.md|*_old.markdown|README_old.md|readme_old.md) continue ;;
            esac
            dev_kit_ref_is_excluded "$match" && continue
            refs="${refs}./${match}
"
          done <<EOF
$(dev_kit_repo_find "$repo_dir" \( -type f -o -type d \) -path "$repo_dir/$pattern" -print 2>/dev/null | sort)
EOF
        else
          while IFS= read -r match; do
            [ -n "$match" ] || continue
            match="${match#"${repo_dir}/"}"
            case "$match" in
              *_old.md|*_old.markdown|README_old.md|readme_old.md) continue ;;
            esac
            dev_kit_ref_is_excluded "$match" && continue
            refs="${refs}./${match}
"
          done <<EOF
$(find "$repo_dir" -maxdepth 1 \( -type f -o -type d \) -name "$pattern" 2>/dev/null | sort)
EOF
        fi
        ;;
      *)
        if [ -e "$repo_dir/$path" ]; then
          dev_kit_ref_is_excluded "$path" && continue
          refs="${refs}./${path}
"
        fi
        ;;
    esac
  done <<EOF
$(dev_kit_context_list "$list_name")
EOF

  printf "%s" "$refs" | dev_kit_unique_lines_ci
}

dev_kit_repo_priority_refs() {
  local repo_dir="${1:-$(pwd)}"
  local list_name=""
  local refs=""

  while IFS= read -r list_name; do
    [ -n "$list_name" ] || continue
    refs="${refs}$(dev_kit_repo_priority_list "$repo_dir" "$list_name")
"
  done <<EOF
$(dev_kit_context_section_list "refs" "source_lists")
EOF

  if [ -z "$refs" ]; then
    dev_kit_repo_priority_list "$repo_dir" "priority_paths"
    return 0
  fi

  printf "%s" "$refs" | dev_kit_unique_lines_ci
}

dev_kit_repo_doc_refs() {
  dev_kit_repo_priority_list "${1:-$(pwd)}" "repo_doc_paths"
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

dev_kit_learning_claude_projects_root() {
  dev_kit_learning_source_discovery_scalar "claude_projects_root"
}

dev_kit_learning_config_enabled_sources() {
  dev_kit_learning_source_discovery_list "enabled_sources"
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
