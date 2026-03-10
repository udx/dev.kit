#!/usr/bin/env bash

# @description: Audit the current repository for basic fidelity gaps

dev_kit_cmd_audit() {
  local format="${1:-text}"
  local repo_dir="${2:-$(pwd)}"
  local repo_name=""
  local stack=""
  local readme_status=""
  local test_status=""

  repo_name="$(dev_kit_repo_name "$repo_dir")"
  stack="$(dev_kit_repo_detect_stack "$repo_dir")"
  readme_status="$(dev_kit_repo_readme_status "$repo_dir")"
  test_status="$(dev_kit_repo_test_status "$repo_dir")"

  if [ "$format" = "json" ]; then
    printf '{\n'
    printf '  "command": "audit",\n'
    printf '  "repo": "%s",\n' "$repo_name"
    printf '  "path": "%s",\n' "$repo_dir"
    printf '  "stack": "%s",\n' "$stack"
    printf '  "checks": {\n'
    printf '    "readme": "%s",\n' "$readme_status"
    printf '    "test_command": "%s"\n' "$test_status"
    printf '  },\n'
    printf '  "improvement_plan": '
    dev_kit_repo_findings_json "$repo_dir"
    printf '\n}\n'
    return 0
  fi

  echo "dev.kit audit"
  echo "repo: $repo_name"
  echo "path: $repo_dir"
  echo "stack: $stack"
  echo "readme: $readme_status"
  echo "test command: $test_status"
  dev_kit_repo_advices "$repo_dir"
}
