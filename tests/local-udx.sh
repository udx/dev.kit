#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEV_KIT_BIN="${DEV_KIT_BIN:-$REPO_DIR/bin/dev-kit}"
LOCAL_ROOT="${DEV_KIT_LOCAL_REPOS_ROOT:-$HOME/git/udx}"
MAX_REPOS="${DEV_KIT_LOCAL_REPOS_MAX:-0}"
ONLY_REPOS="${DEV_KIT_LOCAL_REPOS_ONLY:-}"
COMMANDS="${DEV_KIT_LOCAL_REPOS_COMMANDS:-repo,agent}"
FAIL_ON_WEAK="${DEV_KIT_LOCAL_REPOS_FAIL_ON_WEAK:-0}"

REPO_COUNT=0
TOTAL_CHECKS=0
TOTAL_PASS=0
TOTAL_WARN=0
TOTAL_FAIL=0

usage() {
  cat <<'EOF'
Usage: bash tests/local-udx.sh

Environment:
  DEV_KIT_LOCAL_REPOS_ROOT       Root to scan for repos (default: $HOME/git/udx)
  DEV_KIT_LOCAL_REPOS_MAX        Limit the number of repos checked
  DEV_KIT_LOCAL_REPOS_ONLY       Comma-separated repo names to check
  DEV_KIT_LOCAL_REPOS_COMMANDS   Comma-separated commands: repo,agent[,learn]
                               learn requires CODEX_HOME or agent session source
  DEV_KIT_LOCAL_REPOS_FAIL_ON_WEAK  Exit non-zero when weak findings exist (default: 0)
EOF
}

print_block() {
  local title="$1"
  local content="$2"

  printf '%s\n' "--- ${title} ---"
  printf '%s\n' "$content"
  printf '%s\n' "--- end ${title} ---"
}

has_command() {
  local name="$1"

  case ",$COMMANDS," in
    *,"$name",*) return 0 ;;
  esac

  return 1
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

run_json() {
  local command_name="$1"
  local repo_path="$2"

  "$DEV_KIT_BIN" "$command_name" --json "$repo_path"
}

note_pass() {
  local repo_name="$1"
  local command_name="$2"
  local message="$3"

  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  TOTAL_PASS=$((TOTAL_PASS + 1))
  printf '  ok   [%s] %s\n' "$command_name" "$message"
}

note_warn() {
  local repo_name="$1"
  local command_name="$2"
  local message="$3"

  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  TOTAL_WARN=$((TOTAL_WARN + 1))
  printf '  warn [%s] %s\n' "$command_name" "$message"
}

note_fail() {
  local repo_name="$1"
  local command_name="$2"
  local message="$3"

  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  TOTAL_FAIL=$((TOTAL_FAIL + 1))
  printf '  fail [%s] %s\n' "$command_name" "$message"
}

check_json_field() {
  local repo_name="$1"
  local command_name="$2"
  local json="$3"
  local jq_filter="$4"
  local pass_message="$5"
  local warn_message="$6"
  local severity="${7:-warn}"

  if printf '%s\n' "$json" | jq -e "$jq_filter" >/dev/null 2>&1; then
    note_pass "$repo_name" "$command_name" "$pass_message"
  else
    if [ "$severity" = "fail" ]; then
      note_fail "$repo_name" "$command_name" "$warn_message"
    else
      note_warn "$repo_name" "$command_name" "$warn_message"
    fi
  fi
}

check_json_contract() {
  local repo_name="$1"
  local command_name="$2"
  local repo_path="$3"
  local json="$4"

  check_json_field "$repo_name" "$command_name" "$json" '.command == "'"$command_name"'"' \
    "command contract is stable" \
    "command contract missing or changed" \
    "fail"

  check_json_field "$repo_name" "$command_name" "$json" '.path == "'"$repo_path"'" or .repo == "'"$repo_path"'"' \
    "repo path is reported" \
    "repo path is missing or changed" \
    "fail"

  case "$command_name" in
    repo)
      check_json_field "$repo_name" "$command_name" "$json" '.markers | type == "array" and length > 0' \
        "markers detected" \
        "no repo markers detected"
      check_json_field "$repo_name" "$command_name" "$json" '.archetype | type == "string" and length > 0' \
        "archetype classified" \
        "archetype missing"
      check_json_field "$repo_name" "$command_name" "$json" '.factors | type == "object"' \
        "factors emitted" \
        "factors missing"
      ;;
    agent)
      check_json_field "$repo_name" "$command_name" "$json" '.archetype | type == "string" and length > 0' \
        "archetype classified" \
        "archetype missing"
      check_json_field "$repo_name" "$command_name" "$json" '.workflow_contract | type == "array" and length > 0' \
        "workflow contract emitted" \
        "workflow contract missing"
      check_json_field "$repo_name" "$command_name" "$json" '.priority_refs | type == "array" and length > 0' \
        "priority refs emitted" \
        "priority refs missing"
      check_json_field "$repo_name" "$command_name" "$json" '.entrypoints | type == "object"' \
        "entrypoints emitted" \
        "entrypoints missing"
      ;;
    learn)
      check_json_field "$repo_name" "$command_name" "$json" '.workflow.id | type == "string" and length > 0' \
        "workflow id emitted" \
        "workflow id missing"
      check_json_field "$repo_name" "$command_name" "$json" '.sources | type == "array" and length > 0' \
        "learning sources emitted" \
        "learning sources missing"
      check_json_field "$repo_name" "$command_name" "$json" '.destinations | type == "array" and length > 0' \
        "learning destinations emitted" \
        "learning destinations missing"
      ;;
  esac
}

