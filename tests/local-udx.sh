#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEV_KIT_BIN="${DEV_KIT_BIN:-$REPO_DIR/bin/dev-kit}"
LOCAL_ROOT="${DEV_KIT_LOCAL_REPOS_ROOT:-$HOME/git/udx}"
MAX_REPOS="${DEV_KIT_LOCAL_REPOS_MAX:-0}"
ONLY_REPOS="${DEV_KIT_LOCAL_REPOS_ONLY:-}"

print_block() {
  local title="$1"
  local content="$2"

  printf '%s\n' "--- ${title} ---"
  printf '%s\n' "$content"
  printf '%s\n' "--- end ${title} ---"
}

list_repos() {
  local repo_path=""
  local repo_name=""
  local count=0

  [ -d "$LOCAL_ROOT" ] || return 0

  while IFS= read -r repo_path; do
    [ -d "$repo_path/.git" ] || continue
    repo_name="$(basename "$repo_path")"
    if [ -n "$ONLY_REPOS" ]; then
      case ",$ONLY_REPOS," in
        *,"$repo_name",*) ;;
        *) continue ;;
      esac
    fi
    printf '%s\n' "$repo_path"
    count=$((count + 1))
    if [ "$MAX_REPOS" -gt 0 ] && [ "$count" -ge "$MAX_REPOS" ]; then
      break
    fi
  done <<EOF
$(find "$LOCAL_ROOT" -mindepth 1 -maxdepth 1 -type d | sort)
EOF
}

assert_json_contract() {
  local output="$1"
  local expected="$2"
  local message="$3"

  case "$output" in
    *"$expected"*) printf 'ok - %s\n' "$message" ;;
    *)
      print_block "$message" "$output"
      printf 'not ok - %s\n' "$message" >&2
      exit 1
      ;;
  esac
}

run_repo_checks() {
  local repo_path="$1"
  local explore_json=""
  local action_json=""
  local learn_json=""

  printf '\n# %s\n' "$repo_path"

  explore_json="$("$DEV_KIT_BIN" explore --json "$repo_path")"
  assert_json_contract "$explore_json" "\"command\": \"explore\"" "explore command contract"
  assert_json_contract "$explore_json" "\"path\": \"$repo_path\"" "explore path contract"
  assert_json_contract "$explore_json" "\"workflow_contract\": [" "explore workflow contract"

  action_json="$("$DEV_KIT_BIN" action --json "$repo_path")"
  assert_json_contract "$action_json" "\"command\": \"action\"" "action command contract"
  assert_json_contract "$action_json" "\"path\": \"$repo_path\"" "action path contract"
  assert_json_contract "$action_json" "\"behavior\": \"evaluation-only\"" "action behavior contract"

  learn_json="$("$DEV_KIT_BIN" learn --json "$repo_path")"
  assert_json_contract "$learn_json" "\"command\": \"learn\"" "learn command contract"
  assert_json_contract "$learn_json" "\"repo\": \"$repo_path\"" "learn repo contract"
}

main() {
  local repo_path=""
  local matched=0

  if [ ! -x "$DEV_KIT_BIN" ]; then
    printf 'dev.kit binary not found: %s\n' "$DEV_KIT_BIN" >&2
    exit 1
  fi

  if [ ! -d "$LOCAL_ROOT" ]; then
    printf 'local repo root not found: %s\n' "$LOCAL_ROOT" >&2
    exit 1
  fi

  printf 'local root: %s\n' "$LOCAL_ROOT"
  [ "$MAX_REPOS" -gt 0 ] && printf 'max repos: %s\n' "$MAX_REPOS"
  [ -n "$ONLY_REPOS" ] && printf 'only repos: %s\n' "$ONLY_REPOS"

  while IFS= read -r repo_path; do
    [ -n "$repo_path" ] || continue
    matched=1
    run_repo_checks "$repo_path"
  done <<EOF
$(list_repos)
EOF

  if [ "$matched" -eq 0 ]; then
    printf 'no matching repos found under %s\n' "$LOCAL_ROOT" >&2
    exit 1
  fi

  printf '\nok - local udx repo sweep completed\n'
}

main "$@"
