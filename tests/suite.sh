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
DOCKER_REPO="$REPO_DIR/tests/fixtures/docker-repo"
WORDPRESS_REPO="$REPO_DIR/tests/fixtures/wordpress-repo"
SIMPLE_ACTION_REPO="$TEST_HOME/simple-action-repo"
GIT_REPO="$TEST_HOME/git-repo"
TEST_MODE="${DEV_KIT_TEST_MODE:-smoke}"

if [ -n "${CI:-}" ]; then
  TEST_MODE="full"
fi

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
assert_contains "$INSTALL_OUTPUT" "then:   dev.kit" "installer prints command follow-up"

DEV_KIT_HOME="$HOME/.udx/dev.kit"
DEV_KIT_BIN_DIR="$HOME/.local/bin"

assert_file_exists "$DEV_KIT_HOME/bin/dev-kit" "installs command source into dev.kit home"
assert_file_exists "$DEV_KIT_HOME/lib/commands/action.sh" "installs action command"
assert_file_exists "$DEV_KIT_HOME/lib/modules/repo_signals.sh" "installs repo signal module"
assert_file_exists "$DEV_KIT_HOME/src/configs/knowledge-base.yaml" "installs knowledge base catalog"
assert_file_exists "$DEV_KIT_HOME/src/configs/tooling-refs.yaml" "installs tooling refs catalog"
assert_file_exists "$DEV_KIT_HOME/src/templates/action.json" "installs action json template"
assert_file_exists "$DEV_KIT_HOME/src/templates/explore.json" "installs explore json template"
assert_file_exists "$DEV_KIT_HOME/src/templates/learn.json" "installs learn json template"
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

if command -v dev.kit >/dev/null 2>&1; then
  pass "command resolves after env setup"
else
  fail "command resolves after env setup"
fi

default_output="$(cd "$DOCUMENTED_SHELL_REPO" && dev.kit)"
print_block "default output" "$default_output"
assert_contains "$default_output" "dev.kit" "default command runs landing output"
assert_contains "$default_output" "mode:              repo detected" "default landing detects repo"
assert_contains "$default_output" "archetype:         library-cli" "default landing reports repo identity"
assert_contains "$default_output" "docker:" "default landing reports localhost tools"
assert_contains "$default_output" "explore:           dev.kit explore" "default landing reports helper commands"

default_json="$(cd "$DOCUMENTED_SHELL_REPO" && dev.kit --json)"
print_block "default json" "$default_json"
assert_contains "$default_json" "\"repo_detected\": true" "default json detects repo"
assert_contains "$default_json" "\"localhost_tools\": [" "default json reports localhost tools"

non_repo_output="$(cd "$TEST_HOME" && dev.kit)"
print_block "non repo output" "$non_repo_output"
assert_contains "$non_repo_output" "mode:              not a repo" "default landing detects non repo workspace"
assert_contains "$non_repo_output" "guide:             navigate into a repo, then run dev.kit again" "default landing guides non repo users"

explore_output="$(cd "$DOCUMENTED_SHELL_REPO" && dev.kit explore)"
print_block "explore output" "$explore_output"
assert_contains "$explore_output" "dev.kit explore" "explore command is available"
assert_contains "$explore_output" "tools:" "explore reports operating tools"
assert_contains "$explore_output" "git, gh, npm, docker" "explore lists operating tools"
assert_contains "$explore_output" "formats:" "explore reports operating formats"
assert_contains "$explore_output" "yml, yaml" "explore lists operating formats"
assert_contains "$explore_output" "local repos:" "explore reports local knowledge root"
assert_contains "$explore_output" "git/udx" "explore lists local knowledge root"
assert_contains "$explore_output" "remote org:" "explore reports remote knowledge root"
assert_contains "$explore_output" "github.com/udx" "explore lists remote knowledge root"
assert_contains "$explore_output" "dev.kit action --json" "explore reports action workflow"
assert_contains "$explore_output" "udx/gh-workflows" "explore reports tooling repos"
assert_contains "$explore_output" "[workflow contract]" "explore reports workflow contract"
assert_contains "$explore_output" "command: bash tests/run.sh" "explore workflow contract uses canonical verification"

