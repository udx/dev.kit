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
AVAILABLE_TEST_GROUPS="core archetypes learn install"
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
  assert_contains "$home_text" "[required]"                 "home text: renders env tools"
  assert_contains "$home_text" "[do next]"                 "home text: renders do-next"

  norepo="$(cd "$TEST_HOME" && dev.kit)"
  assert_contains "$norepo" "no repo detected"             "home: handles non-repo dir"

  repo_json="$(cd "$DOCUMENTED_SHELL_REPO" && dev.kit repo --json)"
  assert_contains "$repo_json" "\"archetype\":"            "repo: reports archetype"
  assert_contains "$repo_json" "\"factors\": {"           "repo: reports factors"
  assert_contains "$repo_json" "\"context\":"              "repo: reports context path"

  cp -R "$SIMPLE_REPO" "$SIMPLE_ACTION_REPO"
  rm -rf "$SIMPLE_ACTION_REPO/.dev-kit" "$SIMPLE_ACTION_REPO/.rabbit"

  # agent auto-generates context when missing — no manual dev.kit repo step needed
  agent_json="$(cd "$SIMPLE_ACTION_REPO" && dev.kit agent --json)"
  assert_contains "$agent_json" "\"archetype\":"           "agent: auto-generates context on demand"
  assert_contains "$agent_json" "\"workflow_contract\":"   "agent: reports workflow contract"

  context_yaml="${SIMPLE_ACTION_REPO}/.rabbit/context.yaml"
  assert_file_exists "$context_yaml"                                   "agent: creates .rabbit/context.yaml"
  assert_contains "$(cat "$context_yaml")" "kind: repoContext"         "agent: context.yaml has kind header"
  assert_contains "$(cat "$context_yaml")" "version: udx.io/dev.kit"  "agent: context.yaml has version"
  assert_contains "$(cat "$context_yaml")" "refs:"                     "agent: context.yaml has refs section"
  assert_not_contains "$(cat "$context_yaml")" "/Users/"               "agent: context.yaml has no absolute paths"
fi

# ── archetypes ─────────────────────────────────────────────────────────────────

if should_run "archetypes"; then
  wordpress_json="$(cd "$WORDPRESS_REPO" && dev.kit repo --json)"
  assert_contains "$wordpress_json" "\"archetype\": \"wordpress-site\""  "archetype: wordpress fixture"

  docker_json="$(cd "$DOCKER_REPO" && dev.kit repo --json)"
  assert_contains "$docker_json" "\"archetype\": \"runtime-image\""      "archetype: docker fixture"
fi

# ── learn ──────────────────────────────────────────────────────────────────────

