#!/bin/bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cli="$root_dir/bin/dev-kit"

fail() {
  echo "[fail] $1" >&2
  exit 1
}

out="$($cli config -h)"
[[ "$out" == *"global"* ]] || fail "config help missing 'global'"
[[ "$out" == *"repo"* ]] || fail "config help missing 'repo'"

$cli codex --help >/dev/null 2>&1 || true

echo "[ok] cli smoke tests"