explore_json="$(cd "$DOCUMENTED_SHELL_REPO" && dev.kit explore --json)"
print_block "explore json" "$explore_json"
assert_contains "$explore_json" "\"command\": \"explore\"" "explore json reports command"
assert_contains "$explore_json" "\"knowledge_base\": { \"local_repos_root\": \"git/udx\", \"remote_org_root\": \"github.com/udx\" }" "explore json reports knowledge hierarchy"
assert_contains "$explore_json" "\"workflow_contract\": [" "explore json reports workflow contract"

cp -R "$SIMPLE_REPO" "$SIMPLE_ACTION_REPO"

simple_action="$(cd "$SIMPLE_ACTION_REPO" && dev.kit action)"
print_block "simple action" "$simple_action"
assert_contains "$simple_action" "dev.kit action" "action command is available"
assert_contains "$simple_action" "archetype: library-cli" "action reports archetype"
assert_contains "$simple_action" "profile: node" "action reports profile"
assert_contains "$simple_action" "documentation: missing" "action reports factor state"
assert_contains "$simple_action" "[improvement priorities]" "action reports improvement priorities"
assert_contains "$simple_action" "Add a README" "action reports documentation guidance"
assert_contains "$simple_action" "[git workflow]" "action reports missing git workflow cleanly"
assert_contains "$simple_action" "status:            unavailable" "action reports missing git workflow cleanly"

simple_action_json="$(cd "$SIMPLE_ACTION_REPO" && dev.kit action --json)"
print_block "simple action json" "$simple_action_json"
assert_contains "$simple_action_json" "\"command\": \"action\"" "action json reports command"
assert_contains "$simple_action_json" "\"archetype\": \"library-cli\"" "action json reports primary archetype"
assert_contains "$simple_action_json" "\"profile\": \"node\"" "action json reports primary profile"
assert_contains "$simple_action_json" "\"findings\": [" "action json reports findings"
assert_contains "$simple_action_json" "\"git_workflow\": { \"available\": false }" "action json reports missing git workflow"

mkdir -p "$GIT_REPO"
git -C "$GIT_REPO" init -b main >/dev/null 2>&1
git -C "$GIT_REPO" config user.name "dev.kit tests"
git -C "$GIT_REPO" config user.email "devkit@example.com"
printf 'hello\n' > "$GIT_REPO/README.md"
git -C "$GIT_REPO" add README.md
git -C "$GIT_REPO" commit -m "Initial commit" >/dev/null 2>&1

git_action="$(cd "$GIT_REPO" && dev.kit action)"
print_block "git action" "$git_action"
assert_contains "$git_action" "mode:              dev" "action defaults to dev mode"
assert_contains "$git_action" "[git workflow]" "action includes git workflow section"
assert_contains "$git_action" "workflow:          dev.sync git" "action includes workflow name"
assert_contains "$git_action" "Analyze branch state: Current branch main has no upstream" "action includes sync next hint"

git_action_json="$(cd "$GIT_REPO" && dev.kit action --json)"
print_block "git action json" "$git_action_json"
assert_contains "$git_action_json" "\"available\": true" "action json reports git workflow availability"
assert_contains "$git_action_json" "\"id\": \"sync-git\"" "action json reports git workflow id"
assert_contains "$git_action_json" "\"mode\": \"dev\"" "action json reports default mode"
assert_contains "$git_action_json" "\"pre-push\"" "action json reports hook state"
assert_contains "$git_action_json" "\"branch_prepare\"" "action json reports workflow steps"

learn_output="$(cd "$DOCUMENTED_SHELL_REPO" && dev.kit learn)"
print_block "learn output" "$learn_output"
assert_contains "$learn_output" "workflow: dev.learn pr" "learn uses the default workflow"
assert_contains "$learn_output" "mode: evaluation-only" "learn stays lightweight by default"
assert_contains "$learn_output" "gh_issue:" "learn reports github issue destination"

learn_json="$(cd "$DOCUMENTED_SHELL_REPO" && dev.kit learn --json)"
print_block "learn json" "$learn_json"
assert_contains "$learn_json" "\"command\": \"learn\"" "learn json reports command"
assert_contains "$learn_json" "\"destinations\": [" "learn json reports destinations"

