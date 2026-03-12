#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
. "$REPO_DIR/tests/helpers/assert.sh"

TEST_HOME="${DEV_KIT_TEST_HOME:-$(mktemp -d "${TMPDIR:-/tmp}/dev-kit-test-home.XXXXXX")}"
PROFILE_FILES=("$TEST_HOME/.bash_profile" "$TEST_HOME/.bashrc" "$TEST_HOME/.zshrc")
BASE_PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
INSTALL_OUTPUT=""
INSTALLER_COPY=""
ARCHIVE_FILE=""
SIMPLE_REPO="$REPO_DIR/tests/fixtures/simple-repo"
DOCUMENTED_SHELL_REPO="$REPO_DIR/tests/fixtures/documented-shell-repo"
PHP_REPO="$REPO_DIR/tests/fixtures/php-repo"
DOCKER_REPO="$REPO_DIR/tests/fixtures/docker-repo"
WORKFLOW_REPO="$REPO_DIR/tests/fixtures/workflow-repo"

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

INSTALLER_COPY="$TEST_HOME/install.sh"
ARCHIVE_FILE="$TEST_HOME/dev-kit-main.tar.gz"
cp "$REPO_DIR/bin/scripts/install.sh" "$INSTALLER_COPY"
tar -czf "$ARCHIVE_FILE" -C "$(dirname "$REPO_DIR")" "$(basename "$REPO_DIR")"

INSTALL_OUTPUT="$(DEV_KIT_INSTALL_ARCHIVE_URL="file://$ARCHIVE_FILE" bash "$INSTALLER_COPY")"
assert_contains "$INSTALL_OUTPUT" "Installed dev.kit" "installer reports success"
assert_contains "$INSTALL_OUTPUT" "shell:  unchanged" "installer leaves shell init untouched"
assert_contains "$INSTALL_OUTPUT" "next:   export PATH=\"$HOME/.local/bin:\$PATH\"" "installer prints PATH fallback"
assert_contains "$INSTALL_OUTPUT" "then:   dev.kit" "installer prints command follow-up"

DEV_KIT_HOME="$HOME/.udx/dev.kit"
DEV_KIT_BIN_DIR="$HOME/.local/bin"

assert_file_exists "$DEV_KIT_HOME/bin/dev-kit" "installs command source into dev.kit home"
assert_file_exists "$DEV_KIT_HOME/lib/modules/bootstrap.sh" "installs internal modules"
assert_file_exists "$DEV_KIT_HOME/lib/modules/repo_signals.sh" "installs repo signal module"
assert_file_exists "$DEV_KIT_HOME/lib/modules/repo_factors.sh" "installs repo factor module"
assert_file_exists "$DEV_KIT_HOME/lib/commands/status.sh" "installs public commands"
assert_file_exists "$DEV_KIT_HOME/src/configs/audit-rules.yaml" "installs source rule catalog"
assert_file_exists "$DEV_KIT_HOME/src/configs/detection-patterns.yaml" "installs detection pattern catalog"
assert_file_exists "$DEV_KIT_HOME/src/configs/detection-signals.yaml" "installs detection signal catalog"
assert_file_exists "$DEV_KIT_HOME/src/templates/audit.json.tmpl" "installs audit json template"
assert_file_exists "$DEV_KIT_HOME/src/templates/bridge.json.tmpl" "installs bridge json template"
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

if HOME="$TEST_HOME" PATH="$BASE_PATH" bash -lc 'command -v dev.kit >/dev/null 2>&1'; then
  fail "command is not exposed in a fresh login shell before PATH setup"
else
  pass "command is not exposed in a fresh login shell before PATH setup"
fi

# shellcheck disable=SC1090
. "$DEV_KIT_HOME/bin/env/dev-kit.sh"

