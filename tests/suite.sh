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
WORDPRESS_REPO="$REPO_DIR/tests/fixtures/wordpress-repo"
SIMPLE_ACTION_REPO="$TEST_HOME/simple-action-repo"
AVAILABLE_TEST_GROUPS="core archetypes install"
TEST_ONLY="${DEV_KIT_TEST_ONLY:-}"

cleanup() {
  rm -rf "$TEST_HOME"
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: bash tests/suite.sh [--only group1,group2] [--list]

Groups:
  core        home + repo + agent (fast, no install required)
  archetypes  fixture archetype detection
  install     full install + uninstall flow (slow, CI)
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

# ── Setup ──────────────────────────────────────────────────────────────────────
# Point directly at the repo — no tar, no install needed for core/archetypes.

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

# ── core ───────────────────────────────────────────────────────────────────────

if should_run "core"; then
  home_json="$(cd "$DOCUMENTED_SHELL_REPO" && dev.kit --json)"
  assert_contains "$home_json" "\"repo_detected\": true"   "home: detects repo"
  assert_contains "$home_json" "\"priority_refs\": ["      "home: reports priority refs"
  assert_contains "$home_json" "\"next_git_action\":"      "home: reports next git action"
  assert_contains "$home_json" "\"helpers\": ["            "home: reports helpers"

  home_text="$(cd "$DOCUMENTED_SHELL_REPO" && dev.kit)"
  assert_contains "$home_text" "[read first]"              "home text: renders read-first"
  assert_contains "$home_text" "[do next]"                 "home text: renders do-next"

  norepo="$(cd "$TEST_HOME" && dev.kit)"
  assert_contains "$norepo" "No repository detected"       "home: handles non-repo dir"

  repo_json="$(cd "$DOCUMENTED_SHELL_REPO" && dev.kit repo --json)"
  assert_contains "$repo_json" "\"archetype\":"            "repo: reports archetype"
  assert_contains "$repo_json" "\"factors\": {"           "repo: reports factors"
  assert_contains "$repo_json" "\"manifest\":"             "repo: reports manifest path"

  cp -R "$SIMPLE_REPO" "$SIMPLE_ACTION_REPO"
  rm -rf "$SIMPLE_ACTION_REPO/.dev-kit"
  agent_no_manifest="$(cd "$SIMPLE_ACTION_REPO" && dev.kit agent --json 2>&1 || true)"
  assert_contains "$agent_no_manifest" "\"error\":"        "agent: reports error without manifest"

  (cd "$SIMPLE_ACTION_REPO" && dev.kit repo) >/dev/null 2>&1
  agent_json="$(cd "$SIMPLE_ACTION_REPO" && dev.kit agent --json)"
  assert_contains "$agent_json" "\"archetype\":"           "agent: reports archetype"
  assert_contains "$agent_json" "\"workflow_contract\":"   "agent: reports workflow contract"
fi

# ── archetypes ─────────────────────────────────────────────────────────────────

if should_run "archetypes"; then
  wordpress_json="$(cd "$WORDPRESS_REPO" && dev.kit repo --json)"
  assert_contains "$wordpress_json" "\"archetype\": \"wordpress-site\""  "archetype: wordpress fixture"

  docker_json="$(cd "$DOCKER_REPO" && dev.kit repo --json)"
  assert_contains "$docker_json" "\"archetype\": \"runtime-image\""      "archetype: docker fixture"
fi

# ── install ────────────────────────────────────────────────────────────────────
# Full tar+install+uninstall — slow, run in CI or with --only install.

if should_run "install" && [ -n "${CI:-}" ]; then
  INSTALLER_COPY="$TEST_HOME/install.sh"
  ARCHIVE_FILE="$TEST_HOME/dev-kit-main.tar.gz"
  cp "$REPO_DIR/bin/scripts/install.sh" "$INSTALLER_COPY"
  tar -czf "$ARCHIVE_FILE" --exclude=".git" --exclude="node_modules" --exclude="vendor" \
    -C "$(dirname "$REPO_DIR")" "$(basename "$REPO_DIR")"

  unset DEV_KIT_HOME DEV_KIT_BIN_DIR
  INSTALL_OUTPUT="$(DEV_KIT_INSTALL_ARCHIVE_URL="file://$ARCHIVE_FILE" HOME="$TEST_HOME" bash "$INSTALLER_COPY")"
  DEV_KIT_HOME="$TEST_HOME/.udx/dev.kit"
  DEV_KIT_BIN_DIR="$TEST_HOME/.local/bin"

  assert_contains "$INSTALL_OUTPUT" "Installed dev.kit"           "install: reports success"
  assert_file_exists "$DEV_KIT_HOME/bin/dev-kit"                  "install: command binary present"
  assert_file_exists "$DEV_KIT_HOME/lib/commands/repo.sh"         "install: repo command present"
  assert_symlink_target "$DEV_KIT_BIN_DIR/dev.kit" "$DEV_KIT_HOME/bin/dev-kit" "install: global symlink correct"

  UNINSTALL_OUTPUT="$(HOME="$TEST_HOME" "$DEV_KIT_HOME/bin/dev-kit" uninstall --yes)"
  assert_contains "$UNINSTALL_OUTPUT" "Removed dev.kit"           "uninstall: reports removal"
  assert_file_missing "$DEV_KIT_BIN_DIR/dev.kit"                  "uninstall: removes symlink"
  assert_file_missing "$DEV_KIT_HOME"                             "uninstall: removes home"
elif should_run "install"; then
  pass "install group skipped outside CI (run with CI=1 to enable)"
fi

printf "ok - dev.kit suite completed\n"
