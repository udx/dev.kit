#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DEV_KIT_TEST_MODE=smoke bash "$REPO_DIR/tests/suite.sh" "$@"
