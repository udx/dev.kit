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
      "saved_context=$(dev_kit_repo_saved_context_json "$repo_dir")" \
      "priority_refs=$(dev_kit_repo_priority_refs_json "$repo_dir")" \
      "knowledge_base=$(dev_kit_knowledge_hierarchy_json)" \
      "knowledge_sources=$(dev_kit_knowledge_preferred_sources | dev_kit_lines_to_json_array)" \
      "operating_surface=$(dev_kit_knowledge_operating_surface_json)" \
      "responsibility_split=$(dev_kit_knowledge_responsibility_split_json)" \
      "typical_workflows=$(dev_kit_knowledge_typical_workflows_json)"
    return 0
  fi

  echo "dev.kit explore"
  echo "repo: $repo_name"
  echo "path: $repo_dir"
  echo "what it is: $(dev_kit_repo_primary_archetype "$repo_dir")"
  echo "archetypes: $(dev_kit_repo_archetypes_text "$repo_dir")"
  echo "facets: $(dev_kit_repo_facets_text "$repo_dir")"
  echo "profile: $(dev_kit_repo_primary_profile "$repo_dir")"
  echo "profiles: $(dev_kit_repo_profiles_text "$repo_dir")"
  echo
  echo "software:"
  echo "  - tools: $(dev_kit_knowledge_operating_tools_text)"
  echo "  - formats: $(dev_kit_knowledge_operating_formats_text)"
  echo
  echo "knowledgebase:"
  echo "  - local repos: $(dev_kit_knowledge_local_repos_root)"
  echo "  - remote org: $(dev_kit_knowledge_remote_org_root)"
  if dev_kit_repo_has_saved_context "$repo_dir"; then
    echo "  - saved context: $(dev_kit_repo_saved_context_summary_text "$repo_dir")"
  else
    echo "  - saved context: none"
  fi
  echo "  - preferred sources: $(dev_kit_knowledge_preferred_sources_text)"
  echo
  echo "typical workflows:"
  while IFS= read -r workflow; do
    [ -n "$workflow" ] || continue
    printf '  - %s\n' "$workflow"
  done <<EOF
$(dev_kit_knowledge_typical_workflows)
EOF
  echo
  echo "responsibility split:"
  echo "  - repo mechanisms: $(dev_kit_knowledge_repo_mechanisms | dev_kit_lines_to_csv)"
  echo "  - agent tasks: $(dev_kit_knowledge_agent_tasks | dev_kit_lines_to_csv)"
  echo
  echo "priority refs:"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    printf '  - %s\n' "$path"
  done <<EOF
$(dev_kit_repo_priority_refs "$repo_dir")
EOF
}
