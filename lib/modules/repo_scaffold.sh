#!/usr/bin/env bash

# Scaffold module — all write operations for dev.kit repo.
# Analysis (what's missing) stays in repo_factors.sh and repo_signals.sh.
# This module only handles creating or updating files and dirs.

# Path where the repo manifest is written after learn
dev_kit_scaffold_manifest_path() {
  local repo_root="$1"
  printf '%s/.dev-kit/manifest.json\n' "$repo_root"
}

# Report gaps as JSON array [{factor, status, message}]
# Reads from existing factor analysis — no new detection here
dev_kit_scaffold_gaps_json() {
  local repo_root="$1"
  local factor=""
  local status=""
  local first=1

  printf '[\n'
  for factor in documentation architecture dependencies config verification runtime build_release_run; do
    status="$(dev_kit_repo_factor_status "$repo_root" "$factor")"
    [ "$status" = "missing" ] || [ "$status" = "partial" ] || continue
    local rule_id message
    rule_id="$(dev_kit_repo_factor_rule_id "$factor" "$status" 2>/dev/null || true)"
    message="$([ -n "$rule_id" ] && dev_kit_rule_message "$rule_id" || printf '%s is %s' "$factor" "$status")"
    [ "$first" -eq 0 ] && printf ',\n'
    printf '  { "factor": "%s", "status": "%s", "message": "%s" }' \
      "$factor" \
      "$status" \
      "$(dev_kit_json_escape "$message")"
    first=0
  done
  printf '\n]\n'
}

# Write the repo manifest to <repo>/.dev-kit/manifest.json
# The manifest is the handoff from dev.kit repo → dev.kit agent
dev_kit_scaffold_manifest_write() {
  local repo_root="$1"
  local manifest_path=""

  manifest_path="$(dev_kit_scaffold_manifest_path "$repo_root")"
  mkdir -p "$(dirname "$manifest_path")"

  printf '{\n'
  printf '  "repo": "%s",\n'       "$(dev_kit_json_escape "$(dev_kit_repo_name "$repo_root")")"
  printf '  "path": "%s",\n'       "$(dev_kit_json_escape "$repo_root")"
  local _archetype _archetype_desc
  _archetype="$(dev_kit_repo_primary_archetype "$repo_root")"
  _archetype_desc="$(dev_kit_archetype_description "$_archetype")"
  printf '  "archetype": "%s",\n'             "$(dev_kit_json_escape "$_archetype")"
  [ -n "$_archetype_desc" ] && \
    printf '  "archetype_description": "%s",\n' "$(dev_kit_json_escape "$_archetype_desc")"
  printf '  "profile": "%s",\n'               "$(dev_kit_json_escape "$(dev_kit_repo_primary_profile "$repo_root")")"
  printf '  "priority_refs": %s,\n' "$(dev_kit_repo_priority_refs_json "$repo_root")"
  printf '  "entrypoints": %s,\n'   "$(dev_kit_repo_entrypoints_json "$repo_root")"
  printf '  "workflow_contract": %s,\n' "$(dev_kit_repo_workflow_json "$repo_root")"
  printf '  "factors": %s\n'        "$(dev_kit_repo_factor_summary_json "$repo_root")"
  printf '}\n'
}

# Create missing directories defined for a given archetype in repo-scaffold.yaml
# Currently emits planned actions as lines; writing is gated by --scaffold flag
dev_kit_scaffold_plan_dirs() {
  local repo_root="$1"
  local archetype="$2"
  # Additional dir names can be passed as extra args
  shift 2
  local extra_dirs=("$@")
  local dir=""

  for dir in docs "${extra_dirs[@]}"; do
    [ -d "${repo_root}/${dir}" ] && continue
    printf 'mkdir|%s\n' "$dir"
  done
}

# Create missing files listed in the scaffold plan
# Returns lines: create|<relative_path>
dev_kit_scaffold_plan_files() {
  local repo_root="$1"
  shift
  local files=("$@")
  local file=""

  for file in "${files[@]}"; do
    [ -f "${repo_root}/${file}" ] && continue
    printf 'create|%s\n' "$file"
  done
}

# Apply scaffold plan lines (from plan_dirs / plan_files)
# Each line is: <action>|<relative_path>
# Returns JSON array of {type, path, status}
dev_kit_scaffold_apply() {
  local repo_root="$1"
  local plan="$2"
  local first=1
  local action=""
  local rel_path=""
  local abs_path=""
  local result=""

  printf '[\n'
  while IFS='|' read -r action rel_path; do
    [ -n "$action" ] || continue
    abs_path="${repo_root}/${rel_path}"
    result="ok"

    case "$action" in
      mkdir)
        mkdir -p "$abs_path" 2>/dev/null || result="error"
        ;;
      create)
        mkdir -p "$(dirname "$abs_path")" 2>/dev/null
        # Write an empty stub only — content generation is Phase 3 (agent)
        printf '' > "$abs_path" 2>/dev/null || result="error"
        ;;
    esac

    [ "$first" -eq 0 ] && printf ',\n'
    printf '  { "type": "%s", "path": "%s", "status": "%s" }' \
      "$action" "$(dev_kit_json_escape "$rel_path")" "$result"
    first=0
  done <<EOF
$plan
EOF
  printf '\n]\n'
}
