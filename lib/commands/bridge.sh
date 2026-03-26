#!/usr/bin/env bash

# @description: Show the agent-facing 12-factor repo model

dev_kit_cmd_bridge() {
  local format="${1:-text}"
  local repo_dir="${2:-$(pwd)}"
  local factors_json=""
  local facets_json=""
  local guidance_json=""
  local saved_context_json=""

  if [ "$format" = "json" ]; then
    facets_json="$(dev_kit_repo_facets_json "$repo_dir")"
    factors_json="$(dev_kit_repo_factor_summary_json "$repo_dir")"
    guidance_json="$(dev_kit_repo_agent_guidance_json "$repo_dir")"
    saved_context_json="$(dev_kit_repo_saved_context_json "$repo_dir")"
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
      "saved_context=$saved_context_json"
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
  echo "agent guidance:"
  while IFS= read -r guidance; do
    [ -n "$guidance" ] || continue
    printf '  - %s\n' "$guidance"
  done <<EOF
$(dev_kit_repo_agent_guidance_text "$repo_dir")
EOF
}
