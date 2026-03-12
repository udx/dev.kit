#!/usr/bin/env bash

# @description: Audit the current repository against 12-factor workflow boundaries

dev_kit_cmd_audit() {
  local format="${1:-text}"
  local repo_dir="${2:-$(pwd)}"
  local repo_name=""
  local primary_profile=""
  local profiles=""
  local primary_archetype=""
  local archetypes=""
  local factors_json=""
  local improvement_plan_json=""

  repo_name="$(dev_kit_repo_name "$repo_dir")"
  primary_profile="$(dev_kit_repo_primary_profile "$repo_dir")"
  profiles="$(dev_kit_repo_profiles_text "$repo_dir")"
  primary_archetype="$(dev_kit_repo_primary_archetype "$repo_dir")"
  archetypes="$(dev_kit_repo_archetypes_text "$repo_dir")"

  if [ "$format" = "json" ]; then
    factors_json="$(dev_kit_repo_factor_summary_json "$repo_dir")"
    improvement_plan_json="$(dev_kit_repo_findings_json "$repo_dir")"
    dev_kit_template_render "audit.json.tmpl" \
      "command=audit" \
      "repo=$(dev_kit_json_escape "$repo_name")" \
      "path=$(dev_kit_json_escape "$repo_dir")" \
      "archetype=$(dev_kit_json_escape "$primary_archetype")" \
      "archetypes=$(dev_kit_repo_archetypes_json "$repo_dir")" \
      "profile=$(dev_kit_json_escape "$primary_profile")" \
      "profiles=$(dev_kit_repo_profiles_json "$repo_dir")" \
      "factors=$factors_json" \
      "improvement_plan=$improvement_plan_json"
    return 0
  fi

  echo "dev.kit"
  echo "repo: $repo_name"
  echo "path: $repo_dir"
  echo "archetype: $primary_archetype"
  echo "archetypes: $archetypes"
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
