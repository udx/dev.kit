#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROMPTFOO_TEMPLATE="$REPO_DIR/tests/promptfoo/dev-kit-agent.yaml"
PROMPTFOO_MOCK_PROVIDER="$REPO_DIR/tests/promptfoo/providers/mock-agent.js"

usage() {
  cat <<'EOF'
Usage:
  bash bin/scripts/promptfoo-dev-kit.sh prepare [options]
  bash bin/scripts/promptfoo-dev-kit.sh eval [options]

Options:
  --repo PATH        Repo to evaluate. Defaults to the current directory.
  --provider ID      Promptfoo provider. Defaults to the local mock provider.
  --task TEXT        Developer task to evaluate.
  --out-dir PATH     Directory for generated config and results.

Environment:
  DEV_KIT_BIN                 Override the dev.kit binary. Defaults to dev.kit.
  DEV_KIT_PROMPTFOO_PROVIDER  Default provider when --provider is omitted.
  DEV_KIT_PROMPTFOO_TASK      Default task when --task is omitted.
  PROMPTFOO_BIN               Override the promptfoo binary. Defaults to promptfoo.
EOF
}

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

yaml_quote() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/''/g")"
}

yaml_block() {
  local value="$1"

  if [ -z "$value" ]; then
    printf '        {}\n'
    return 0
  fi

  printf '%s\n' "$value" | sed 's/^/        /'
}

render_config() {
  local repo_dir="$1"
  local provider="$2"
  local task="$3"
  local explore_json="$4"
  local action_json="$5"
  local output_path="$6"

  awk \
    -v provider="$provider" \
    -v repo_dir="$repo_dir" \
    -v task="$task" \
    -v explore_json="$explore_json" \
    -v action_json="$action_json" \
    '
      /^__PROVIDER__$/ {
        printf "  - %s\n", provider
        next
      }
      /^__REPO_PATH__$/ {
        gsub(/\047/, "\047\047", repo_dir)
        printf "      repo_path: \047%s\047\n", repo_dir
        next
      }
      /^__REPO_TASK__$/ {
        gsub(/\047/, "\047\047", task)
        printf "      repo_task: \047%s\047\n", task
        next
      }
      /^__EXPLORE_JSON__$/ {
        print explore_json
        next
      }
      /^__ACTION_JSON__$/ {
        print action_json
        next
      }
      { print }
    ' "$PROMPTFOO_TEMPLATE" > "$output_path"
}

prepare_eval() {
  local repo_dir="$1"
  local provider="$2"
  local task="$3"
  local out_dir="$4"
  local dev_kit_bin="${DEV_KIT_BIN:-dev.kit}"
  local config_path="$out_dir/promptfooconfig.yaml"
  local explore_json=""
  local action_json=""

  if ! command -v "$dev_kit_bin" >/dev/null 2>&1; then
    if [ -x "$REPO_DIR/bin/dev-kit" ]; then
      dev_kit_bin="$REPO_DIR/bin/dev-kit"
    else
      fail "Missing dev.kit binary. Install dev.kit or set DEV_KIT_BIN."
    fi
  fi

  mkdir -p "$out_dir"

  explore_json="$("$dev_kit_bin" explore --json "$repo_dir")"
  action_json="$("$dev_kit_bin" action --json "$repo_dir")"

  render_config \
    "$repo_dir" \
    "$provider" \
    "$task" \
    "$(yaml_block "$explore_json")" \
    "$(yaml_block "$action_json")" \
    "$config_path"

  printf '%s\n' "$config_path"
}

run_eval() {
  local config_path="$1"
  local out_dir="$2"
  local promptfoo_bin="${PROMPTFOO_BIN:-promptfoo}"
  local promptfoo_home="$out_dir/promptfoo-home"
  local result_path="$out_dir/results.json"

  require_command "$promptfoo_bin"
  mkdir -p "$promptfoo_home"

  HOME="$promptfoo_home" \
  PROMPTFOO_DISABLE_TELEMETRY=1 \
  PROMPTFOO_DISABLE_WAL_MODE=true \
  "$promptfoo_bin" eval \
    -c "$config_path" \
    --no-write \
    --no-share \
    --no-progress-bar \
    --output "$result_path"

  printf '%s\n' "$result_path"
}

main() {
  local command="${1:-eval}"
  local repo_dir="$(pwd)"
  local provider="${DEV_KIT_PROMPTFOO_PROVIDER:-file://$PROMPTFOO_MOCK_PROVIDER}"
  local task="${DEV_KIT_PROMPTFOO_TASK:-I just opened this repo. What should I read first and do next to work safely without engineering drift?}"
  local out_dir=""
  local config_path=""
  local arg=""

  shift || true

  while [ "$#" -gt 0 ]; do
    arg="$1"
    case "$arg" in
      --repo)
        shift
        [ "$#" -gt 0 ] || fail "--repo requires a path"
        repo_dir="$1"
        ;;
      --provider)
        shift
        [ "$#" -gt 0 ] || fail "--provider requires a value"
        provider="$1"
        ;;
      --task)
        shift
        [ "$#" -gt 0 ] || fail "--task requires text"
        task="$1"
        ;;
      --out-dir)
        shift
        [ "$#" -gt 0 ] || fail "--out-dir requires a path"
        out_dir="$1"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        fail "Unknown option: $arg"
        ;;
    esac
    shift
  done

  repo_dir="$(cd "$repo_dir" && pwd)"
  [ -n "$out_dir" ] || out_dir="$(mktemp -d "${TMPDIR:-/tmp}/dev-kit-promptfoo.XXXXXX")"

  case "$command" in
    prepare)
      config_path="$(prepare_eval "$repo_dir" "$provider" "$task" "$out_dir")"
      printf 'Prepared Promptfoo config: %s\n' "$config_path"
      ;;
    eval)
      config_path="$(prepare_eval "$repo_dir" "$provider" "$task" "$out_dir")"
      printf 'Prepared Promptfoo config: %s\n' "$config_path"
      printf 'Promptfoo results: %s\n' "$(run_eval "$config_path" "$out_dir")"
      ;;
    *)
      fail "Unknown command: $command"
      ;;
  esac
}

main "$@"
