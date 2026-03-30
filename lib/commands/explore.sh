#!/usr/bin/env bash

# @description: Explore repo identity, workflows, and knowledge sources

dev_kit_cmd_explore() {
  local format="${1:-text}"
  local repo_dir="${2:-$(pwd)}"
  local repo_name=""
  local factors_json=""

  repo_name="$(dev_kit_repo_name "$repo_dir")"

  if [ "$format" = "json" ]; then
    factors_json="$(dev_kit_repo_factor_summary_json "$repo_dir")"
    dev_kit_template_render "explore.json" \
      "command=explore" \
      "repo=$(dev_kit_json_escape "$repo_name")" \
      "path=$(dev_kit_json_escape "$repo_dir")" \
      "archetype=$(dev_kit_json_escape "$(dev_kit_repo_primary_archetype "$repo_dir")")" \
      "archetypes=$(dev_kit_repo_archetypes_json "$repo_dir")" \
      "facets=$(dev_kit_repo_facets_json "$repo_dir")" \
      "profile=$(dev_kit_json_escape "$(dev_kit_repo_primary_profile "$repo_dir")")" \
      "profiles=$(dev_kit_repo_profiles_json "$repo_dir")" \
      "factors=$factors_json" \
      "priority_refs=$(dev_kit_repo_priority_refs_json "$repo_dir")" \
      "knowledge_base=$(dev_kit_knowledge_hierarchy_json)" \
      "knowledge_sources=$(dev_kit_knowledge_preferred_sources | dev_kit_lines_to_json_array)" \
      "tooling_refs=$(dev_kit_tooling_repos_json)" \
      "operating_surface=$(dev_kit_knowledge_operating_surface_json)" \
      "responsibility_split=$(dev_kit_knowledge_responsibility_split_json)" \
      "workflow_contract=$(dev_kit_repo_workflow_json "$repo_dir")" \
      "typical_workflows=$(dev_kit_knowledge_typical_workflows_json)"
    return 0
  fi

  dev_kit_output_title "dev.kit explore"
  dev_kit_output_section "repo"
  dev_kit_output_row "repo" "$repo_name"
  dev_kit_output_row "path" "$repo_dir"
  dev_kit_output_row "what it is" "$(dev_kit_repo_primary_archetype "$repo_dir")"
  dev_kit_output_row "archetypes" "$(dev_kit_repo_archetypes_text "$repo_dir")"
  dev_kit_output_row "facets" "$(dev_kit_repo_facets_text "$repo_dir")"
  dev_kit_output_row "profile" "$(dev_kit_repo_primary_profile "$repo_dir")"
  dev_kit_output_row "profiles" "$(dev_kit_repo_profiles_text "$repo_dir")"

  dev_kit_output_section "software"
  dev_kit_output_row "tools" "$(dev_kit_knowledge_operating_tools_text)"
  dev_kit_output_row "formats" "$(dev_kit_knowledge_operating_formats_text)"

  dev_kit_output_section "knowledgebase"
  dev_kit_output_row "local repos" "$(dev_kit_knowledge_local_repos_root)"
  dev_kit_output_row "remote org" "$(dev_kit_knowledge_remote_org_root)"
  dev_kit_output_row "preferred sources" "$(dev_kit_knowledge_preferred_sources_text)"
  dev_kit_output_row "standard reading" "$(dev_kit_tooling_standard_reading_order | dev_kit_lines_to_csv)"

  dev_kit_output_section "typical workflows"
  dev_kit_output_list_from_lines <<EOF
$(dev_kit_knowledge_typical_workflows)
EOF
  dev_kit_output_section "tooling repos"
  dev_kit_tooling_repos_text
  dev_kit_output_section "workflow contract"
  dev_kit_repo_workflow_text "$repo_dir"
  dev_kit_output_section "responsibility split"
  dev_kit_output_row "repo mechanisms" "$(dev_kit_knowledge_repo_mechanisms | dev_kit_lines_to_csv)"
  dev_kit_output_row "agent tasks" "$(dev_kit_knowledge_agent_tasks | dev_kit_lines_to_csv)"
  dev_kit_output_section "priority refs"
  dev_kit_output_list_from_lines <<EOF
$(dev_kit_repo_priority_refs "$repo_dir")
EOF
}
