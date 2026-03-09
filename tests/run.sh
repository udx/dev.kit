#!/usr/bin/env bash

# dev.kit Test Runner
# Facilitates running tests locally or in a high-fidelity udx/worker container.

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_SUITE="${REPO_DIR}/tests/suite.sh"
WORKER_IMAGE="usabilitydynamics/udx-worker:latest"

usage() {
  cat <<EOF
Usage: ./tests/run.sh [options]

Options:
  --worker      Run tests inside a clean udx/worker container (Emulates Ubuntu environment)
  --local       Run tests in the current environment (Default)
  -h, --help    Show this help message

Example:
  ./tests/run.sh --worker
EOF
}

run_local() {
  echo "--- Running Tests Locally ---"
  bash "$TEST_SUITE"
}

run_worker() {
  # 1. Check for @udx/worker-deployment CLI (High-fidelity orchestration)
  if command -v worker >/dev/null 2>&1; then
    echo "--- Running Tests via udx/worker-deployment (worker run) ---"
    # The deploy.yml in the root handles the mounts and environment
    worker run
    return $?
  fi

  # 2. Fallback to raw docker run if CLI is missing
  if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Neither 'worker' (udx/worker-deployment) nor 'docker' were found."
    exit 1
  fi

  echo "--- Running Tests in udx/worker Container (Raw Docker Fallback) ---"
  # We mount the REPO_DIR to /workspace and run the suite
  docker run --rm \
    -v "${REPO_DIR}:/workspace" \
    -w /workspace \
    -e DEV_KIT_SOURCE=/workspace \
    -e TERM=xterm-256color \
    "$WORKER_IMAGE" \
    /bin/bash tests/suite.sh
}

mode="local"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --worker) mode="worker"; shift ;;
    --local)  mode="local"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if [ "$mode" = "worker" ]; then
  run_worker
else
  run_local
fi