help_output="$(dev.kit help)"
assert_contains "$help_output" "explore" "help lists explore"
assert_contains "$help_output" "action" "help lists action"
assert_contains "$help_output" "learn" "help lists learn"
assert_contains "$help_output" "uninstall" "help lists uninstall"
assert_not_contains "$help_output" "bridge" "help hides bridge"
assert_not_contains "$help_output" "sync" "help hides sync"
assert_not_contains "$help_output" "save" "help hides save"
assert_not_contains "$help_output" "audit" "help hides audit"

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
assert_contains "$completion_list" " explore " "completion lists explore"
assert_contains "$completion_list" " action " "completion lists action"
assert_contains "$completion_list" " learn " "completion lists learn"
assert_contains "$completion_list" " uninstall " "completion lists uninstall"
assert_not_contains "$completion_list" " bridge " "completion hides bridge"
assert_not_contains "$completion_list" " sync " "completion hides sync"
assert_contains "$completion_list" " --json " "completion lists global json flag"

COMP_WORDS=(dev.kit action --)
COMP_CWORD=2
COMPREPLY=()
_dev_kit_complete
action_completion_list=" ${COMPREPLY[*]} "
assert_contains "$action_completion_list" " --json " "action completion lists json flag"
assert_not_contains "$action_completion_list" " --pr " "action completion hides legacy pr mode"

if [ "$TEST_MODE" = "full" ]; then
  wordpress_action="$(cd "$WORDPRESS_REPO" && dev.kit action)"
  print_block "wordpress action" "$wordpress_action"
  assert_contains "$wordpress_action" "archetype: wordpress-site" "wordpress action detects wordpress archetype"
  assert_contains "$wordpress_action" "verification: present" "wordpress action detects canonical verification entrypoint"

  wordpress_explore="$(cd "$WORDPRESS_REPO" && dev.kit explore)"
  assert_contains "$wordpress_explore" "./README.md" "wordpress explore prioritizes the readme"
  assert_contains "$wordpress_explore" "./.github/workflows" "wordpress explore prioritizes github workflows"

  docker_action="$(cd "$DOCKER_REPO" && dev.kit action)"
  print_block "docker action" "$docker_action"
  assert_contains "$docker_action" "archetype: runtime-image" "docker action detects runtime image archetype"
  assert_contains "$docker_action" "entrypoint: make run" "docker action detects runtime entrypoint"

  docker_explore="$(cd "$DOCKER_REPO" && dev.kit explore)"
  assert_contains "$docker_explore" "./Makefile" "docker explore prioritizes the makefile"
  assert_contains "$docker_explore" "./deploy.yml" "docker explore prioritizes deploy config"
else
  pass "full repo-family regression fixtures are skipped in smoke mode"
fi

UNINSTALL_CANCEL_OUTPUT="$(printf 'n\n' | "$DEV_KIT_HOME/bin/scripts/uninstall.sh" 2>&1 || true)"
assert_contains "$UNINSTALL_CANCEL_OUTPUT" "Cancelled." "uninstall prompt cancels by default"
assert_file_exists "$DEV_KIT_BIN_DIR/dev.kit" "cancelled uninstall keeps global symlink"
assert_file_exists "$DEV_KIT_HOME" "cancelled uninstall keeps installed home"

UNINSTALL_OUTPUT="$(dev.kit uninstall --yes)"
assert_contains "$UNINSTALL_OUTPUT" "Removed binary:" "uninstall removes the global binary"
assert_contains "$UNINSTALL_OUTPUT" "Removed home:" "uninstall removes the installed home"
assert_file_missing "$DEV_KIT_BIN_DIR/dev.kit" "global symlink is removed"
assert_file_missing "$DEV_KIT_HOME" "installed home is removed"

for profile in "${PROFILE_FILES[@]}"; do
  assert_command_output_contains "cat \"$profile\"" "test sentinel" "$(basename "$profile") remains unchanged after uninstall"
done

printf "ok - dev.kit integration suite completed\n"
