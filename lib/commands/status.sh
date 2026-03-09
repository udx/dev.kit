#!/bin/bash

# @description: Engineering brief and system diagnostic.
# @intent: status, check, health, info, diagnostic
# @objective: Provide a compact, high-signal overview of the current engineering environment, active tasks, and empowerment mesh.
# @usage: dev.kit status
# @usage: dev.kit status --audit
# @usage: dev.kit status --json

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

dev_kit_cmd_status() {
  local json_output="false"
  local deep_audit="false"
  
  for arg in "$@"; do
    case "$arg" in
      --json) json_output="true" ;;
      --audit) deep_audit="true" ;;
    esac
  done

  if [ "$json_output" = "true" ]; then
    dev_kit_health_audit_json
    return
  fi

  ui_header "Engineering Brief"

  # 1. Identity & Operating Mode
  local ai_enabled; ai_enabled="$(config_value_scoped ai.enabled "false")"
  local provider; provider="$(config_value_scoped ai.provider "gemini")"
  
  if [ "$ai_enabled" = "true" ]; then
    ui_ok "Mode" "AI-Powered ($provider)"
  else
    ui_info "Mode" "Personal Helper (Local)"
  fi

  # 2. Workspace & Context
  local repo_root; repo_root="$(get_repo_root || true)"
  if [ -n "$repo_root" ]; then
    ui_ok "Workspace" "$(basename "$repo_root")"
    
    # Active Task Discovery
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

  # 3. Empowerment Mesh (Summary)
  echo ""
  printf "%sEmpowerment Mesh Summary:%s\n" "$(ui_cyan)" "$(ui_reset)"
  if command -v gh >/dev/null 2>&1; then ui_ok "GitHub" "CLI Active"; fi
  if command -v dev_kit_context7_health >/dev/null 2>&1 && dev_kit_context7_health >/dev/null 2>&1; then
    ui_ok "Knowledge" "Context7 Ready"
  fi

  # 4. Deep Audit (Optional)
  if [ "$deep_audit" = "true" ]; then
    echo ""
    ui_header "Engineering Compliance Audit"
    if [ -n "$repo_root" ]; then
      [ -d "$repo_root/tests" ] && ui_ok "TDD" "Test suite detected" || ui_warn "TDD" "No tests found"
      [ -f "$repo_root/environment.yaml" ] && ui_ok "CaC" "environment.yaml active" || ui_warn "CaC" "Missing orchestrator"
      [ -d "$repo_root/docs" ] && ui_ok "Docs" "Knowledge base found" || ui_warn "Docs" "No documentation"
    fi
    echo ""
    echo "Software Detection:"
    for sw in git docker npm gh; do
      if command -v "$sw" >/dev/null 2>&1; then ui_ok "$sw" "$(command -v "$sw")"; else ui_warn "$sw" "Missing"; fi
    done
  fi

  # 5. Actionable Advice
  echo ""
  ui_tip "Run 'dev.kit suggest' for repository improvements."
  ui_tip "Run 'dev.kit status --audit' for a full compliance check."
  echo ""
}
