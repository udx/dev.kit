#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

DEV_KIT_BIN="${DEV_KIT_BIN:-${REPO_DIR}/bin/dev-kit}"
OUTPUT_DIR="${DEV_KIT_UX_OUTPUT_DIR:-${REPO_DIR}/tmp/ux}"
LOG_FILE="${DEV_KIT_UX_LOG_FILE:-${OUTPUT_DIR}/dev-kit-install-cleanup.log}"
SHELL_KIND="${DEV_KIT_UX_SHELL:-bash}"
DO_PURGE="${DEV_KIT_UX_PURGE:-false}"
DRY_RUN="${DEV_KIT_UX_DRY_RUN:-false}"

mkdir -p "$OUTPUT_DIR"

export DEV_KIT_TEST_OUTPUT_DIR="$OUTPUT_DIR"
export DEV_KIT_TEST_LOG_FILE="$LOG_FILE"
export DEV_KIT_TEST_SHELL="$SHELL_KIND"
export DEV_KIT_TEST_PURGE="$DO_PURGE"

run_args=("--run" "--force")
if [ "$DRY_RUN" = "true" ]; then
  run_args=("--mock")
fi

"$DEV_KIT_BIN" test install "${run_args[@]}"
