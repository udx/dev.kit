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
  check_software "gh" "$sw_gh" "GitHub CLI" "Install gh for automated repository and Skill Mesh resolution."
  check_software "codex" "$sw_codex" "OpenAI CLI" "Use dev.kit ai sync to hydrate your agent with repository skills."
  check_software "gemini" "$sw_gemini" "Gemini CLI" "Install gemini for native Google AI integration."
  check_software "mmdc" "$sw_mmdc" "Mermaid CLI" "Install for local SVG rendering: npm install -g @mermaid-js/mermaid-cli"

  echo ""
  echo "External Engineering Context:"
  # GitHub Resolution
  if command -v dev_kit_github_health >/dev/null 2>&1; then
    dev_kit_github_health
    local gh_status=$?
    case $gh_status in
      0) print_check "GitHub Resolution" "[ok]" "authenticated (gh)" ;;
      1) print_check "GitHub Resolution" "[missing]" "CLI missing (gh)" ;;
      2) print_check "GitHub Resolution" "[warn]" "not authenticated" ;;
    esac
  fi

  # Context7 Resolution
  if command -v dev_kit_context7_health >/dev/null 2>&1; then
    dev_kit_context7_health
    local c7_status=$?
    case $c7_status in
      0) print_check "Context7 Resolution" "[ok]" "ready (API/CLI)" ;;
      1) print_check "Context7 Resolution" "[missing]" "API key or CLI missing" ;;
      2) print_check "Context7 Resolution" "[warn]" "CLI available via npm" ;;
    esac
  fi

  # @udx NPM Packages
  if command -v npm >/dev/null 2>&1; then
    local missing_pkgs=()
    for pkg in "@udx/mcurl" "@udx/mysec"; do
      if ! dev_kit_npm_health "$pkg" >/dev/null 2>&1; then
        missing_pkgs+=("$(echo "$pkg" | sed 's/.*[\/]//')")
      fi
    done
    if [ ${#missing_pkgs[@]} -eq 0 ]; then
      print_check "@udx Tools" "[ok]" "all core tools installed"
    else
      print_check "@udx Tools" "[warn]" "missing: ${missing_pkgs[*]}"
      echo "  - [advice] Install for more power: npm install -g @udx/mcurl @udx/mysec"
    fi
  else
    print_check "@udx Tools" "[missing]" "npm runtime required"
  fi

  echo ""
  echo "Managed AI Skills Health:"
  local skills_dir="$HOME/.gemini/skills"
  if [ -d "$skills_dir" ]; then
    local count=0
    while IFS= read -r skill; do
      [ -z "$skill" ] && continue
      count=$((count + 1))
      local name
      name="$(basename "$skill")"
      local status="[ok]"
      local detail="documented"
      [ ! -f "$skill/SKILL.md" ] && { status="[warn]"; detail="missing SKILL.md"; }
      
      # Managed skills no longer require local scripts (moved to core commands)
      print_check "$name" "$status" "$detail"
    done < <(find "$skills_dir" -mindepth 1 -maxdepth 1 -name "dev-kit-*" -type d)
    
    if [ $count -eq 0 ]; then
      print_check "skills" "[warn]" "No managed skills found. Run: dev.kit ai sync"
    fi
  else
    print_check "skills" "[missing]" "Skills directory not found: $skills_dir"
    echo "  - [advice] Run: dev.kit ai sync to initialize AI environment."
  fi

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
