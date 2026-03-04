#!/bin/bash

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

dev_kit_cmd_doctor() {
  shift || true
  ensure_dev_kit_home

  print_section "dev.kit | doctor"

  # 1. Orchestrator Integration
  if [ -f "${ENVIRONMENT_YAML:-}" ]; then
    print_check "orchestrator" "[ok]" "environment.yaml found"
  else
    print_check "orchestrator" "[warn]" "environment.yaml missing"
  fi

  # 2. Shell Integration
  local env_line="source \"$HOME/.udx/dev.kit/source/env.sh\""
  local profile=""
  case "${SHELL:-}" in
    */zsh) profile="$HOME/.zshrc" ;;
    */bash) profile="$HOME/.bash_profile" ;;
    *) profile="$HOME/.bash_profile" ;;
  esac

  if [ -f "$profile" ] && grep -Fqx "$env_line" "$profile"; then
    print_check "shell integration" "[ok]" "found in $profile"
  else
    print_check "shell integration" "[warn]" "missing from $profile"
  fi

  # 3. PATH
  if command -v dev.kit >/dev/null 2>&1; then
    print_check "path" "[ok]" "$(command -v dev.kit)"
  else
    print_check "path" "[warn]" "dev.kit not in PATH"
  fi

  # 4. Operating Mode (AI vs Personal Helper)
  local ai_enabled
  ai_enabled="$(config_value_scoped ai.enabled "false")"
  if [ "$ai_enabled" = "true" ]; then
    print_check "operating mode" "[ok]" "AI-Powered (Smart Translator)"
  else
    print_check "operating mode" "[ok]" "Personal Helper (Interface Translator)"
  fi

  # 5. Engineering Software Autodetection & Effectivity Advice
  echo ""
  echo "Engineering Software Detection:"
  
  check_software() {
    local name="$1"
    local desc="$2"
    local advice="$3"
    if command -v "$name" >/dev/null 2>&1; then
      print_check "$name" "[ok]" "$(command -v "$name")"
    else
      print_check "$name" "[missing]" "$desc"
      echo "  - [advice] $advice"
    fi
  }

  check_software "git" "Version control" "Install git to enable repo-as-skill mapping."
  check_software "docker" "Containerization" "Install Docker to run isolated worker environments."
  check_software "npm" "Node package manager" "Install npm/node for frontend and tooling support."
  check_software "gh" "GitHub CLI" "Install gh for automated repository and PR management."
  check_software "codex" "OpenAI CLI" "Install codex to enable automated dev.kit exec."
  check_software "gemini" "Gemini CLI" "Install gemini for native Google AI integration."

  # 6. Sensitive Vars Advisory
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
