#!/usr/bin/env bash
# dev.kit CLI Test Suite

set -euo pipefail

# --- Environment ---
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$TEST_DIR/.." && pwd)"
DEV_KIT_BIN="$REPO_DIR/bin/dev-kit"

# Mock context
export DEV_KIT_HOME="$TEST_DIR/.tmp/home"
export DEV_KIT_STATE="$TEST_DIR/.tmp/state"
export DEV_KIT_CONFIG="$DEV_KIT_STATE/config.env"
export DEV_KIT_SOURCE="$REPO_DIR"

mkdir -p "$DEV_KIT_HOME" "$DEV_KIT_STATE"

# --- Arguments ---
FULL_INSTALL="false"
for arg in "$@"; do
  if [ "$arg" = "--full" ]; then
    FULL_INSTALL="true"
  fi
done

# --- Functions ---

run_test() {
  local id="$1"
  local label="$2"
  local cmd="$3"
  printf "Test %-2d: %-40s " "$id" "$label"
  if eval "$cmd" >"$TEST_DIR/.tmp/test.log" 2>&1; then
    echo "[ok]"
  else
    echo "[fail]"
    echo "--- ERROR LOG ---"
    cat "$TEST_DIR/.tmp/test.log"
    echo "-----------------"
    exit 1
  fi
}

# --- Core Tests ---

echo "Running dev.kit CLI Test Suite..."
echo "Repo Root: $REPO_DIR"

run_test 1 "Help command" "\"$DEV_KIT_BIN\" help"
run_test 2 "Status command (Default)" "\"$DEV_KIT_BIN\""
run_test 3 "AI Skills listing" "\"$DEV_KIT_BIN\" ai skills | grep 'dev-kit-diagram-generator'"
run_test 4 "AI Workflows listing" "\"$DEV_KIT_BIN\" ai workflows | grep 'Feature Engineering Loop'"
run_test 5 "Config set value" "\"$DEV_KIT_BIN\" config set --key test_key test_val"
run_test 6 "Config show value" "\"$DEV_KIT_BIN\" config show | grep 'test_key = test_val'"
run_test 7 "Doctor verification" "\"$DEV_KIT_BIN\" doctor"
run_test 8 "Task start (Auto-ID)" "\"$DEV_KIT_BIN\" task start 'test request' | grep 'Task initialized'"

# --- Implicit Execution Test ---
# We mock codex command to avoid actual AI call during test if possible,
# but since we want to test routing, we just check if it attempts to call the function.
# For now, we test that it doesn't fail with 'Unknown command' when passed a string.
run_test 9 "Implicit Intent routing" "\"$DEV_KIT_BIN\" 'How are you?' 2>&1 | grep -v 'Unknown command'"

# --- Full Installation Test ---

if [ "$FULL_INSTALL" = "true" ]; then
  echo "Testing full installation path..."
  
  ORIG_HOME="$HOME"
  export HOME="$TEST_DIR/.tmp"
  mkdir -p "$HOME/.local/bin"
  
  # Mock user answering 'n' to zsh/bash prompts to avoid side effects
  bash "$REPO_DIR/bin/scripts/install.sh" <<EOF
n
n
EOF
  
  MOCKED_TARGET="$HOME/.local/bin/dev.kit"
  if [ -L "$MOCKED_TARGET" ]; then
    echo "  [ok] Symlink created at $MOCKED_TARGET"
  else
    echo "  [fail] Symlink missing at $MOCKED_TARGET"
    export HOME="$ORIG_HOME"
    exit 1
  fi
  
  export HOME="$ORIG_HOME"
fi

echo "All tests passed!"

# Clean up
if [ "${DEBUG:-}" != "1" ]; then
  rm -rf "$TEST_DIR/.tmp"
fi
