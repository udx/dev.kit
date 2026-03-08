#!/bin/bash

# @description: Engineering brief and system diagnostic.
# @intent: status, check, health, info, diagnostic
# @objective: Provide a compact, high-signal overview of the current engineering environment, active tasks, and empowerment mesh.
# @usage: dev.kit status
# @usage: dev.kit status --json
# @workflow: 1. Identity & Operating Mode -> 2. Environment Health -> 3. Active Context -> 4. Empowerment Mesh -> 5. Actionable Advice

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

  ui_header "Engineering Brief"

  # 1. Identity
  local version="0.1.0"
  [ -f "$REPO_DIR/VERSION" ] && version="$(cat "$REPO_DIR/VERSION")"
  
  # 2. Operating Mode & Environment
  local ai_enabled; ai_enabled="$(config_value_scoped ai.enabled "false")"
  local provider; provider="$(config_value_scoped ai.provider "codex")"
  
  if [ "$ai_enabled" = "true" ]; then
    ui_ok "Mode" "AI-Powered ($provider)"
  else
    ui_info "Mode" "Personal Helper (Local)"
  fi

  local env_line="source \"$HOME/.udx/dev.kit/source/env.sh\""
  local profile=""; case "${SHELL:-}" in */zsh) profile="$HOME/.zshrc" ;; *) profile="$HOME/.bash_profile" ;; esac
  if [ -f "$profile" ] && grep -Fqx "$env_line" "$profile"; then
    ui_ok "Shell" "Integrated ($profile)"
  else
    ui_warn "Shell" "Missing integration"
  fi

  # 3. Workspace & Context
  local repo_root; repo_root="$(get_repo_root || true)"
  if [ -n "$repo_root" ]; then
    ui_ok "Workspace" "$(basename "$repo_root")"
    
    # Active Task
    local active_workflow=""
    if [ -d "$repo_root/tasks" ]; then
      active_workflow="$(find "$repo_root/tasks" -name "workflow.md" -exec grep -l "status: planned\|status: active" {} + | head -n 1 || true)"
      if [ -n "$active_workflow" ]; then
        local task_id; task_id="$(basename "$(dirname "$active_workflow")")"
        echo ""
        printf "%sWaterfall Progression: [%s]%s\n" "$(ui_cyan)" "$task_id" "$(ui_reset)"
        grep -A 2 "^### Step" "$active_workflow" | awk '
          /^### Step/ { step = $0; sub(/^### /, "", step); printf "  %-20s", step; }
          /^status:/ {
            status = $2;
            if (status == "completed" || status == "done") printf " \033[32m✔\033[0m\n";
            else if (status == "active" || status == "running") printf " \033[36m›\033[0m\n";
            else printf " \033[2m…\033[0m\n";
          }
        '
      fi
    fi
  else
    ui_warn "Workspace" "Not in a repository"
  fi

  # 4. Virtual Skills (Discovery)
  echo ""
  printf "%sVirtual Skills (Environment Discovery):%s\n" "$(ui_cyan)" "$(ui_reset)"
  if command -v gh >/dev/null 2>&1; then ui_ok "GitHub" "CLI (Discovery Active)"; else ui_info "GitHub" "Missing"; fi
  if command -v npm >/dev/null 2>&1; then ui_ok "NPM" "Node Runtime"; else ui_info "NPM" "Missing"; fi
  if command -v docker >/dev/null 2>&1; then ui_ok "Docker" "Engine Detected"; else ui_info "Docker" "Missing"; fi
  if command -v gcloud >/dev/null 2>&1; then ui_ok "Google" "Cloud CLI"; fi

  # 5. Empowerment Mesh
  echo ""
  printf "%sEmpowerment Mesh:%s\n" "$(ui_cyan)" "$(ui_reset)"
  if command -v dev_kit_github_health >/dev/null 2>&1 && dev_kit_github_health >/dev/null 2>&1; then
    ui_ok "Remote" "GitHub Authorized"
  fi
  
  if command -v dev_kit_context7_health >/dev/null 2>&1 && dev_kit_context7_health >/dev/null 2>&1; then
    ui_ok "Knowledge" "Context7 API (v2)"
  fi

  # 6. Actionable Tips
  echo ""
  ui_tip "Run 'dev.kit skills run \"<intent>\"' to resolve drift."
  ui_tip "Run 'dev.kit sync' to atomically commit changes."
  echo ""
}
