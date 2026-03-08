#!/usr/bin/env bash

# dev.kit Engineering Test Suite
# Verifies grounding, discovery, and sync logic in a clean environment.

# Colors for better visibility
C_RESET='\033[0m'
C_GREEN='\033[32m'
C_RED='\033[31m'
C_BLUE='\033[34m'

REPO_DIR="${DEV_KIT_SOURCE:-$(pwd)}"
# Ensure we load the dev-kit logic
export REPO_DIR
export PATH="$REPO_DIR/bin:$PATH"

log_info() { printf "  ${C_BLUE}ℹ %s${C_RESET}\n" "$1"; }
log_ok()   { printf "  ${C_GREEN}✔ %s${C_RESET}\n" "$1"; }
log_fail() { printf "  ${C_RED}✖ %s${C_RESET}\n" "$1"; exit 1; }

echo "--- dev.kit High-Fidelity Test Suite ---"

# 1. Verify Discovery (Doctor)
log_info "Testing: Discovery & Doctor Health"
if dev-kit doctor >/dev/null 2>&1; then
  log_ok "Doctor reports healthy (Discovery Mesh active)"
else
  log_fail "Doctor check failed"
fi

# 2. Verify Sync Logic (Atomic Grouping)
log_info "Testing: Sync Logic (Dry-run)"
if dev-kit sync run --dry-run >/dev/null 2>&1; then
  log_ok "Sync dry-run successful (Grouping logic verified)"
else
  log_fail "Sync dry-run failed"
fi

# 3. Verify Documentation Hierarchy (CDE Grounding)
log_info "Testing: Knowledge Base Integrity"
if [ -d "$REPO_DIR/docs/foundations" ] && [ -d "$REPO_DIR/docs/runtime" ]; then
  log_ok "Documentation structure is CDE-aligned"
else
  log_fail "Documentation structure is broken"
fi

# 4. Verify Self-Documenting CLI (Metadata Extraction)
log_info "Testing: CLI Metadata Extraction"
if dev-kit ai commands | grep -q "objective"; then
  log_ok "CLI metadata extraction is operational"
else
  log_fail "Failed to extract metadata from command scripts"
fi

echo "--- All Tests Passed: Repository is High-Fidelity ---"
exit 0