run_repo_command() {
  local repo_path="$1"
  local repo_name="$2"
  local command_name="$3"
  local output=""
  local command_exit=0

  printf ' [%s]\n' "$command_name"

  set +e
  output="$(run_json "$command_name" "$repo_path" 2>&1)"
  command_exit=$?
  set -e

  if [ "$command_exit" -ne 0 ]; then
    note_fail "$repo_name" "$command_name" "command exited with code $command_exit"
    print_block "$repo_name $command_name output" "$output"
    return
  fi

  if ! printf '%s\n' "$output" | jq -e . >/dev/null 2>&1; then
    note_fail "$repo_name" "$command_name" "output is not valid json"
    print_block "$repo_name $command_name output" "$output"
    return
  fi

  check_json_contract "$repo_name" "$command_name" "$repo_path" "$output"
}

run_repo_checks() {
  local repo_path="$1"
  local repo_name=""
  local start_checks=0
  local start_pass=0
  local start_warn=0
  local start_fail=0
  local repo_checks=0
  local repo_pass=0
  local repo_warn=0
  local repo_fail=0

  repo_name="$(basename "$repo_path")"
  REPO_COUNT=$((REPO_COUNT + 1))

  start_checks=$TOTAL_CHECKS
  start_pass=$TOTAL_PASS
  start_warn=$TOTAL_WARN
  start_fail=$TOTAL_FAIL

  printf '\n# %s\n' "$repo_path"

  if has_command "repo"; then
    run_repo_command "$repo_path" "$repo_name" "repo"
  fi

  if has_command "agent"; then
    run_repo_command "$repo_path" "$repo_name" "agent"
  fi

  if has_command "learn"; then
    run_repo_command "$repo_path" "$repo_name" "learn"
  fi

  repo_checks=$((TOTAL_CHECKS - start_checks))
  repo_pass=$((TOTAL_PASS - start_pass))
  repo_warn=$((TOTAL_WARN - start_warn))
  repo_fail=$((TOTAL_FAIL - start_fail))

  printf ' score: pass=%s warn=%s fail=%s checks=%s\n' \
    "$repo_pass" "$repo_warn" "$repo_fail" "$repo_checks"
}

main() {
  local repo_path=""
  local matched=0

  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi

  if [ ! -x "$DEV_KIT_BIN" ]; then
    printf 'dev.kit binary not found: %s\n' "$DEV_KIT_BIN" >&2
    exit 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    printf 'jq is required for tests/local-udx.sh\n' >&2
    exit 1
  fi

  if [ ! -d "$LOCAL_ROOT" ]; then
    printf 'local repo root not found: %s\n' "$LOCAL_ROOT" >&2
    exit 1
  fi

  printf 'local root: %s\n' "$LOCAL_ROOT"
  [ "$MAX_REPOS" -gt 0 ] && printf 'max repos: %s\n' "$MAX_REPOS"
  [ -n "$ONLY_REPOS" ] && printf 'only repos: %s\n' "$ONLY_REPOS"
  printf 'commands: %s\n' "$COMMANDS"
  [ "$FAIL_ON_WEAK" -eq 1 ] && printf 'fail on weak findings: enabled\n'

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

  printf '\nsummary: repos=%s pass=%s warn=%s fail=%s checks=%s\n' \
    "$REPO_COUNT" "$TOTAL_PASS" "$TOTAL_WARN" "$TOTAL_FAIL" "$TOTAL_CHECKS"

  if [ "$TOTAL_FAIL" -gt 0 ]; then
    exit 1
  fi

  if [ "$FAIL_ON_WEAK" -eq 1 ] && [ "$TOTAL_WARN" -gt 0 ]; then
    exit 1
  fi
}

main "$@"
