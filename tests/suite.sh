#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
. "$REPO_DIR/tests/helpers/assert.sh"

TEST_HOME="${DEV_KIT_TEST_HOME:-$(mktemp -d "${TMPDIR:-/tmp}/dev-kit-test-home.XXXXXX")}"
PROFILE_FILES=("$TEST_HOME/.bash_profile" "$TEST_HOME/.bashrc" "$TEST_HOME/.zshrc")
BASE_PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
INSTALL_OUTPUT=""
SIMPLE_REPO="$REPO_DIR/tests/fixtures/simple-repo"
DOCUMENTED_SHELL_REPO="$REPO_DIR/tests/fixtures/documented-shell-repo"
PHP_REPO="$REPO_DIR/tests/fixtures/php-repo"
DOCKER_REPO="$REPO_DIR/tests/fixtures/docker-repo"

cleanup() {
  rm -rf "$TEST_HOME"
}

trap cleanup EXIT

print_block() {
  local title="$1"
  local content="$2"

  printf '%s\n' "--- ${title} ---"
  printf '%s\n' "$content"
  printf '%s\n' "--- end ${title} ---"
}

fixture_audit_text() {
  local repo_dir="$1"
  (cd "$repo_dir" && dev.kit)
}

fixture_audit_json() {
  local repo_dir="$1"
  (cd "$repo_dir" && dev.kit --json)
}

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
assert_file_exists "$DEV_KIT_HOME/src/configs/audit-rules.yaml" "installs source rule catalog"
assert_file_exists "$DEV_KIT_HOME/src/configs/detection-patterns.yaml" "installs detection pattern catalog"
assert_file_exists "$DEV_KIT_HOME/src/configs/detection-signals.yaml" "installs detection signal catalog"
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

simple_output="$(fixture_audit_text "$SIMPLE_REPO")"
print_block "simple repo audit" "$simple_output"
assert_contains "$simple_output" "profile: node" "simple repo audit detects node profile"
assert_contains "$simple_output" "documentation: missing" "simple repo audit marks documentation missing"
assert_contains "$simple_output" "verification: partial" "simple repo audit marks verification partial"
assert_contains "$simple_output" "evidence: tests" "simple repo audit uses test directory evidence"
assert_contains "$simple_output" "Add a README" "simple repo audit gives documentation advice"
assert_contains "$simple_output" "Verification assets exist" "simple repo audit gives partial verification advice"

simple_json="$(fixture_audit_json "$SIMPLE_REPO")"
print_block "simple repo json" "$simple_json"
assert_contains "$simple_json" "\"command\": \"audit\"" "simple repo json reports audit command"
assert_contains "$simple_json" "\"profile\": \"node\"" "simple repo json reports node profile"
assert_contains "$simple_json" "\"verification\": {" "simple repo json includes verification factor"
assert_contains "$simple_json" "\"status\": \"partial\"" "simple repo json reports partial factor state"
assert_contains "$simple_json" "\"id\": \"partial-verification-entrypoint\"" "simple repo json includes partial verification finding"

documented_shell_output="$(fixture_audit_text "$DOCUMENTED_SHELL_REPO")"
print_block "documented shell repo audit" "$documented_shell_output"
assert_contains "$documented_shell_output" "profile: shell" "documented shell audit detects shell profile"
assert_contains "$documented_shell_output" "documentation: present" "documented shell audit marks documentation present"
assert_contains "$documented_shell_output" "verification: present" "documented shell audit marks verification present"
assert_contains "$documented_shell_output" "entrypoint: bash tests/run.sh" "documented shell audit finds documented verification entrypoint"
assert_contains "$documented_shell_output" "runtime: partial" "documented shell audit marks runtime partial"

php_output="$(fixture_audit_text "$PHP_REPO")"
print_block "php repo audit" "$php_output"
assert_contains "$php_output" "profile: php" "php audit detects php profile"
assert_contains "$php_output" "dependencies: present" "php audit detects dependency manifest"
assert_contains "$php_output" "verification: partial" "php audit marks verification partial"
assert_contains "$php_output" "phpunit.xml" "php audit uses phpunit evidence"

docker_output="$(fixture_audit_text "$DOCKER_REPO")"
print_block "docker repo audit" "$docker_output"
assert_contains "$docker_output" "profile: container" "docker audit detects container profile"
assert_contains "$docker_output" "runtime: present" "docker audit marks runtime present"
assert_contains "$docker_output" "build_release_run: present" "docker audit marks build release run present"
assert_contains "$docker_output" "entrypoint: docker run --rm acme/docker-repo" "docker audit finds documented runtime entrypoint"

bridge_json="$(cd "$DOCUMENTED_SHELL_REPO" && dev.kit bridge --json)"
print_block "documented shell bridge json" "$bridge_json"
assert_contains "$bridge_json" "\"command\": \"bridge\"" "bridge json is available"
assert_contains "$bridge_json" "\"model\": {" "bridge json includes model"
assert_contains "$bridge_json" "\"profiles\": [\"shell\"]" "bridge json exposes discovered profiles"
assert_contains "$bridge_json" "\"guidance\": [" "bridge json includes agent guidance"
assert_contains "$bridge_json" "canonical verification step" "bridge json explains verification workflow"

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
