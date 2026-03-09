#!/usr/bin/env bash

# @description: System and repository health auditing.
# @intent: health, doctor, audit, compliance
# @objective: Audit environment health, software prerequisites, and repository compliance.

dev_kit_health_sw_check() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then echo "ok"; else echo "missing"; fi
}

dev_kit_health_audit_json() {
  local repo_root; repo_root="$(get_repo_root || true)"
  local ai_enabled; ai_enabled="$(config_value_scoped ai.enabled "false")"
  
  local gh_health="missing"
  if command -v dev_kit_github_health >/dev/null 2>&1; then
    case $(dev_kit_github_health; echo $?) in 0) gh_health="ok" ;; 2) gh_health="warn" ;; esac
  fi

  local skill_count=0
  [ -d "$REPO_DIR/docs/workflows" ] && skill_count=$(find "$REPO_DIR/docs/workflows" -maxdepth 1 -name "*.md" ! -name "README.md" ! -name "normalization.md" ! -name "loops.md" ! -name "mermaid-patterns.md" | wc -l | tr -d ' ')

  cat <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "operating_mode": "$([ "$ai_enabled" = "true" ] && echo "AI-Powered" || echo "Personal Helper")",
  "software": {
    "git": "$(dev_kit_health_sw_check git)",
    "docker": "$(dev_kit_health_sw_check docker)",
    "npm": "$(dev_kit_health_sw_check npm)",
    "gh": "$(dev_kit_health_sw_check gh)"
  },
  "mesh": {
    "github": "$gh_health",
    "workflow_skills": $skill_count
  },
  "compliance": {
    "tdd": "$([ -d "$repo_root/tests" ] && echo "ok" || echo "warn")",
    "cac": "$([ -f "$repo_root/environment.yaml" ] && echo "ok" || echo "warn")",
    "docs": "$([ -d "$repo_root/docs" ] && echo "ok" || echo "warn")"
  }
}
EOF
}
