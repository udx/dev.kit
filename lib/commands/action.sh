#!/usr/bin/env bash

# @description: Generate grounded next actions for humans and agents

dev_kit_cmd_action() {
  local format="${1:-text}"
  local repo_dir="$(pwd)"
  local repo_root=""
  local workflow_id="$(dev_kit_sync_default_workflow)"
  local arg=""
  local positional_seen=0
  local repo_name=""
  local factors_json=""
  local guidance_json=""
  local findings_json=""
  local priority_refs_json=""
  local git_workflow_json='{ "available": false }'
  local next_git_action=""
  local factor=""

  shift || true

  while [ "$#" -gt 0 ]; do
    arg="$1"
    case "$arg" in
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

  repo_root="$(dev_kit_repo_root "$repo_dir")"
  repo_dir="${repo_root:-$repo_dir}"
  repo_name="$(dev_kit_repo_name "$repo_dir")"

  if [ "$format" = "json" ]; then
    factors_json="$(dev_kit_repo_factor_summary_json "$repo_dir")"
    guidance_json="$(dev_kit_repo_agent_guidance_json "$repo_dir")"
    findings_json="$(dev_kit_repo_findings_json "$repo_dir")"
    priority_refs_json="$(dev_kit_repo_priority_refs_json "$repo_dir")"
    if dev_kit_sync_has_git_repo "$repo_dir"; then
      git_workflow_json="$(dev_kit_action_git_workflow_json "$repo_dir" "$workflow_id")"
      next_git_action="$(dev_kit_sync_next_hint "$repo_dir")"
    fi
    dev_kit_template_render "action.json" \
      "command=action" \
      "repo=$(dev_kit_json_escape "$repo_name")" \
      "path=$(dev_kit_json_escape "$repo_dir")" \
      "entrypoints=$(dev_kit_repo_entrypoints_json "$repo_dir")" \
      "next_git_action=$(dev_kit_json_escape "$next_git_action")" \
      "markers=$(dev_kit_repo_markers_json "$repo_dir")" \
      "behavior=$(dev_kit_json_escape "$(dev_kit_sync_behavior)")" \
      "archetype=$(dev_kit_json_escape "$(dev_kit_repo_primary_archetype "$repo_dir")")" \
      "archetypes=$(dev_kit_repo_archetypes_json "$repo_dir")" \
      "facets=$(dev_kit_repo_facets_json "$repo_dir")" \
      "profile=$(dev_kit_json_escape "$(dev_kit_repo_primary_profile "$repo_dir")")" \
      "profiles=$(dev_kit_repo_profiles_json "$repo_dir")" \
      "factors=$factors_json" \
      "guidance=$guidance_json" \
      "findings=$findings_json" \
      "priority_refs=$priority_refs_json" \
      "knowledge_base=$(dev_kit_knowledge_hierarchy_json)" \
      "knowledge_sources=$(dev_kit_knowledge_preferred_sources | dev_kit_lines_to_json_array)" \
      "source_chain=$(dev_kit_repo_source_chain_json "$repo_dir")" \
      "module_docs=$(dev_kit_repo_infra_module_docs_json "$repo_dir")" \
      "workflow_contract=$(dev_kit_repo_workflow_json "$repo_dir")" \
      "agent_contract=$(dev_kit_repo_agent_contract_json "$repo_dir")" \
      "git_workflow=$git_workflow_json"
    return 0
  fi

  dev_kit_output_title "dev.kit action"
  dev_kit_output_summary "${repo_name} • $(dev_kit_repo_primary_archetype "$repo_dir") • grounded next actions"
  dev_kit_output_section "read first"
  dev_kit_output_list_from_lines <<EOF
$(dev_kit_repo_priority_refs "$repo_dir" | dev_kit_output_first_lines 4)
EOF

  dev_kit_output_section "do next"
  if dev_kit_sync_has_git_repo "$repo_dir"; then
    dev_kit_output_list_item "$(dev_kit_sync_next_hint "$repo_dir")"
  fi
  dev_kit_output_list_from_lines <<EOF
$(dev_kit_repo_findings_text "$repo_dir" | dev_kit_output_first_lines 3)
EOF
}

dev_kit_action_git_workflow_json() {
  local repo_dir="$1"
  local workflow_id="$2"

  printf '{ "available": true, "workflow": { "id": "%s", "name": "%s" }, "behavior": "%s", "description": "%s", "next_hint": "%s", "repo_state": %s, "hooks": %s, "capabilities": %s, "steps": %s }' \
    "$(dev_kit_json_escape "$workflow_id")" \
    "$(dev_kit_json_escape "$(dev_kit_workflow_name "$workflow_id")")" \
    "$(dev_kit_json_escape "$(dev_kit_sync_behavior)")" \
    "$(dev_kit_json_escape "$(dev_kit_workflow_description "$workflow_id")")" \
    "$(dev_kit_json_escape "$(dev_kit_sync_next_hint "$repo_dir")")" \
    "$(dev_kit_sync_repo_state_json "$repo_dir")" \
    "$(dev_kit_sync_hooks_json "$repo_dir")" \
    "$(dev_kit_sync_capabilities_json "$repo_dir")" \
    "$(dev_kit_sync_steps_json "$repo_dir" "$workflow_id")"
}
