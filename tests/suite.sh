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
CODEX_HOME_FIXTURE="$REPO_DIR/tests/fixtures/codex-home"
LEARN_CODEX_HOME="$TEST_HOME/codex-home"
LEARN_SESSION_ID="019d4f54-eddc-7350-a757-3bb578d24f99"
SIMPLE_ACTION_REPO="$TEST_HOME/simple-action-repo"
GIT_REPO="$TEST_HOME/git-repo"
NESTED_REPO_DIR="$DOCUMENTED_SHELL_REPO/scripts"
TEST_MODE="${DEV_KIT_TEST_MODE:-smoke}"
TEST_ONLY="${DEV_KIT_TEST_ONLY:-}"
AVAILABLE_TEST_GROUPS="home explore action git-action learn help completion repo-family uninstall"

if [ -n "${CI:-}" ]; then
  TEST_MODE="full"
fi

cleanup() {
  rm -rf "$TEST_HOME"
}

trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: bash tests/suite.sh [--only group1,group2] [--list]

Groups:
  home
  explore
  action
  git-action
  learn
  help
  completion
  repo-family
  uninstall
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

print_block() {
  local title="$1"
  local content="$2"

  printf '%s\n' "--- ${title} ---"
  printf '%s\n' "$content"
  printf '%s\n' "--- end ${title} ---"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --only)
      shift
      [ "$#" -gt 0 ] || fail "--only requires a comma-separated list"
      TEST_ONLY="$1"
      ;;
    --list)
      list_groups
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      ;;
  esac
  shift
done

mkdir -p "$TEST_HOME"
mkdir -p "$LEARN_CODEX_HOME/sessions/2026/04/02"
export HOME="$TEST_HOME"
export PATH="$BASE_PATH"
unset DEV_KIT_HOME
unset DEV_KIT_BIN_DIR

