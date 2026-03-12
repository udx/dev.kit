#!/usr/bin/env bash

# @description: Audit the current repository against 12-factor workflow boundaries

dev_kit_cmd_audit() {
  local format="${1:-text}"
  local repo_dir="${2:-$(pwd)}"
  local repo_name=""
  local primary_profile=""
  local profiles=""

  repo_name="$(dev_kit_repo_name "$repo_dir")"
  primary_profile="$(dev_kit_repo_primary_profile "$repo_dir")"
  profiles="$(dev_kit_repo_profiles_text "$repo_dir")"

  if [ "$format" = "json" ]; then
    printf '{\n'
    printf '  "command": "audit",\n'
    printf '  "repo": "%s",\n' "$repo_name"
    printf '  "path": "%s",\n' "$repo_dir"
    printf '  "profile": "%s",\n' "$primary_profile"
    printf '  "profiles": '
    dev_kit_repo_profiles_json "$repo_dir"
    printf ',\n'
    printf '  "factors": '
    dev_kit_repo_factor_summary_json "$repo_dir"
    printf ',\n'
    printf '  "improvement_plan": '
    dev_kit_repo_findings_json "$repo_dir"
    printf '\n}\n'
    return 0
  fi

  echo "dev.kit"
  echo "repo: $repo_name"
  echo "path: $repo_dir"
  echo "profile: $primary_profile"
  echo "profiles: $profiles"
  echo "factors:"
  while IFS= read -r factor; do
    printf '  - %s: %s\n' "$factor" "$(dev_kit_repo_factor_status "$repo_dir" "$factor")"
    printf '    evidence: %s\n' "$(dev_kit_repo_factor_evidence_text "$repo_dir" "$factor")"
    if dev_kit_repo_factor_entrypoint "$repo_dir" "$factor" >/dev/null 2>&1; then
      printf '    entrypoint: %s\n' "$(dev_kit_repo_factor_entrypoint "$repo_dir" "$factor")"
    fi
  done <<EOF
$(dev_kit_repo_factor_ids)
EOF
  dev_kit_repo_advices "$repo_dir"
}
