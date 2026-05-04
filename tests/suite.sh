#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
. "$REPO_DIR/tests/helpers/assert.sh"

TEST_HOME="${DEV_KIT_TEST_HOME:-$(mktemp -d "${TMPDIR:-/tmp}/dev-kit-test-home.XXXXXX")}"
BASE_PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
SIMPLE_REPO="$REPO_DIR/tests/fixtures/simple-repo"
DOCUMENTED_SHELL_REPO="$REPO_DIR/tests/fixtures/documented-shell-repo"
DOCKER_REPO="$REPO_DIR/tests/fixtures/docker-repo"
SIMPLE_ACTION_REPO="$TEST_HOME/simple-action-repo"
HOME_ACTION_REPO="$TEST_HOME/home-action-repo"
DOCKER_ACTION_REPO="$TEST_HOME/docker-action-repo"
AVAILABLE_TEST_GROUPS="core"
TEST_ONLY="${DEV_KIT_TEST_ONLY:-}"

cleanup() {
  rm -rf "$TEST_HOME"
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: bash tests/suite.sh [--only core] [--list]

Groups:
  core        minimal happy-path smoke checks
EOF
}

list_groups() {
  local group=""
  for group in $AVAILABLE_TEST_GROUPS; do
    printf '%s\n' "$group"
  done
}

should_run() {
  local group="$1"
  if [ -z "$TEST_ONLY" ]; then
    return 0
  fi
  case ",$TEST_ONLY," in
    *,"$group",*) return 0 ;;
  esac
  return 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --only)
      shift
      [ "$#" -gt 0 ] || fail "--only requires a comma-separated list"
      TEST_ONLY="$1"
      ;;
    --list) list_groups; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unknown option: $1" ;;
  esac
  shift
done

mkdir -p "$TEST_HOME"
export HOME="$TEST_HOME"
export PATH="$BASE_PATH"
unset DEV_KIT_HOME
unset DEV_KIT_BIN_DIR

DEV_KIT_HOME="$REPO_DIR"
DEV_KIT_BIN_DIR="$TEST_HOME/.local/bin"
mkdir -p "$DEV_KIT_BIN_DIR"
ln -sf "$REPO_DIR/bin/dev-kit" "$DEV_KIT_BIN_DIR/dev.kit"
export PATH="$DEV_KIT_BIN_DIR:$PATH"

# shellcheck disable=SC1090
. "$DEV_KIT_HOME/bin/env/dev-kit.sh"
while IFS= read -r module_file; do
  [ -n "$module_file" ] || continue
  [ "$module_file" = "$REPO_DIR/lib/modules/bootstrap.sh" ] && continue
  # shellcheck disable=SC1090
  . "$module_file"
done <<EOF
$(dev_kit_module_paths)
EOF

if should_run "core"; then
  cp -R "$DOCUMENTED_SHELL_REPO" "$HOME_ACTION_REPO"
  rm -rf "$HOME_ACTION_REPO/.dev-kit" "$HOME_ACTION_REPO/.rabbit" "$HOME_ACTION_REPO/AGENTS.md"

  home_json="$(cd "$HOME_ACTION_REPO" && dev.kit --json)"
  assert_contains "$home_json" "\"repo_detected\": true" "home: detects repo"
  assert_contains "$home_json" "\"synced\": {" "home: reports synced artifacts"
  assert_contains "$home_json" "\"helpers\": [" "home: reports helpers"

  home_text="$(cd "$HOME_ACTION_REPO" && dev.kit)"
  assert_contains "$home_text" "[required]" "home text: renders env tools"
  assert_contains "$home_text" "[synced]" "home text: syncs repo artifacts"
  assert_file_exists "$HOME_ACTION_REPO/.rabbit/context.yaml" "home: writes context.yaml"
  assert_file_exists "$HOME_ACTION_REPO/AGENTS.md" "home: writes AGENTS.md"
  assert_not_contains "$(dev_kit_github_repo_refs_in_file "$REPO_DIR/src/configs/detection-signals.yaml")" "org/repo" "home: ignores placeholder github refs"

  env_json="$(cd "$HOME_ACTION_REPO" && dev.kit env --json)"
  assert_contains "$env_json" "\"command\": \"env\"" "env: reports command name"

  repo_json="$(cd "$DOCUMENTED_SHELL_REPO" && dev.kit repo --json)"
  assert_contains "$repo_json" "\"archetype\":" "repo: reports archetype"
  assert_contains "$repo_json" "\"context\":" "repo: reports context path"

  cp -R "$SIMPLE_REPO" "$SIMPLE_ACTION_REPO"
  rm -rf "$SIMPLE_ACTION_REPO/.dev-kit" "$SIMPLE_ACTION_REPO/.rabbit"

  agent_json="$(cd "$SIMPLE_ACTION_REPO" && dev.kit agent --json)"
  assert_contains "$agent_json" "\"workflow_contract\":" "agent: reports workflow contract"

  context_yaml="${SIMPLE_ACTION_REPO}/.rabbit/context.yaml"
  assert_file_exists "$context_yaml" "agent: creates .rabbit/context.yaml"
  assert_contains "$(cat "$context_yaml")" "kind: repoContext" "agent: context.yaml has kind header"
  assert_not_contains "$(cat "$context_yaml")" "/Users/" "agent: context.yaml has no absolute paths"
  assert_contains "$(cat "${SIMPLE_ACTION_REPO}/AGENTS.md")" "Use these repo-derived steps as the default operating path." "agent: AGENTS.md uses repo-derived workflow guidance"

  cp -R "$DOCKER_REPO" "$DOCKER_ACTION_REPO"
  rm -rf "$DOCKER_ACTION_REPO/.rabbit" "$DOCKER_ACTION_REPO/AGENTS.md"

  docker_repo_json="$(cd "$DOCKER_ACTION_REPO" && dev.kit repo --json)"
  assert_contains "$docker_repo_json" "\"context\":" "docker repo: reports context path"

  docker_context_yaml="${DOCKER_ACTION_REPO}/.rabbit/context.yaml"
  assert_contains "$(cat "$docker_context_yaml")" "path: deploy.yml" "docker repo: includes deploy manifest"
  assert_contains "$(cat "$docker_context_yaml")" "source_repo: udx/worker" "docker repo: traces manifest owner from version"
fi

printf "ok - dev.kit suite completed\n"