assert_contains ":$PATH:" ":$DEV_KIT_BIN_DIR:" "env script prepends the user bin dir for the current shell"

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
assert_contains "$simple_output" "archetype: library-cli" "simple repo audit detects library archetype"
assert_contains "$simple_output" "documentation: missing" "simple repo audit marks documentation missing"
assert_contains "$simple_output" "architecture: missing" "simple repo audit marks architecture missing"
assert_contains "$simple_output" "verification: partial" "simple repo audit marks verification partial"
assert_contains "$simple_output" "evidence: tests" "simple repo audit uses test directory evidence"
assert_contains "$simple_output" "Add a README" "simple repo audit gives documentation advice"
assert_contains "$simple_output" "repository structure" "simple repo audit gives architecture advice"
assert_contains "$simple_output" "Verification assets exist" "simple repo audit gives partial verification advice"
assert_contains "$simple_output" "runtime: not_applicable" "simple repo audit does not force runtime on library repos"

simple_json="$(fixture_audit_json "$SIMPLE_REPO")"
print_block "simple repo json" "$simple_json"
assert_contains "$simple_json" "\"command\": \"audit\"" "simple repo json reports audit command"
assert_contains "$simple_json" "\"archetype\": \"library-cli\"" "simple repo json reports library archetype"
assert_contains "$simple_json" "\"profile\": \"node\"" "simple repo json reports node profile"
assert_contains "$simple_json" "\"architecture\": {" "simple repo json includes architecture factor"
assert_contains "$simple_json" "\"verification\": {" "simple repo json includes verification factor"
assert_contains "$simple_json" "\"status\": \"partial\"" "simple repo json reports partial factor state"
assert_contains "$simple_json" "\"id\": \"partial-verification-entrypoint\"" "simple repo json includes partial verification finding"

documented_shell_output="$(fixture_audit_text "$DOCUMENTED_SHELL_REPO")"
print_block "documented shell repo audit" "$documented_shell_output"
assert_contains "$documented_shell_output" "archetype: library-cli" "documented shell audit detects library archetype"
assert_contains "$documented_shell_output" "profile: shell" "documented shell audit detects shell profile"
assert_contains "$documented_shell_output" "documentation: present" "documented shell audit marks documentation present"
assert_contains "$documented_shell_output" "architecture: partial" "documented shell audit marks architecture partial"
assert_contains "$documented_shell_output" "documented architecture sections" "documented shell audit uses architecture docs evidence"
assert_contains "$documented_shell_output" "verification: present" "documented shell audit marks verification present"
assert_contains "$documented_shell_output" "entrypoint: bash tests/run.sh" "documented shell audit finds documented verification entrypoint"
assert_contains "$documented_shell_output" "runtime: not_applicable" "documented shell audit skips runtime for library repos"

php_output="$(fixture_audit_text "$PHP_REPO")"
print_block "php repo audit" "$php_output"
assert_contains "$php_output" "archetype: library-cli" "php audit detects library archetype"
assert_contains "$php_output" "profile: php" "php audit detects php profile"
assert_contains "$php_output" "dependencies: present" "php audit detects dependency manifest"
assert_contains "$php_output" "architecture: missing" "php audit marks architecture missing"
assert_contains "$php_output" "verification: partial" "php audit marks verification partial"
assert_contains "$php_output" "phpunit.xml" "php audit uses phpunit evidence"
assert_contains "$php_output" "runtime: not_applicable" "php audit skips runtime when none exists"

docker_output="$(fixture_audit_text "$DOCKER_REPO")"
print_block "docker repo audit" "$docker_output"
assert_contains "$docker_output" "archetype: runtime-image" "docker audit detects runtime image archetype"
assert_contains "$docker_output" "profile: container" "docker audit detects container profile"
assert_contains "$docker_output" "architecture: present" "docker audit marks architecture present"
assert_contains "$docker_output" "thin command layer" "docker audit detects thin command layer"
assert_contains "$docker_output" "config: partial" "docker audit detects partial config contract"
assert_contains "$docker_output" "runtime: present" "docker audit marks runtime present"
assert_contains "$docker_output" "build_release_run: present" "docker audit marks build release run present"
assert_contains "$docker_output" "entrypoint: make run" "docker audit finds runtime entrypoint"

