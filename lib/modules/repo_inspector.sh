#!/usr/bin/env bash

dev_kit_repo_name() {
  basename "${1:-$(pwd)}"
}

dev_kit_has_file() {
  local repo_dir="$1"
  local path="$2"
  [ -e "$repo_dir/$path" ]
}

dev_kit_detect_node_repo() {
  local repo_dir="$1"
  dev_kit_has_file "$repo_dir" "package.json"
}

dev_kit_repo_test_status() {
  local repo_dir="$1"

  if dev_kit_detect_node_repo "$repo_dir"; then
    if awk '
      /"scripts"[[:space:]]*:[[:space:]]*{/ { in_scripts=1 }
      in_scripts && /"test"[[:space:]]*:/ { found=1 }
      in_scripts && /}/ { if (!found) exit }
      END { exit found ? 0 : 1 }
    ' "$repo_dir/package.json"; then
      printf "%s" "present"
      return 0
    fi
  fi

  printf "%s" "missing"
}

dev_kit_repo_readme_status() {
  local repo_dir="$1"

  if dev_kit_has_file "$repo_dir" "README.md" || dev_kit_has_file "$repo_dir" "README"; then
    printf "%s" "present"
    return 0
  fi

  printf "%s" "missing"
}

dev_kit_repo_detect_stack() {
  local repo_dir="$1"

  if dev_kit_detect_node_repo "$repo_dir"; then
    printf "%s" "node"
    return 0
  fi

  printf "%s" "unknown"
}

dev_kit_repo_findings_json() {
  local repo_dir="$1"
  local readme_status=""
  local test_status=""
  local emitted=0
  local readme_message=""
  local test_message=""

  readme_status="$(dev_kit_repo_readme_status "$repo_dir")"
  test_status="$(dev_kit_repo_test_status "$repo_dir")"
  readme_message="$(dev_kit_rule_message "missing-readme")"
  test_message="$(dev_kit_rule_message "missing-test-command")"

  printf "["

  if [ "$readme_status" = "missing" ]; then
    printf '\n    { "id": "missing-readme", "message": "%s" }' "$readme_message"
    emitted=1
  fi

  if [ "$test_status" = "missing" ]; then
    if [ "$emitted" -eq 1 ]; then
      printf ","
    fi
    printf '\n    { "id": "missing-test-command", "message": "%s" }' "$test_message"
    emitted=1
  fi

  if [ "$emitted" -eq 1 ]; then
    printf '\n  '
  fi

  printf "]"
}

dev_kit_repo_advices() {
  local repo_dir="$1"
  local readme_status=""
  local test_status=""

  readme_status="$(dev_kit_repo_readme_status "$repo_dir")"
  test_status="$(dev_kit_repo_test_status "$repo_dir")"

  if [ "$readme_status" = "missing" ]; then
    printf 'advice: %s\n' "$(dev_kit_rule_message "missing-readme")"
  fi

  if [ "$test_status" = "missing" ]; then
    printf 'advice: %s\n' "$(dev_kit_rule_message "missing-test-command")"
  fi
}
