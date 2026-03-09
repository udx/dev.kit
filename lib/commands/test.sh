#!/usr/bin/env bash

# @description: Run the repository's test suite to verify health and grounding.
# @intent: test, check, verify, suite, worker
# @objective: Validate the integrity of the dev.kit engine, its grounding in the repository, and ensure environment parity via worker containers.
# @usage: dev.kit test [--worker]

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

dev_kit_cmd_test() {
  local runner="${REPO_DIR}/tests/run.sh"
  
  if [ ! -f "$runner" ]; then
    echo "Error: Test runner not found at $runner" >&2
    return 1
  fi

  # Pass all arguments directly to the runner script
  bash "$runner" "$@"
}
