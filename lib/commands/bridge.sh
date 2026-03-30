#!/usr/bin/env bash

# @description: Show the agent-facing repo workflow model

dev_kit_cmd_bridge() {
  local format="${1:-text}"
  local repo_dir="${2:-$(pwd)}"
  local factors_json=""
  local facets_json=""
  local guidance_json=""
  local saved_context_json=""
  local priority_refs_json=""

  if [ "$format" = "json" ]; then
    facets_json="$(dev_kit_repo_facets_json "$repo_dir")"
    factors_json="$(dev_kit_repo_factor_summary_json "$repo_dir")"
    guidance_json="$(dev_kit_repo_agent_guidance_json "$repo_dir")"
    saved_context_json="$(dev_kit_repo_saved_context_json "$repo_dir")"
    priority_refs_json="$(dev_kit_repo_priority_refs_json "$repo_dir")"
    dev_kit_template_render "bridge.json" \
      "command=bridge" \
      "repo=$(dev_kit_json_escape "$repo_dir")" \
      "archetype=$(dev_kit_json_escape "$(dev_kit_repo_primary_archetype "$repo_dir")")" \
      "archetypes=$(dev_kit_repo_archetypes_json "$repo_dir")" \
      "facets=$facets_json" \
      "profile=$(dev_kit_json_escape "$(dev_kit_repo_primary_profile "$repo_dir")")" \
      "profiles=$(dev_kit_repo_profiles_json "$repo_dir")" \
      "factors=$factors_json" \
      "guidance=$guidance_json" \
      "saved_context=$saved_context_json" \
      "priority_refs=$priority_refs_json" \
      "knowledge_base=$(dev_kit_knowledge_hierarchy_json)" \
      "knowledge_sources=$(dev_kit_knowledge_preferred_sources | dev_kit_lines_to_json_array)" \
      "operating_surface=$(dev_kit_knowledge_operating_surface_json)" \
      "responsibility_split=$(dev_kit_knowledge_responsibility_split_json)"
    return 0
  fi

  echo "dev.kit bridge"
  echo "repo: $repo_dir"
  echo "archetype: $(dev_kit_repo_primary_archetype "$repo_dir")"
  echo "archetypes: $(dev_kit_repo_archetypes_text "$repo_dir")"
  echo "facets: $(dev_kit_repo_facets_text "$repo_dir")"
  echo "profile: $(dev_kit_repo_primary_profile "$repo_dir")"
  echo "profiles: $(dev_kit_repo_profiles_text "$repo_dir")"
  if dev_kit_repo_has_saved_context "$repo_dir"; then
    echo "saved context: $(dev_kit_repo_saved_context_summary_text "$repo_dir")"
  else
    echo "saved context: none"
  fi
  echo "knowledgebase: $(dev_kit_knowledge_local_repos_root) -> $(dev_kit_knowledge_remote_org_root)"
  echo "software: tools=$(dev_kit_knowledge_operating_tools_text); formats=$(dev_kit_knowledge_operating_formats_text)"
  echo "knowledge sources: $(dev_kit_knowledge_preferred_sources_text)"
  echo "agent guidance:"
  while IFS= read -r guidance; do
    [ -n "$guidance" ] || continue
    printf '  - %s\n' "$guidance"
  done <<EOF
$(dev_kit_repo_agent_guidance_text "$repo_dir")
EOF
}
