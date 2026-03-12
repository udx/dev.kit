#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_CONFIG="$REPO_DIR/deploy.yml"

worker_cmd() {
  if command -v worker >/dev/null 2>&1; then
    command -v worker
    return 0
  fi

  return 1
}

usage() {
  cat <<'EOF'
Usage: bash tests/run.sh

Options:
  --help    Show this help
EOF
}

run_worker() {
  local cmd=""

  cmd="$(worker_cmd)" || {
    echo "worker CLI not found. Install @udx/worker-deployment globally." >&2
    exit 1
  }

  "$cmd" run --config="$DEPLOY_CONFIG"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

run_worker
