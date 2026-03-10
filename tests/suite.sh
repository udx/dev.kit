#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
. "$REPO_DIR/tests/helpers/assert.sh"

TEST_HOME="${DEV_KIT_TEST_HOME:-$(mktemp -d "${TMPDIR:-/tmp}/dev-kit-test-home.XXXXXX")}"
PROFILE_FILES=("$TEST_HOME/.bash_profile" "$TEST_HOME/.bashrc" "$TEST_HOME/.zshrc")
BASE_PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
INSTALL_OUTPUT=""
FIXTURE_REPO="$REPO_DIR/tests/fixtures/simple-repo"

cleanup() {
  rm -rf "$TEST_HOME"
}

trap cleanup EXIT

mkdir -p "$TEST_HOME"
export HOME="$TEST_HOME"
export PATH="$BASE_PATH"
unset DEV_KIT_HOME
unset DEV_KIT_BIN_DIR

for profile in "${PROFILE_FILES[@]}"; do
  printf "# dev.kit test sentinel\n" > "$profile"
done

INSTALL_OUTPUT="$(bash "$REPO_DIR/bin/scripts/install.sh")"
assert_contains "$INSTALL_OUTPUT" "Installed dev.kit" "installer reports success"
assert_contains "$INSTALL_OUTPUT" "shell:  unchanged" "installer leaves shell init untouched"

DEV_KIT_HOME="$HOME/.udx/dev.kit"
DEV_KIT_BIN_DIR="$HOME/.local/bin"

assert_file_exists "$DEV_KIT_HOME/bin/dev-kit" "installs command source into dev.kit home"
assert_file_exists "$DEV_KIT_HOME/lib/modules/bootstrap.sh" "installs internal modules"
assert_file_exists "$DEV_KIT_HOME/lib/commands/status.sh" "installs public commands"
assert_file_exists "$DEV_KIT_HOME/src/configs/audit-rules.yml" "installs source rule catalog"
assert_file_missing "$DEV_KIT_HOME/source" "does not create legacy source directory"
assert_file_missing "$DEV_KIT_HOME/state" "does not create legacy state directory"
assert_file_missing "$DEV_KIT_HOME/config" "does not install a config layer"
assert_symlink_target "$DEV_KIT_BIN_DIR/dev.kit" "$DEV_KIT_HOME/bin/dev-kit" "creates global dev.kit symlink"

for profile in "${PROFILE_FILES[@]}"; do
  assert_command_output_contains "cat \"$profile\"" "test sentinel" "$(basename "$profile") remains unchanged"
done

if command -v dev.kit >/dev/null 2>&1; then
  fail "command is not exposed before PATH setup"
else
  pass "command is not exposed before PATH setup"
fi

# shellcheck disable=SC1090
. "$DEV_KIT_HOME/bin/env/dev-kit.sh"

assert_contains ":$PATH:" ":$DEV_KIT_BIN_DIR:" "env script prepends the user bin dir"

if command -v dev.kit >/dev/null 2>&1; then
  pass "command resolves after env setup"
else
  fail "command resolves after env setup"
fi

status_output="$(dev.kit status)"
assert_contains "$status_output" "state: installed" "status reports installed state"

status_json="$(dev.kit status --json)"
assert_contains "$status_json" "\"state\": \"installed\"" "status json reports installed state"

audit_output="$(cd "$FIXTURE_REPO" && dev.kit)"
printf '%s\n' "--- dev.kit fixture output ---"
printf '%s\n' "$audit_output"
printf '%s\n' "--- end dev.kit fixture output ---"
assert_contains "$audit_output" "repo: simple-repo" "audit reports the fixture repo name"
assert_contains "$audit_output" "stack: node" "audit detects node repositories"
assert_contains "$audit_output" "readme: missing" "audit reports missing readme"
assert_contains "$audit_output" "test command: missing" "audit reports missing test command"
assert_contains "$audit_output" "Add a README" "audit gives useful readme advice"
assert_contains "$audit_output" "Add a runnable test command" "audit gives useful test advice"

audit_json="$(cd "$FIXTURE_REPO" && dev.kit --json)"
printf '%s\n' "--- dev.kit fixture json ---"
printf '%s\n' "$audit_json"
printf '%s\n' "--- end dev.kit fixture json ---"
assert_contains "$audit_json" "\"command\": \"audit\"" "default json output is audit"
assert_contains "$audit_json" "\"repo\": \"simple-repo\"" "audit json reports repo name"
assert_contains "$audit_json" "\"readme\": \"missing\"" "audit json reports missing readme"
assert_contains "$audit_json" "\"test_command\": \"missing\"" "audit json reports missing test command"
assert_contains "$audit_json" "\"id\": \"missing-readme\"" "audit json includes readme finding"
assert_contains "$audit_json" "\"id\": \"missing-test-command\"" "audit json includes test finding"

bridge_json="$(cd "$FIXTURE_REPO" && dev.kit bridge --json)"
assert_contains "$bridge_json" "\"command\": \"bridge\"" "bridge json is available"
assert_contains "$bridge_json" "\"capabilities\": [\"audit\", \"bridge\", \"status\"]" "bridge exposes discovered capabilities"

help_output="$(dev.kit help)"
assert_contains "$help_output" "audit" "help discovers audit dynamically"
assert_contains "$help_output" "status" "help discovers status dynamically"
assert_contains "$help_output" "bridge" "help discovers bridge dynamically"

if declare -F _dev_kit_complete >/dev/null 2>&1; then
  pass "bash completion function is loaded"
else
  fail "bash completion function is loaded"
fi

COMP_WORDS=(dev.kit "")
COMP_CWORD=1
COMPREPLY=()
_dev_kit_complete
completion_list=" ${COMPREPLY[*]} "
assert_contains "$completion_list" " status " "completion lists status"
assert_contains "$completion_list" " bridge " "completion lists bridge"
assert_contains "$completion_list" " audit " "completion lists audit"
assert_contains "$completion_list" " --json " "completion lists global json flag"

COMP_WORDS=(dev.kit bridge --)
COMP_CWORD=2
COMPREPLY=()
_dev_kit_complete
bridge_completion_list=" ${COMPREPLY[*]} "
assert_contains "$bridge_completion_list" " --json " "bridge completion lists json flag"

UNINSTALL_OUTPUT="$("$DEV_KIT_HOME/bin/scripts/uninstall.sh")"
assert_contains "$UNINSTALL_OUTPUT" "Removed binary:" "uninstall removes the global binary"
assert_contains "$UNINSTALL_OUTPUT" "Removed home:" "uninstall removes the installed home"
assert_file_missing "$DEV_KIT_BIN_DIR/dev.kit" "global symlink is removed"
assert_file_missing "$DEV_KIT_HOME" "installed home is removed"

for profile in "${PROFILE_FILES[@]}"; do
  assert_command_output_contains "cat \"$profile\"" "test sentinel" "$(basename "$profile") remains unchanged after uninstall"
done

printf "ok - dev.kit integration suite completed\n"
