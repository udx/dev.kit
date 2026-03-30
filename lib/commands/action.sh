#!/usr/bin/env bash

# @description: Generate grounded next actions for humans and agents

dev_kit_cmd_action() {
  local format="${1:-text}"
  local repo_dir="$(pwd)"
  local workflow_id="$DEV_KIT_SYNC_DEFAULT_WORKFLOW"
  local mode="$DEV_KIT_SYNC_DEFAULT_MODE"
  local refresh_context=0
  local yes=0
  local arg=""
  local positional_seen=0
  local repo_name=""
  local factors_json=""
  local guidance_json=""
  local findings_json=""
  local saved_context_json=""
  local priority_refs_json=""
  local refresh_requested_json="false"
  local refresh_performed_json="false"
  local git_workflow_json='{ "available": false }'
  local factor=""
  local saved_context_text="none"

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
      --refresh-context)
        refresh_context=1
        ;;
      --yes)
        yes=1
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

  if [ "$refresh_context" -eq 1 ]; then
    refresh_requested_json="true"
    dev_kit_repo_refresh_context "$repo_dir" "$yes"
    refresh_performed_json="true"
  fi

  repo_name="$(dev_kit_repo_name "$repo_dir")"
  if dev_kit_repo_has_saved_context "$repo_dir"; then
    saved_context_text="$(dev_kit_repo_saved_context_summary_text "$repo_dir")"
  fi

  if [ "$format" = "json" ]; then
    factors_json="$(dev_kit_repo_factor_summary_json "$repo_dir")"
    guidance_json="$(dev_kit_repo_agent_guidance_json "$repo_dir")"
    findings_json="$(dev_kit_repo_findings_json "$repo_dir")"
    saved_context_json="$(dev_kit_repo_saved_context_json "$repo_dir")"
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
      "saved_context=$saved_context_json" \
      "priority_refs=$priority_refs_json" \
      "knowledge_base=$(dev_kit_knowledge_hierarchy_json)" \
      "knowledge_sources=$(dev_kit_knowledge_preferred_sources | dev_kit_lines_to_json_array)" \
      "tooling_refs=$(dev_kit_tooling_repos_json)" \
      "operating_surface=$(dev_kit_knowledge_operating_surface_json)" \
      "responsibility_split=$(dev_kit_knowledge_responsibility_split_json)" \
      "workflow_contract=$(dev_kit_repo_workflow_json "$repo_dir")" \
      "git_workflow=$git_workflow_json" \
      "refresh_requested=$refresh_requested_json" \
      "refresh_performed=$refresh_performed_json"
    return 0
  fi

  echo "dev.kit action"
  echo "repo: $repo_name"
  echo "path: $repo_dir"
  echo "mode: $mode"
  echo "behavior: $DEV_KIT_SYNC_BEHAVIOR"
  echo "archetype: $(dev_kit_repo_primary_archetype "$repo_dir")"
  echo "archetypes: $(dev_kit_repo_archetypes_text "$repo_dir")"
  echo "facets: $(dev_kit_repo_facets_text "$repo_dir")"
  echo "profile: $(dev_kit_repo_primary_profile "$repo_dir")"
  echo "profiles: $(dev_kit_repo_profiles_text "$repo_dir")"
  echo "saved context: $saved_context_text"
  if [ "$refresh_context" -eq 1 ]; then
    echo "context refresh: completed"
  fi
  echo
  echo "factors:"
  while IFS= read -r factor; do
    [ -n "$factor" ] || continue
    printf '  - %s: %s\n' "$factor" "$(dev_kit_repo_factor_status "$repo_dir" "$factor")"
    printf '    evidence: %s\n' "$(dev_kit_repo_factor_evidence_text "$repo_dir" "$factor")"
    if dev_kit_repo_factor_entrypoint "$repo_dir" "$factor" >/dev/null 2>&1; then
      printf '    entrypoint: %s\n' "$(dev_kit_repo_factor_entrypoint "$repo_dir" "$factor")"
    fi
  done <<EOF
$(dev_kit_repo_factor_ids)
EOF
  echo
  echo "improvement priorities:"
  while IFS= read -r factor; do
    [ -n "$factor" ] || continue
    printf '  - %s\n' "$factor"
  done <<EOF
$(dev_kit_repo_findings_text "$repo_dir")
EOF
  echo
  echo "workflow contract:"
  dev_kit_repo_workflow_text "$repo_dir"
  echo
  if dev_kit_sync_has_git_repo "$repo_dir"; then
    echo "git workflow:"
    echo "  workflow: $(dev_kit_workflow_name "$workflow_id")"
    echo "  hint: $(dev_kit_sync_next_hint "$repo_dir")"
    echo
    echo "  repo_state:"
    dev_kit_sync_repo_state_compact_text "$repo_dir"
    echo
    echo "  hooks:"
    dev_kit_sync_hooks_focus_text "$repo_dir"
    echo
    echo "  capabilities:"
    dev_kit_sync_capability_warnings_text "$repo_dir"
    echo "  next:"
    dev_kit_sync_steps_text "$repo_dir" "$workflow_id" "$mode"
    echo
  else
    echo "git workflow: unavailable"
    echo
  fi
  echo "agent guidance:"
  while IFS= read -r arg; do
    [ -n "$arg" ] || continue
    printf '  - %s\n' "$arg"
  done <<EOF
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
