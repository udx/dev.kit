#!/bin/bash

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

dev_kit_cmd_status() {
  local json_output="false"
  if [ "${1:-}" = "--json" ]; then
    json_output="true"
    shift
  fi

  if [ "$json_output" = "true" ]; then
    dev_kit_cmd_doctor --json
    return
  fi

  print_section "dev.kit | Engineering Brief"

  # 1. Identity & Version
  local version="0.1.0"
  if [ -f "$REPO_DIR/VERSION" ]; then
    version="$(cat "$REPO_DIR/VERSION")"
  fi
  printf "Instance:  udx/dev.kit v%s\n" "$version"
  
  # 2. Operating Mode
  local ai_enabled
  ai_enabled="$(config_value_scoped ai.enabled "false")"
  local mode="Personal Helper (Local Automation)"
  if [ "$ai_enabled" = "true" ]; then
    local provider
    provider="$(config_value_scoped ai.provider "codex")"
    mode="AI-Powered (Smart Translator via $provider)"
  fi
  print_check "Mode" "[ok]" "$mode"

  # 3. Environment Health (Brief)
  local orchestrator="missing"
  if [ -f "$ENVIRONMENT_YAML" ]; then
    orchestrator="ok ($ENVIRONMENT_YAML)"
  fi
  print_check "Orchestrator" "[ok]" "$orchestrator"

  local env_line="source \"$HOME/.udx/dev.kit/source/env.sh\""
  local profile=""
  case "${SHELL:-}" in
    */zsh) profile="$HOME/.zshrc" ;;
    */bash) profile="$HOME/.bash_profile" ;;
    *) profile="$HOME/.bash_profile" ;;
  esac
  local shell_status="missing"
  if [ -f "$profile" ] && grep -Fqx "$env_line" "$profile"; then
    shell_status="ok (integrated in $profile)"
  fi
  print_check "Shell" "[ok]" "$shell_status"

  # 4. Active Context
  local repo_root
  repo_root="$(get_repo_root || true)"
  if [ -n "$repo_root" ]; then
    print_check "Workspace" "[ok]" "$repo_root"
    local task_id="none"
    # Try to find active workflow/task
    if [ -d "$repo_root/tasks" ]; then
       # (Simplified: just check if tasks exist)
       task_id="available in $repo_root/tasks/"
    fi
    print_check "Active Task" "[ok]" "$task_id"
  else
    print_check "Workspace" "[warn]" "not in a git repository"
  fi

  # 5. Advisory & Next Steps
  echo ""
  echo "Engineering Advisory:"
  if [ "$shell_status" = "missing" ]; then
    echo "- [action] Run: dev.kit doctor --shell-integrate"
  fi
  if [ "$ai_enabled" = "false" ]; then
    echo "- [info] AI features are disabled. Use 'dev.kit config set --key ai.enabled true' to enable."
  fi
  echo "- [tip] Use 'dev.kit help' to list all commands."
  echo "- [tip] Run 'dev.kit doctor' for deep system analysis."
  echo ""
}
