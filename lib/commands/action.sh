#!/usr/bin/env bash

# @description: Generate grounded next actions for humans and agents

dev_kit_cmd_action() {
  local format="${1:-text}"
  local repo_dir="$(pwd)"
  local workflow_id="$DEV_KIT_SYNC_DEFAULT_WORKFLOW"
  local mode="$DEV_KIT_SYNC_DEFAULT_MODE"
  local arg=""
  local positional_seen=0
  local repo_name=""
  local factors_json=""
  local guidance_json=""
  local findings_json=""
  local priority_refs_json=""
  local git_workflow_json='{ "available": false }'
  local factor=""

  shift || true

  while [ "$#" -gt 0 ]; do
    arg="$1"
    case "$arg" in
      --dev)
        mode="dev"
        ;;
      --ci)
        mode="ci"
        ;;
      --pr)
        mode="pr"
        ;;
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

  repo_name="$(dev_kit_repo_name "$repo_dir")"

  if [ "$format" = "json" ]; then
    factors_json="$(dev_kit_repo_factor_summary_json "$repo_dir")"
    guidance_json="$(dev_kit_repo_agent_guidance_json "$repo_dir")"
    findings_json="$(dev_kit_repo_findings_json "$repo_dir")"
    priority_refs_json="$(dev_kit_repo_priority_refs_json "$repo_dir")"
    if dev_kit_sync_has_git_repo "$repo_dir"; then
      git_workflow_json="$(dev_kit_action_git_workflow_json "$repo_dir" "$workflow_id" "$mode")"
    fi
    dev_kit_template_render "action.json" \
      "command=action" \
      "repo=$(dev_kit_json_escape "$repo_name")" \
      "path=$(dev_kit_json_escape "$repo_dir")" \
      "mode=$(dev_kit_json_escape "$mode")" \
      "behavior=$(dev_kit_json_escape "$DEV_KIT_SYNC_BEHAVIOR")" \
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
      "tooling_refs=$(dev_kit_tooling_repos_json)" \
      "operating_surface=$(dev_kit_knowledge_operating_surface_json)" \
      "responsibility_split=$(dev_kit_knowledge_responsibility_split_json)" \
      "workflow_contract=$(dev_kit_repo_workflow_json "$repo_dir")" \
      "git_workflow=$git_workflow_json"
    return 0
  fi

  dev_kit_output_title "dev.kit action"
  dev_kit_output_section "repo"
  dev_kit_output_row "repo" "$repo_name"
  dev_kit_output_row "path" "$repo_dir"
  dev_kit_output_row "mode" "$mode"
  dev_kit_output_row "behavior" "$DEV_KIT_SYNC_BEHAVIOR"
  dev_kit_output_row "archetype" "$(dev_kit_repo_primary_archetype "$repo_dir")"
  dev_kit_output_row "archetypes" "$(dev_kit_repo_archetypes_text "$repo_dir")"
  dev_kit_output_row "facets" "$(dev_kit_repo_facets_text "$repo_dir")"
  dev_kit_output_row "profile" "$(dev_kit_repo_primary_profile "$repo_dir")"
  dev_kit_output_row "profiles" "$(dev_kit_repo_profiles_text "$repo_dir")"
  dev_kit_output_section "factors"
  while IFS= read -r factor; do
    [ -n "$factor" ] || continue
    dev_kit_output_row "$factor" "$(dev_kit_repo_factor_status "$repo_dir" "$factor")"
    dev_kit_output_row "evidence" "$(dev_kit_repo_factor_evidence_text "$repo_dir" "$factor")"
    if dev_kit_repo_factor_entrypoint "$repo_dir" "$factor" >/dev/null 2>&1; then
      dev_kit_output_row "entrypoint" "$(dev_kit_repo_factor_entrypoint "$repo_dir" "$factor")"
    fi
  done <<EOF
$(dev_kit_repo_factor_ids)
EOF
  dev_kit_output_section "improvement priorities"
  dev_kit_output_list_from_lines <<EOF
$(dev_kit_repo_findings_text "$repo_dir")
EOF
  dev_kit_output_section "workflow contract"
  dev_kit_repo_workflow_text "$repo_dir"
  if dev_kit_sync_has_git_repo "$repo_dir"; then
    dev_kit_output_section "git workflow"
    dev_kit_output_row "workflow" "$(dev_kit_workflow_name "$workflow_id")"
    dev_kit_output_row "hint" "$(dev_kit_sync_next_hint "$repo_dir")"
    echo
    dev_kit_output_row "repo_state" ""
    dev_kit_sync_repo_state_compact_text "$repo_dir"
    echo
    dev_kit_output_row "hooks" ""
    dev_kit_sync_hooks_focus_text "$repo_dir"
    echo
    dev_kit_output_row "capabilities" ""
    dev_kit_sync_capability_warnings_text "$repo_dir"
    dev_kit_output_row "next" ""
    dev_kit_sync_steps_text "$repo_dir" "$workflow_id" "$mode"
  else
    dev_kit_output_section "git workflow"
    dev_kit_output_row "status" "unavailable"
  fi
  dev_kit_output_section "agent guidance"
  dev_kit_output_list_from_lines <<EOF
$(dev_kit_repo_agent_guidance_text "$repo_dir")
EOF
}

dev_kit_action_git_workflow_json() {
  local repo_dir="$1"
  local workflow_id="$2"
  local mode="$3"

  printf '{ "available": true, "workflow": { "id": "%s", "name": "%s" }, "mode": "%s", "behavior": "%s", "description": "%s", "next_hint": "%s", "repo_state": %s, "hooks": %s, "capabilities": %s, "steps": %s }' \
    "$(dev_kit_json_escape "$workflow_id")" \
    "$(dev_kit_json_escape "$(dev_kit_workflow_name "$workflow_id")")" \
    "$(dev_kit_json_escape "$mode")" \
    "$(dev_kit_json_escape "$DEV_KIT_SYNC_BEHAVIOR")" \
    "$(dev_kit_json_escape "$(dev_kit_workflow_description "$workflow_id")")" \
    "$(dev_kit_json_escape "$(dev_kit_sync_next_hint "$repo_dir")")" \
    "$(dev_kit_sync_repo_state_json "$repo_dir")" \
    "$(dev_kit_sync_hooks_json "$repo_dir")" \
    "$(dev_kit_sync_capabilities_json "$repo_dir")" \
    "$(dev_kit_sync_steps_json "$repo_dir" "$workflow_id" "$mode")"
}
