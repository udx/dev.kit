#!/bin/bash

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

dev_kit_cmd_audit() {
  shift || true
  ensure_dev_kit_home

  print_section "dev.kit | audit (Repo-as-a-Skill Compliance)"

  local repo_root
  repo_root="$(get_repo_root || true)"
  if [ -z "$repo_root" ]; then
    echo "Error: Must be inside a git repository to audit." >&2
    exit 1
  fi

  # 1. TDD Check
  echo "TDD (Test Driven Development):"
  if [ -d "$repo_root/tests" ] || [ -d "$repo_root/test" ] || [ -d "$repo_root/spec" ]; then
    print_check "test suite" "[ok]" "found tests/ or spec/ directory"
  else
    print_check "test suite" "[warn]" "no tests/ found. TDD compliance requires explicit tests."
  fi

  # 2. 12-Factor / CaC Check
  echo ""
  echo "12-Factor & Config-as-Code (CaC):"
  if [ -f "$repo_root/environment.yaml" ]; then
    print_check "orchestrator" "[ok]" "found environment.yaml"
  else
    print_check "orchestrator" "[warn]" "missing environment.yaml. Required for CaC."
  fi

  if [ -f "$repo_root/.env" ]; then
    if git check-ignore "$repo_root/.env" >/dev/null 2>&1; then
      print_check "secrets isolation" "[ok]" ".env is gitignored"
    else
      print_check "secrets isolation" "[alert]" ".env is NOT gitignored! 12-factor violation."
    fi
  fi

  # 3. Active Context Layer Check
  echo ""
  echo "Active Context Layer (Human/Script/LLM):"
  if [ -d "$repo_root/docs" ]; then
    print_check "documentation" "[ok]" "found docs/ directory"
    if [ -f "$repo_root/docs/README.md" ] || [ -f "$repo_root/docs/index.md" ]; then
       print_check "context entrypoint" "[ok]" "found docs entrypoint"
    else
       print_check "context entrypoint" "[warn]" "docs/ exists but lacks a central entrypoint (index.md/README.md)"
    fi
  else
    print_check "documentation" "[warn]" "missing docs/. Required for high-fidelity context."
  fi

  if [ -d "$repo_root/tasks" ]; then
    print_check "task history" "[ok]" "found tasks/ directory (active context)"
  else
    print_check "task history" "[info]" "no tasks/ directory. Start tasks with 'dev.kit task new <id>'."
  fi

  # 4. AI Interface / Skill Mapping
  echo ""
  echo "AI Mapping & MCP:"
  if [ -d "$repo_root/src/ai" ]; then
    print_check "ai interface" "[ok]" "found src/ai/ (repo skills defined)"
  else
    print_check "ai interface" "[warn]" "no src/ai/ directory. Repo is not yet a self-describing skill."
  fi

  if [ -f "$repo_root/environment.yaml" ]; then
     local mcp_check
     mcp_check="$(dev_kit_yaml_value "$repo_root/environment.yaml" "ai.mcp_servers" "")"
     if [ -n "$mcp_check" ]; then
        print_check "mcp servers" "[ok]" "mcp_servers defined in environment.yaml"
     else
        print_check "mcp servers" "[info]" "no mcp_servers in environment.yaml. AI agents may lack tool access."
     fi
  fi

  echo ""
  echo "Audit complete. Use the above feedback to improve 'Repo-as-a-Skill' compliance."
}
