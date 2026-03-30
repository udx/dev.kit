#!/usr/bin/env bash

# @description: Explore repo identity, workflows, and knowledge sources

dev_kit_cmd_explore() {
  local format="${1:-text}"
  local repo_dir="${2:-$(pwd)}"
  local repo_root=""
  local repo_name=""
  local factors_json=""

  repo_root="$(dev_kit_repo_root "$repo_dir")"
  repo_dir="${repo_root:-$repo_dir}"
  repo_name="$(dev_kit_repo_name "$repo_dir")"

  if [ "$format" = "json" ]; then
    factors_json="$(dev_kit_repo_factor_summary_json "$repo_dir")"
    dev_kit_template_render "explore.json" \
      "command=explore" \
      "repo=$(dev_kit_json_escape "$repo_name")" \
      "path=$(dev_kit_json_escape "$repo_dir")" \
      "markers=$(dev_kit_repo_markers_json "$repo_dir")" \
      "workflow_refs=$(dev_kit_repo_workflow_refs_json "$repo_dir")" \
      "archetype=$(dev_kit_json_escape "$(dev_kit_repo_primary_archetype "$repo_dir")")" \
      "archetypes=$(dev_kit_repo_archetypes_json "$repo_dir")" \
      "facets=$(dev_kit_repo_facets_json "$repo_dir")" \
      "profile=$(dev_kit_json_escape "$(dev_kit_repo_primary_profile "$repo_dir")")" \
      "profiles=$(dev_kit_repo_profiles_json "$repo_dir")" \
      "factors=$factors_json" \
      "priority_refs=$(dev_kit_repo_priority_refs_json "$repo_dir")" \
      "knowledge_base=$(dev_kit_knowledge_hierarchy_json)" \
      "knowledge_sources=$(dev_kit_knowledge_preferred_sources | dev_kit_lines_to_json_array)" \
      "source_chain=$(dev_kit_repo_source_chain_json "$repo_dir")" \
      "module_docs=$(dev_kit_repo_infra_module_docs_json "$repo_dir")" \
      "workflow_contract=$(dev_kit_repo_workflow_json "$repo_dir")"
    return 0
  fi

  dev_kit_output_title "dev.kit explore"
  dev_kit_output_summary "${repo_name} • $(dev_kit_repo_primary_archetype "$repo_dir") • start with repo-native refs"
  dev_kit_output_section "summary"
  dev_kit_output_row "path" "$repo_dir"
  dev_kit_output_row "profile" "$(dev_kit_repo_primary_profile "$repo_dir")"
  dev_kit_output_row "markers" "$(dev_kit_repo_markers_text "$repo_dir")"

  dev_kit_output_section "read first"
  dev_kit_output_list_from_lines <<EOF
$(dev_kit_repo_priority_refs "$repo_dir" | dev_kit_output_first_lines 6)
EOF

  if [ -n "$(dev_kit_repo_source_chain_text "$repo_dir")" ]; then
    dev_kit_output_section "source chain"
    dev_kit_repo_source_chain_text "$repo_dir"
  fi

  dev_kit_output_section "workflow guide"
  dev_kit_repo_workflow_text "$repo_dir"

  dev_kit_output_section "knowledge"
  dev_kit_output_row "local repos" "$(dev_kit_knowledge_local_repos_root)"
  dev_kit_output_row "remote org" "$(dev_kit_knowledge_remote_org_root)"
  dev_kit_output_row "workflow refs" "$(dev_kit_repo_workflow_refs_text "$repo_dir")"
}
