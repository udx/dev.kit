#!/bin/bash

# @description: Deep system analysis and environment hydration advice.
# @intent: doctor, check, health, environment, diagnosis
# @objective: Audit the engineering environment for healthy integrations, secure configurations, and required software, providing proactive advice for empowerment.
# @usage: dev.kit doctor
# @usage: dev.kit doctor --shell-integrate
# @workflow: 1. Core Health -> 2. Software Prerequisites -> 3. External Engineering Context (Mesh) -> 4. AI Skills Health -> 5. Security & Secrets Advisory

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
  local sw_gemini; sw_gemini=$(check_sw "gemini")
  local sw_mmdc; sw_mmdc=$(check_sw "mmdc")

  if [ "$json_output" = "true" ]; then
    local repo_root; repo_root="$(get_repo_root || true)"
    
    # Calculate Mesh Health
    local gh_health="missing"
    if command -v dev_kit_github_health >/dev/null 2>&1; then
      case $(dev_kit_github_health; echo $?) in
        0) gh_health="ok" ;;
        2) gh_health="warn" ;;
      esac
    fi

    local c7_health="missing"
    if command -v dev_kit_context7_health >/dev/null 2>&1; then
      case $(dev_kit_context7_health; echo $?) in
        0) c7_health="ok" ;;
        2) c7_health="warn" ;;
      esac
    fi

    # Calculate Skill Count
    local skill_count=0
    if [ -d "$REPO_DIR/docs/workflows" ]; then
      skill_count=$(find "$REPO_DIR/docs/workflows" -maxdepth 1 -name "*.md" ! -name "README.md" ! -name "normalization.md" ! -name "loops.md" ! -name "mermaid-patterns.md" | wc -l | tr -d ' ')
    fi

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
    "gemini": "$sw_gemini",
    "mmdc": "$sw_mmdc"
  },
  "mesh": {
    "github": "$gh_health",
    "context7": "$c7_health",
    "workflow_skills": $skill_count
  },
  "compliance": {
    "tdd": "$([ -d "$repo_root/tests" ] && echo "ok" || echo "warn")",
    "cac": "$([ -f "$repo_root/environment.yaml" ] && echo "ok" || echo "warn")",
    "docs": "$([ -d "$repo_root/docs" ] && echo "ok" || echo "warn")"
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
  check_software "gemini" "$sw_gemini" "Gemini CLI" "Use dev.kit ai sync to hydrate your agent with repository skills."
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
  echo "Managed AI Skills Health (Repository):"
  local local_skills="$REPO_DIR/docs/workflows"
  if [ -d "$local_skills" ]; then
    local count=0
    # Scan for .md files that define skills (excluding README.md)
    while IFS= read -r skill_file; do
      [ -z "$skill_file" ] && continue
      local filename; filename="$(basename "$skill_file")"
      [ "$filename" = "README.md" ] && continue
      [ "$filename" = "normalization.md" ] && continue
      [ "$filename" = "loops.md" ] && continue
      [ "$filename" = "mermaid-patterns.md" ] && continue

      ((count++))
      local name="${filename%.md}"
      local status="[ok]"
      local detail="documented"
      
      print_check "$name" "$status" "$detail"
    done < <(find "$local_skills" -maxdepth 1 -name "*.md")
    
    if [ $count -eq 0 ]; then
      print_check "skills" "[info]" "No specialized workflows defined in docs/workflows/."
    fi
  else
    print_check "skills" "[info]" "No workflows directory found at $local_skills"
  fi

  echo ""
  echo "Advisory (Security & Secrets):"
  local repo_root
  repo_root="$(get_repo_root || true)"
  
  if command -v mysec >/dev/null 2>&1; then
    print_check "mysec" "[ok]" "Active (Secret Scanning)"
  else
    print_check "mysec" "[info]" "Missing (npm install -g @udx/mysec)"
  fi
  
  if [ -n "$repo_root" ]; then
    if [ -f "$repo_root/.env" ]; then
      if git check-ignore "$repo_root/.env" >/dev/null 2>&1; then
        print_check ".env" "[ok]" "Gitignored (Safe)"
      else
        print_check ".env" "[alert]" "Not Gitignored! (Risk)"
      fi
    fi
  fi
  echo "- [info] Use environment.yaml for non-sensitive orchestration."

  # 6. Repository Audit (Compliance)
  echo ""
  print_section "Repository Compliance (Repo-as-a-Skill)"
  
  if [ -n "$repo_root" ]; then
    # TDD Check
    if [ -d "$repo_root/tests" ] || [ -d "$repo_root/test" ] || [ -d "$repo_root/spec" ]; then
      print_check "TDD" "[ok]" "Test suite detected"
    else
      print_check "TDD" "[warn]" "Missing tests/ or spec/ directory"
    fi

    # Config-as-Code Check
    if [ -f "$repo_root/environment.yaml" ]; then
      print_check "CaC" "[ok]" "environment.yaml active"
    else
      print_check "CaC" "[warn]" "Missing environment.yaml"
    fi

    # Documentation Check
    if [ -d "$repo_root/docs" ]; then
      print_check "Docs" "[ok]" "Knowledge base active"
    else
      print_check "Docs" "[warn]" "Missing docs/ directory"
    fi

    # AI Readiness
    if [ -d "$repo_root/src/ai" ]; then
      print_check "AI Skills" "[ok]" "Repo skills defined"
    else
      print_check "AI Skills" "[warn]" "Missing src/ai/ directory"
    fi
  else
    echo "  - [info] Run inside a git repository for full compliance audit."
  fi
  echo ""
}
