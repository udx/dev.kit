#!/usr/bin/env bash

# @description: Show the agent-facing 12-factor repo model

dev_kit_cmd_bridge() {
  local format="${1:-text}"
  local repo_dir="${2:-$(pwd)}"

  if [ "$format" = "json" ]; then
    printf '{\n'
    printf '  "command": "bridge",\n'
    printf '  "repo": "%s",\n' "$repo_dir"
    printf '  "model": {\n'
    printf '    "profile": "%s",\n' "$(dev_kit_repo_primary_profile "$repo_dir")"
    printf '    "profiles": '
    dev_kit_repo_profiles_json "$repo_dir"
    printf ',\n'
    printf '    "factors": '
    dev_kit_repo_factor_summary_json "$repo_dir"
    printf ',\n'
    printf '    "guidance": '
    dev_kit_repo_agent_guidance_json "$repo_dir"
    printf '\n  }\n'
    printf '}\n'
    return 0
  fi

  echo "dev.kit bridge"
  echo "repo: $repo_dir"
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
