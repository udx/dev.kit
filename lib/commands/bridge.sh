#!/usr/bin/env bash

# @description: Show the agent-facing 12-factor repo model

dev_kit_cmd_bridge() {
  local format="${1:-text}"
  local repo_dir="${2:-$(pwd)}"
  local factors_json=""
  local guidance_json=""

  if [ "$format" = "json" ]; then
    factors_json="$(dev_kit_repo_factor_summary_json "$repo_dir")"
    guidance_json="$(dev_kit_repo_agent_guidance_json "$repo_dir")"
    dev_kit_template_render "bridge.json.tmpl" \
      "command=bridge" \
      "repo=$(dev_kit_json_escape "$repo_dir")" \
      "archetype=$(dev_kit_json_escape "$(dev_kit_repo_primary_archetype "$repo_dir")")" \
      "archetypes=$(dev_kit_repo_archetypes_json "$repo_dir")" \
      "profile=$(dev_kit_json_escape "$(dev_kit_repo_primary_profile "$repo_dir")")" \
      "profiles=$(dev_kit_repo_profiles_json "$repo_dir")" \
      "factors=$factors_json" \
      "guidance=$guidance_json"
    return 0
  fi

  echo "dev.kit bridge"
  echo "repo: $repo_dir"
  echo "archetype: $(dev_kit_repo_primary_archetype "$repo_dir")"
  echo "archetypes: $(dev_kit_repo_archetypes_text "$repo_dir")"
  echo "profile: $(dev_kit_repo_primary_profile "$repo_dir")"
  echo "profiles: $(dev_kit_repo_profiles_text "$repo_dir")"
  echo "agent guidance:"
  while IFS= read -r guidance; do
    [ -n "$guidance" ] || continue
    printf '  - %s\n' "$guidance"
  done <<EOF
$(dev_kit_repo_agent_guidance_text "$repo_dir")
EOF
}
