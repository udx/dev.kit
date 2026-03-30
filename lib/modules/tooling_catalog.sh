#!/usr/bin/env bash

DEV_KIT_TOOLING_CONFIG_FILE="src/configs/tooling-refs.yaml"

dev_kit_tooling_config_path() {
  printf "%s" "$REPO_DIR/$DEV_KIT_TOOLING_CONFIG_FILE"
}

dev_kit_tooling_standard_reading_order() {
  dev_kit_yaml_mapping_list "$(dev_kit_tooling_config_path)" "refs" "standard_reading_order"
}

dev_kit_tooling_dependency_orgs() {
  dev_kit_yaml_mapping_list "$(dev_kit_tooling_config_path)" "refs" "dependency_orgs"
}

dev_kit_tooling_repo_lines() {
  local file_path=""

  file_path="$(dev_kit_tooling_config_path)"
  awk '
    $1 == "config:" { in_config = 1; next }
    in_config && $0 ~ /^  refs:/ { in_refs = 1; next }
    in_refs && $0 ~ /^    tooling_repos:/ { in_repos = 1; next }
    in_repos && $0 ~ /^      - repo:/ {
      sub(/^[[:space:]]*-[[:space:]]*repo:[[:space:]]*/, "", $0)
      repo = $0
      role = ""
      next
    }
    in_repos && $0 ~ /^        role:/ {
      sub(/^[[:space:]]*role:[[:space:]]*/, "", $0)
      role = $0
      printf "%s|%s\n", repo, role
    }
  ' "$file_path"
}

dev_kit_tooling_repos_text() {
  local line=""
  local repo=""
  local role=""

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    repo="${line%%|*}"
    role="${line#*|}"
    printf '  - %s: %s\n' "$repo" "$role"
  done <<EOF
$(dev_kit_tooling_repo_lines)
EOF
}

dev_kit_tooling_repos_json() {
  local line=""
  local repo=""
  local role=""
  local first=1

  printf "["
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    repo="${line%%|*}"
    role="${line#*|}"
    if [ "$first" -eq 0 ]; then
      printf ", "
    fi
    printf '{ "repo": "%s", "role": "%s" }' \
      "$(dev_kit_json_escape "$repo")" \
      "$(dev_kit_json_escape "$role")"
    first=0
  done <<EOF
$(dev_kit_tooling_repo_lines)
EOF
  printf "]"
}

dev_kit_repo_workflow_ref_lines() {
  local repo_dir="$1"
  local workflow_file=""
  local workflow_ref=""

  [ -d "$repo_dir/.github/workflows" ] || return 0

  while IFS= read -r workflow_file; do
    [ -n "$workflow_file" ] || continue
    while IFS= read -r workflow_ref; do
      [ -n "$workflow_ref" ] || continue
      printf '%s\n' "$workflow_ref"
    done <<EOF
$(sed -n 's/^[[:space:]]*uses:[[:space:]]*\(udx\/[^[:space:]]*\).*/\1/p' "$workflow_file")
EOF
  done <<EOF
$(find "$repo_dir/.github/workflows" -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)
EOF
}

dev_kit_repo_workflow_refs_text() {
  local repo_dir="$1"
  local refs=""

  refs="$(dev_kit_repo_workflow_ref_lines "$repo_dir" | awk '!seen[$0]++')"
  if [ -z "$refs" ]; then
    printf "%s" "none"
    return 0
  fi

  printf "%s" "$refs" | dev_kit_lines_to_csv
}

dev_kit_repo_workflow_refs_json() {
  local repo_dir="$1"
  local refs=""

  refs="$(dev_kit_repo_workflow_ref_lines "$repo_dir" | awk '!seen[$0]++')"
  if [ -z "$refs" ]; then
    printf "%s" "[]"
    return 0
  fi

  printf "%s" "$refs" | dev_kit_lines_to_json_array
}