cat > "$LEARN_CODEX_HOME/sessions/2026/04/02/rollout-2026-04-02T20-54-19-${LEARN_SESSION_ID}.jsonl" <<EOF
{"timestamp":"2026-04-02T17:54:23.549Z","type":"session_meta","payload":{"id":"${LEARN_SESSION_ID}","timestamp":"2026-04-02T17:54:19.235Z","cwd":"${DOCUMENTED_SHELL_REPO}","originator":"codex-tui","cli_version":"0.118.0","source":"cli","model_provider":"openai"}}
{"timestamp":"2026-04-02T17:54:23.553Z","type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"https://github.com/icamiami/icamiami.org/issues/1897"}]}}
{"timestamp":"2026-04-02T17:54:29.875Z","type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"I’m pulling the issue details first and checking whether this workspace matches that repository before making any changes. After that I’ll trace the affected code path and implement the fix locally if the code is here."}],"phase":"commentary"}}
{"timestamp":"2026-04-02T17:56:56.484Z","type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"let's do make build and confirm build"}]}}
{"timestamp":"2026-04-02T17:57:30.573Z","type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"also, use deploy.yml to deploy and see if tf really upgraded"}]}}
{"timestamp":"2026-04-02T18:00:01.549Z","type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"let's create github branch and sync to remote"}]}}
{"timestamp":"2026-04-02T18:48:40.260Z","type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"ok, let's prepare brief PR"}]}}
{"timestamp":"2026-04-02T18:50:41.200Z","type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"let's add related github issue"}]}}
{"timestamp":"2026-04-03T10:51:58.211Z","type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"nice, I merged and new release was completed, let's see if you can find related github action workflow and releases artifacts there were created, vulnerabilities reduce that happened and so on, so basically collect some data so we can plan brief update comment to related github issue, right?"}]}}
{"timestamp":"2026-04-03T11:04:21.403Z","type":"event_msg","payload":{"type":"exec_command_end","aggregated_output":"{\"html_url\":\"https://github.com/icamiami/icamiami.org/issues/1897#issuecomment-4183019047\",\"body\":\"✅ Update: [udx/worker-tooling#57](https://github.com/udx/worker-tooling/pull/57) was merged and released as [\`0.19.0\`](https://github.com/udx/worker-tooling/releases/tag/0.19.0) on 2026-04-02. Findings improvement in code scanning. ⚠️ Next step: update rabbit-automation-action.\"}"}}
EOF

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

if should_run "home"; then
  default_output="$(cd "$DOCUMENTED_SHELL_REPO" && dev.kit)"
  print_block "default output" "$default_output"
  assert_contains "$default_output" "dev.kit" "default command runs landing output"
  assert_contains "$default_output" "[workspace]" "default landing renders workspace section"
  assert_contains "$default_output" "[helpers]" "default landing renders helper section"

  default_json="$(cd "$DOCUMENTED_SHELL_REPO" && dev.kit --json)"
  print_block "default json" "$default_json"
  assert_contains "$default_json" "\"repo_detected\": true" "default json detects repo"
  assert_contains "$default_json" "\"root\": \"$DOCUMENTED_SHELL_REPO\"" "default json reports repo root"
  assert_contains "$default_json" "\"localhost_tools\": [" "default json reports localhost tools"
  assert_contains "$default_json" "\"start_here\": [" "default json reports start-here workflow"
  assert_contains "$default_json" "\"agent_contract\": [" "default json reports agent contract"

  nested_output="$(cd "$NESTED_REPO_DIR" && dev.kit)"
  print_block "nested output" "$nested_output"
  assert_contains "$nested_output" "repo root:         $DOCUMENTED_SHELL_REPO" "default landing resolves repo root from nested dir"

  non_repo_output="$(cd "$TEST_HOME" && dev.kit)"
  print_block "non repo output" "$non_repo_output"
  assert_contains "$non_repo_output" "No repository detected in the current directory" "default landing detects non repo workspace"
  assert_contains "$non_repo_output" "guide:             navigate into a repo, then run dev.kit again" "default landing guides non repo users"
fi

if should_run "explore"; then
  explore_json="$(cd "$DOCUMENTED_SHELL_REPO" && dev.kit explore --json)"
  print_block "explore json" "$explore_json"
  assert_contains "$explore_json" "\"command\": \"explore\"" "explore json reports command"
  assert_contains "$explore_json" "\"markers\": [" "explore json reports repo markers"
  assert_contains "$explore_json" "\"workflow_refs\": [" "explore json reports workflow refs"
  assert_contains "$explore_json" "\"knowledge_base\": { \"local_repos_root\": \"git/udx\", \"remote_org_root\": \"github.com/udx\" }" "explore json reports knowledge hierarchy"
  assert_contains "$explore_json" "\"source_chain\": [" "explore json reports source chain"
  assert_contains "$explore_json" "\"workflow_contract\": [" "explore json reports workflow contract"
  assert_contains "$explore_json" "\"command\": \"bash tests/run.sh\"" "explore json reports canonical verification command"
fi

cp -R "$SIMPLE_REPO" "$SIMPLE_ACTION_REPO"

if should_run "action"; then
  simple_action_json="$(cd "$SIMPLE_ACTION_REPO" && dev.kit action --json)"
  print_block "simple action json" "$simple_action_json"
  assert_contains "$simple_action_json" "\"command\": \"action\"" "action json reports command"
  assert_contains "$simple_action_json" "\"archetype\": \"library-cli\"" "action json reports primary archetype"
  assert_contains "$simple_action_json" "\"profile\": \"node\"" "action json reports primary profile"
  assert_contains "$simple_action_json" "\"findings\": [" "action json reports findings"
  assert_contains "$simple_action_json" "\"git_workflow\": { \"available\": false }" "action json reports missing git workflow"
  assert_contains "$simple_action_json" "\"agent_contract\": [" "action json reports agent contract"
  assert_contains "$simple_action_json" "\"verification\": {" "action json reports factor state"
  assert_contains "$simple_action_json" "Add a README" "action json reports documentation guidance"
fi

mkdir -p "$GIT_REPO"
git -C "$GIT_REPO" init -b main >/dev/null 2>&1
git -C "$GIT_REPO" config user.name "dev.kit tests"
git -C "$GIT_REPO" config user.email "devkit@example.com"
printf 'hello\n' > "$GIT_REPO/README.md"
git -C "$GIT_REPO" add README.md
git -C "$GIT_REPO" commit -m "Initial commit" >/dev/null 2>&1

if should_run "git-action"; then
  git_action_json="$(cd "$GIT_REPO" && dev.kit action --json)"
  print_block "git action json" "$git_action_json"
  assert_contains "$git_action_json" "\"available\": true" "action json reports git workflow availability"
  assert_contains "$git_action_json" "\"id\": \"action-git\"" "action json reports git workflow id"
  assert_contains "$git_action_json" "\"name\": \"dev.action git\"" "action json reports git workflow name"
  assert_contains "$git_action_json" "Current branch main has no upstream" "action json reports git next hint"
  assert_contains "$git_action_json" "\"pre-push\"" "action json reports hook state"
  assert_contains "$git_action_json" "\"branch_prepare\"" "action json reports workflow steps"
fi

if should_run "learn"; then
  learn_json="$(cd "$DOCUMENTED_SHELL_REPO" && dev.kit learn --json)"
  print_block "learn json" "$learn_json"
  assert_contains "$learn_json" "\"command\": \"learn\"" "learn json reports command"
  assert_contains "$learn_json" "\"destinations\": [" "learn json reports destinations"
  assert_contains "$learn_json" "\"name\": \"dev.learn pr\"" "learn json reports workflow name"
  assert_contains "$learn_json" "\"id\": \"gh_issue\"" "learn json reports github issue destination"

  learn_session_json="$(cd "$DOCUMENTED_SHELL_REPO" && CODEX_HOME="$LEARN_CODEX_HOME" dev.kit learn --json)"
  print_block "learn session json" "$learn_session_json"
  assert_contains "$learn_session_json" "\"type\": \"local_agent_session\"" "learn session json reports discovered local agent session source"
  assert_contains "$learn_session_json" "\"shared_context\": { \"mode\": \"issue-root\"" "learn session json reports issue-root shared context"
  assert_contains "$learn_session_json" "\"id\": \"issue-scope\"" "learn session json reports workflow derived from the session"
  assert_contains "$learn_session_json" "\"id\": \"source-backed-updates\"" "learn session json reports lessons derived from the session"
  assert_contains "$learn_session_json" "https://github.com/icamiami/icamiami.org/issues/1897" "learn session json reports linked github issue"
fi

if should_run "help"; then
  help_output="$(dev.kit help)"
  assert_contains "$help_output" "explore" "help lists explore"
  assert_contains "$help_output" "action" "help lists action"
  assert_contains "$help_output" "learn" "help lists learn"
  assert_contains "$help_output" "uninstall" "help lists uninstall"
  assert_not_contains "$help_output" "bridge" "help hides bridge"
  assert_not_contains "$help_output" "sync" "help hides sync"
  assert_not_contains "$help_output" "save" "help hides save"
  assert_not_contains "$help_output" "audit" "help hides audit"
fi

if should_run "completion"; then
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
fi

if should_run "repo-family" && [ "$TEST_MODE" = "full" ]; then
  wordpress_action_json="$(cd "$WORDPRESS_REPO" && dev.kit action --json)"
  print_block "wordpress action json" "$wordpress_action_json"
  assert_contains "$wordpress_action_json" "\"archetype\": \"wordpress-site\"" "wordpress action detects wordpress archetype"
  assert_contains "$wordpress_action_json" "\"entrypoint\": \"npm test\"" "wordpress action detects canonical verification entrypoint"
  assert_contains "$wordpress_action_json" "\"source_chain\": [" "wordpress action reports source chain"
  assert_contains "$wordpress_action_json" "development/<env>/ (existing: develop-alex)" "wordpress action reports env override hint"

  wordpress_explore_json="$(cd "$WORDPRESS_REPO" && dev.kit explore --json)"
  assert_contains "$wordpress_explore_json" "\"./README.md\"" "wordpress explore prioritizes the readme"
  assert_contains "$wordpress_explore_json" "\"udx/gh-workflows/.github/workflows/infra-build.yml@master\"" "wordpress explore reports reusable workflow ref"
  assert_contains "$wordpress_explore_json" "\"./.rabbit/infra_configs\"" "wordpress explore prioritizes infra configs"

  docker_action_json="$(cd "$DOCKER_REPO" && dev.kit action --json)"
  print_block "docker action json" "$docker_action_json"
  assert_contains "$docker_action_json" "\"archetype\": \"runtime-image\"" "docker action detects runtime image archetype"
  assert_contains "$docker_action_json" "\"entrypoint\": \"make run\"" "docker action detects runtime entrypoint"

  docker_explore_json="$(cd "$DOCKER_REPO" && dev.kit explore --json)"
  assert_contains "$docker_explore_json" "\"./Makefile\"" "docker explore prioritizes the makefile"
  assert_contains "$docker_explore_json" "\"./deploy.yml\"" "docker explore prioritizes deploy config"
elif should_run "repo-family"; then
  pass "full repo-family regression fixtures are skipped in smoke mode"
fi

if should_run "uninstall"; then
  UNINSTALL_CANCEL_OUTPUT="$(printf 'n\n' | "$DEV_KIT_HOME/bin/scripts/uninstall.sh" 2>&1 || true)"
  assert_contains "$UNINSTALL_CANCEL_OUTPUT" "Cancelled." "uninstall prompt cancels by default"
  assert_file_exists "$DEV_KIT_BIN_DIR/dev.kit" "cancelled uninstall keeps global symlink"
  assert_file_exists "$DEV_KIT_HOME" "cancelled uninstall keeps installed home"

  UNINSTALL_OUTPUT="$(dev.kit uninstall --yes)"
  assert_contains "$UNINSTALL_OUTPUT" "Removed dev.kit" "uninstall prints removal title"
  assert_contains "$UNINSTALL_OUTPUT" "binary:" "uninstall removes the global binary"
  assert_contains "$UNINSTALL_OUTPUT" "home:" "uninstall removes the installed home"
  assert_file_missing "$DEV_KIT_BIN_DIR/dev.kit" "global symlink is removed"
  assert_file_missing "$DEV_KIT_HOME" "installed home is removed"

  for profile in "${PROFILE_FILES[@]}"; do
    assert_command_output_contains "cat \"$profile\"" "test sentinel" "$(basename "$profile") remains unchanged after uninstall"
  done
fi

printf "ok - dev.kit integration suite completed\n"
