#!/bin/bash

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

dev_kit_cmd_doctor() {
  local json_output="false"
  if [ "${1:-}" = "--json" ]; then
    json_output="true"
    shift
  fi

  ensure_dev_kit_home

  if [ "$json_output" = "false" ]; then
    print_section "dev.kit | doctor"
  fi

  local status_orchestrator="missing"
  if [ -f "${ENVIRONMENT_YAML:-}" ]; then
    status_orchestrator="ok"
  fi

  local env_line="source \"$HOME/.udx/dev.kit/source/env.sh\""
  local profile=""
  case "${SHELL:-}" in
    */zsh) profile="$HOME/.zshrc" ;;
    */bash) profile="$HOME/.bash_profile" ;;
    *) profile="$HOME/.bash_profile" ;;
  esac

  local status_shell="missing"
  if [ -f "$profile" ] && grep -Fqx "$env_line" "$profile"; then
    status_shell="ok"
  fi

  local status_path="missing"
  local path_bin=""
  if command -v dev.kit >/dev/null 2>&1; then
    status_path="ok"
    path_bin="$(command -v dev.kit)"
  fi

  local ai_enabled
  ai_enabled="$(config_value_scoped ai.enabled "false")"
  local operating_mode="Personal Helper"
  if [ "$ai_enabled" = "true" ]; then
    operating_mode="AI-Powered"
  fi

  check_sw() {
    if command -v "$1" >/dev/null 2>&1; then echo "ok"; else echo "missing"; fi
  }

  local sw_git; sw_git=$(check_sw "git")
  local sw_docker; sw_docker=$(check_sw "docker")
  local sw_npm; sw_npm=$(check_sw "npm")
  local sw_gh; sw_gh=$(check_sw "gh")
  local sw_codex; sw_codex=$(check_sw "codex")
  local sw_gemini; sw_gemini=$(check_sw "gemini")
  local sw_mmdc; sw_mmdc=$(check_sw "mmdc")

  if [ "$json_output" = "true" ]; then
    cat <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "orchestrator": "$status_orchestrator",
  "shell_integration": "$status_shell",
  "path": "$status_path",
  "operating_mode": "$operating_mode",
  "software": {
    "git": "$sw_git",
    "docker": "$sw_docker",
    "npm": "$sw_npm",
    "gh": "$sw_gh",
    "codex": "$sw_codex",
    "gemini": "$sw_gemini",
    "mmdc": "$sw_mmdc"
  }
}
EOF
    return
  fi

  # Human-readable output (original logic)
  print_check "orchestrator" "[$status_orchestrator]" "environment.yaml"
  print_check "shell integration" "[$status_shell]" "found in $profile"
  print_check "path" "[$status_path]" "$path_bin"
  print_check "operating mode" "[ok]" "$operating_mode"

  echo ""
  echo "Engineering Software Detection:"
  check_software() {
    local name="$1"
    local status="$2"
    local desc="$3"
    local advice="$4"
    if [ "$status" = "ok" ]; then
      print_check "$name" "[ok]" "$(command -v "$name")"
    else
      print_check "$name" "[missing]" "$desc"
      echo "  - [advice] $advice"
    fi
  }

  check_software "git" "$sw_git" "Version control" "Install git to enable repo-as-skill mapping."
  check_software "docker" "$sw_docker" "Containerization" "Install Docker to run isolated worker environments."
  check_software "npm" "$sw_npm" "Node package manager" "Install npm/node for frontend and tooling support."
  check_software "gh" "$sw_gh" "GitHub CLI" "Install gh for automated repository and PR management."
  check_software "codex" "$sw_codex" "OpenAI CLI" "Install codex to enable automated dev.kit exec."
  check_software "gemini" "$sw_gemini" "Gemini CLI" "Install gemini for native Google AI integration."
  check_software "mmdc" "$sw_mmdc" "Mermaid CLI" "Install with: npm install -g @mermaid-js/mermaid-cli"

  echo ""
  echo "Advisory (Security & Secrets):"
  local repo_root
  repo_root="$(get_repo_root || true)"
  if [ -n "$repo_root" ]; then
    if [ -f "$repo_root/.env" ]; then
      if git check-ignore "$repo_root/.env" >/dev/null 2>&1; then
        echo "- [ok] .env is isolated (gitignored)."
      else
        echo "- [alert] .env is NOT ignored! Add it to .gitignore immediately."
      fi
    fi
  fi
  echo "- [info] Use environment.yaml for non-sensitive orchestration."
  echo ""
}