workflow_output="$(fixture_audit_text "$WORKFLOW_REPO")"
print_block "workflow repo audit" "$workflow_output"
assert_contains "$workflow_output" "archetype: workflow-repo" "workflow audit detects workflow archetype"
assert_contains "$workflow_output" "documentation: present" "workflow audit marks documentation present"
assert_contains "$workflow_output" "architecture: partial" "workflow audit marks architecture partial"
assert_contains "$workflow_output" "verification: present" "workflow audit marks verification present"
assert_contains "$workflow_output" "runtime: not_applicable" "workflow audit skips runtime factor"
assert_contains "$workflow_output" "build_release_run: not_applicable" "workflow audit skips build runtime separation"
assert_contains "$workflow_output" ".github/workflows/*.yml" "workflow audit uses workflow evidence"

bridge_json="$(cd "$DOCUMENTED_SHELL_REPO" && dev.kit bridge --json)"
print_block "documented shell bridge json" "$bridge_json"
assert_contains "$bridge_json" "\"command\": \"bridge\"" "bridge json is available"
assert_contains "$bridge_json" "\"model\": {" "bridge json includes model"
assert_contains "$bridge_json" "\"archetype\": \"library-cli\"" "bridge json exposes primary archetype"
assert_contains "$bridge_json" "\"profiles\": [\"shell\"]" "bridge json exposes discovered profiles"
assert_contains "$bridge_json" "\"guidance\": [" "bridge json includes agent guidance"
assert_contains "$bridge_json" "structural boundaries" "bridge json explains architecture workflow"
assert_contains "$bridge_json" "canonical verification step" "bridge json explains verification workflow"

help_output="$(dev.kit help)"
assert_contains "$help_output" "audit" "help discovers audit dynamically"
assert_contains "$help_output" "status" "help discovers status dynamically"
assert_contains "$help_output" "bridge" "help discovers bridge dynamically"
assert_contains "$help_output" "uninstall" "help discovers uninstall dynamically"

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
assert_contains "$completion_list" " uninstall " "completion lists uninstall"
assert_contains "$completion_list" " --json " "completion lists global json flag"

COMP_WORDS=(dev.kit bridge --)
COMP_CWORD=2
COMPREPLY=()
_dev_kit_complete
bridge_completion_list=" ${COMPREPLY[*]} "
assert_contains "$bridge_completion_list" " --json " "bridge completion lists json flag"

COMP_WORDS=(dev.kit uninstall --)
COMP_CWORD=2
COMPREPLY=()
_dev_kit_complete
uninstall_completion_list=" ${COMPREPLY[*]} "
assert_contains "$uninstall_completion_list" " --yes " "uninstall completion lists yes flag"
assert_not_contains "$uninstall_completion_list" "--json" "uninstall completion omits json flag"

UNINSTALL_CANCEL_OUTPUT="$(printf 'n\n' | "$DEV_KIT_HOME/bin/scripts/uninstall.sh" 2>&1 || true)"
assert_contains "$UNINSTALL_CANCEL_OUTPUT" "Cancelled." "uninstall prompt cancels by default"
assert_file_exists "$DEV_KIT_BIN_DIR/dev.kit" "cancelled uninstall keeps global symlink"
assert_file_exists "$DEV_KIT_HOME" "cancelled uninstall keeps installed home"

UNINSTALL_OUTPUT="$(dev.kit uninstall --yes)"
assert_contains "$UNINSTALL_OUTPUT" "Removed binary:" "uninstall removes the global binary"
assert_contains "$UNINSTALL_OUTPUT" "Removed home:" "uninstall removes the installed home"
assert_contains "$UNINSTALL_OUTPUT" "Shell profile files were not modified." "uninstall leaves shell init untouched"
assert_file_missing "$DEV_KIT_BIN_DIR/dev.kit" "global symlink is removed"
assert_file_missing "$DEV_KIT_HOME" "installed home is removed"

for profile in "${PROFILE_FILES[@]}"; do
  assert_command_output_contains "cat \"$profile\"" "test sentinel" "$(basename "$profile") remains unchanged after uninstall"
done

printf "ok - dev.kit integration suite completed\n"
