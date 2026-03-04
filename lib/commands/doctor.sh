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
    if command -v codex >/dev/null 2>&1; then
      print_check "codex cli" "[ok]" "$(command -v codex)"
    else
      print_check "codex cli" "[warn]" "missing (required for automated dev.kit exec)"
    fi
  else
    print_check "operating mode" "[ok]" "Personal Helper (Interface Translator)"
    echo "  - [info] dev.kit exec will print prompts for manual use."
    echo "  - [info] Enable AI-Powered mode for MCP fetching and Context7 integration."
  fi

  # 5. Mapping Check
  if [ -f "${ENVIRONMENT_YAML:-}" ]; then
    local skills_mapping
    skills_mapping="$(dev_kit_yaml_value "$ENVIRONMENT_YAML" "ai.mapping.skills" "")"
    if [ -n "$skills_mapping" ]; then
      print_check "ai mapping" "[ok]" "skills -> $skills_mapping"
    fi
  fi

  # 6. Sensitive Vars Advisory
  echo ""
  echo "Advisory (Security & Secrets):"
  local repo_root
  repo_root="$(get_repo_root || true)"
  if [ -n "$repo_root" ]; then
    if [ -f "$repo_root/.env" ]; then
      echo "- [notice] Found .env file in repo root."
      if git check-ignore "$repo_root/.env" >/dev/null 2>&1; then
        echo "  - [ok] .env is ignored by git."
      else
        echo "  - [alert] .env is NOT ignored by git! Add it to .gitignore."
      fi
    fi
    if [ -f "$repo_root/.udx/dev.kit/config.env" ]; then
      echo "- [notice] Found repo-scoped dev.kit config."
      if git check-ignore "$repo_root/.udx/dev.kit/config.env" >/dev/null 2>&1; then
        echo "  - [ok] Repo config is ignored by git."
      else
        echo "  - [notice] Repo config is tracked by git. Use for non-sensitive overrides only."
      fi
    fi
  fi
  echo "- [info] Keep secrets in ~/.udx/dev.kit/state/config.env or use an external vault."

  # 5. Env Vars Helper
  echo ""
  echo "Environment Variables:"
  printf "  %-20s %s\n" "DEV_KIT_HOME" "${DEV_KIT_HOME:-}"
  printf "  %-20s %s\n" "DEV_KIT_STATE" "${DEV_KIT_STATE:-}"
  printf "  %-20s %s\n" "DEV_KIT_SOURCE" "${DEV_KIT_SOURCE:-}"
  printf "  %-20s %s\n" "DEV_KIT_CONFIG" "${CONFIG_FILE:-}"

  echo ""
}