if should_run "learn"; then
  LEARN_REPO="$TEST_HOME/learn.test-repo"
  cp -R "$DOCUMENTED_SHELL_REPO" "$LEARN_REPO"
  rm -rf "$LEARN_REPO/.dev-kit" "$LEARN_REPO/.rabbit"
  mkdir -p "$LEARN_REPO/.rabbit/dev.kit"
  LEARN_REPO="$(cd "$LEARN_REPO" && pwd)"  # normalize: macOS TMPDIR has trailing slash → // in paths

  # -- codex fixture (points at LEARN_REPO) --
  TEST_CODEX_HOME="$TEST_HOME/.codex"
  CODEX_UUID="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
  mkdir -p "$TEST_CODEX_HOME/sessions/2026/04/12"
  cat > "$TEST_CODEX_HOME/sessions/2026/04/12/rollout-2026-04-12T10-00-00-${CODEX_UUID}.jsonl" <<EOF
{"type":"session_meta","payload":{"id":"$CODEX_UUID","cwd":"$LEARN_REPO","originator":"codex-tui"}}
{"type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"# AGENTS.md instructions for $LEARN_REPO <INSTRUCTIONS> hidden bootstrap content </INSTRUCTIONS>"}]}}
{"type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"check deploy.yml and github actions workflow security gaps"}]}}
{"type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"https://github.com/test/repo/issues/42 related issue"}]}}
EOF

  # -- claude fixture (project dir derived from LEARN_REPO path) --
  CLAUDE_UUID="11111111-2222-3333-4444-555555555555"
  CLAUDE_PROJECT_ID="$(printf "%s" "$LEARN_REPO" | sed -E 's|/|-|g; s|[^[:alnum:]_-]|-|g; s|-+|-|g')"
  TEST_CLAUDE_PROJECTS="$TEST_HOME/.claude-projects"
  TEST_CLAUDE_HISTORY="$TEST_HOME/.claude-history.jsonl"
  mkdir -p "$TEST_CLAUDE_PROJECTS/$CLAUDE_PROJECT_ID"
  cat > "$TEST_CLAUDE_PROJECTS/$CLAUDE_PROJECT_ID/${CLAUDE_UUID}.jsonl" <<EOF
{"type":"user","message":{"role":"user","content":"review .github/workflows and deploy.yml security configuration"},"promptId":"p-001","isMeta":false,"cwd":"$LEARN_REPO","sessionId":"$CLAUDE_UUID"}
{"type":"user","message":{"role":"user","content":"https://github.com/test/repo/pull/5 check workflow gaps"},"promptId":"p-002","isMeta":false,"cwd":"$LEARN_REPO","sessionId":"$CLAUDE_UUID"}
EOF
  cat > "$TEST_CLAUDE_HISTORY" <<EOF
{"display":"review .github/workflows and deploy.yml security configuration","timestamp":1775930000000,"project":"$LEARN_REPO","sessionId":"$CLAUDE_UUID"}
{"display":"claude history prefers this compact prompt","timestamp":1775930001000,"project":"$LEARN_REPO","sessionId":"$CLAUDE_UUID"}
EOF

  export CODEX_HOME="$TEST_CODEX_HOME"
  export CLAUDE_PROJECTS_ROOT="$TEST_CLAUDE_PROJECTS"
  export CLAUDE_HISTORY_FILE="$TEST_CLAUDE_HISTORY"

  # 1. codex-only source
  learn_codex="$(cd "$LEARN_REPO" && DEV_KIT_LEARN_SOURCES=codex dev.kit learn --json)"
  assert_contains     "$learn_codex" "\"codex\""    "learn: codex source in observed"
  assert_contains     "$learn_codex" "$CODEX_UUID"  "learn: codex session ID present"
  assert_not_contains "$learn_codex" "\"claude\""   "learn: codex-only excludes claude"

  # 2. claude-only source
  learn_claude="$(cd "$LEARN_REPO" && DEV_KIT_LEARN_SOURCES=claude dev.kit learn --json)"
  assert_contains     "$learn_claude" "\"claude\""   "learn: claude source in observed"
  assert_contains     "$learn_claude" "$CLAUDE_UUID" "learn: claude session ID present"
  assert_not_contains "$learn_claude" "\"codex\""    "learn: claude-only excludes codex"

  # 3. multi-source default (both)
  learn_multi="$(cd "$LEARN_REPO" && dev.kit learn --json)"
  assert_contains "$learn_multi" "\"claude\""          "learn: multi-source includes claude"
  assert_contains "$learn_multi" "\"codex\""           "learn: multi-source includes codex"
  assert_contains "$learn_multi" "\"observed_sources\"" "learn: observed_sources array present"

  # 4. artifact written (text mode)
  (cd "$LEARN_REPO" && dev.kit learn) >/dev/null 2>&1
  artifact="$(ls "$LEARN_REPO/.rabbit/dev.kit/lessons-"*.md 2>/dev/null | head -1)"
  assert_file_exists "$artifact"                             "learn: artifact file written"
  assert_contains "$(cat "$artifact")" "## Workflow rules"  "learn: artifact has workflow rules section"
  assert_contains "$(cat "$artifact")" "## Ready templates" "learn: artifact has ready templates section"
  assert_contains "$(cat "$artifact")" "## Evidence highlights" "learn: artifact has evidence highlights section"
  assert_contains "$(cat "$artifact")" "github.com"         "learn: artifact includes referenced URLs"
  assert_not_contains "$(cat "$artifact")" "AGENTS.md instructions" "learn: artifact excludes bootstrap prompt noise"
  assert_contains "$(cat "$artifact")" "Use repo workflow assets like deploy.yml" "learn: artifact packages rule guidance"
  assert_contains "$(cat "$artifact")" '`Workflow tracing`' "learn: artifact packages reusable templates"
  assert_contains "$(cat "$artifact")" "claude history prefers this compact prompt" "learn: artifact keeps compact evidence highlights"

  # 5. incremental: sessions older than last-run are skipped
  touch -t 203001010000 "$LEARN_REPO/.rabbit/dev.kit/learn-last-run"
  learn_incr="$(cd "$LEARN_REPO" && dev.kit learn --json)"
  assert_not_contains "$learn_incr" "$CODEX_UUID"  "learn: incremental skips old codex session"
  assert_not_contains "$learn_incr" "$CLAUDE_UUID" "learn: incremental skips old claude session"

  # 6. deleting the artifact resets the incremental baseline and rebuilds from all sessions
  rm -f "$artifact"
  learn_rebuild="$(cd "$LEARN_REPO" && dev.kit learn --json)"
  assert_contains "$learn_rebuild" "$CODEX_UUID"  "learn: missing artifact rebuilds codex history"
  assert_contains "$learn_rebuild" "$CLAUDE_UUID" "learn: missing artifact rebuilds claude history"
  rm -f "$LEARN_REPO/.rabbit/dev.kit/learn-last-run"

  # 7. incremental artifact merges previous lessons with new session-derived deltas
  (cd "$LEARN_REPO" && dev.kit learn) >/dev/null 2>&1
  sleep 1
  SECOND_CODEX_UUID="ffffffff-1111-2222-3333-444444444444"
  mkdir -p "$TEST_CODEX_HOME/sessions/2026/04/13"
  cat > "$TEST_CODEX_HOME/sessions/2026/04/13/rollout-2026-04-13T12-00-00-${SECOND_CODEX_UUID}.jsonl" <<EOF
{"type":"session_meta","payload":{"id":"$SECOND_CODEX_UUID","cwd":"$LEARN_REPO","originator":"codex-tui"}}
{"type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"readme docs first cleanup legacy modules and keep configuration separate from code"}]}}
{"type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"https://github.com/test/repo/pull/9 review cleanup scope"}]}}
EOF
  learn_merge="$(cd "$LEARN_REPO" && dev.kit learn --json)"
  assert_contains "$learn_merge" "$SECOND_CODEX_UUID" "learn: incremental picks newly added session"
  (cd "$LEARN_REPO" && dev.kit learn) >/dev/null 2>&1
  merged_artifact="$(ls "$LEARN_REPO/.rabbit/dev.kit/lessons-"*.md 2>/dev/null | head -1)"
  merged_artifact_text="$(cat "$merged_artifact")"
  assert_contains "$merged_artifact_text" "https://github.com/test/repo/issues/42" "learn: merged artifact retains prior references"
  assert_contains "$merged_artifact_text" "https://github.com/test/repo/pull/9" "learn: merged artifact adds new references"
  assert_contains "$merged_artifact_text" '`Config-over-code`' "learn: merged artifact adds new reusable template"

  # 8. no sessions — use env to ensure override reaches the subprocess
  learn_empty="$(cd "$LEARN_REPO" && \
    env CODEX_HOME="$TEST_HOME/no-codex" CLAUDE_PROJECTS_ROOT="$TEST_HOME/no-claude" \
    dev.kit learn)"
  assert_contains "$learn_empty" "no new agent sessions found since the latest lessons artifact" "learn: handles empty incremental runs gracefully"

  unset CODEX_HOME CLAUDE_PROJECTS_ROOT CLAUDE_HISTORY_FILE
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
