#!/bin/bash

dev_kit_cmd_exec() {
  shift || true
  local print_only="false"
  local show_log="false"
  local stream_logs="true"

  case "${1:-}" in
    --print|--dry-run)
      print_only="true"
      shift
      ;;
    --show-log)
      show_log="true"
      shift
      ;;
    --stream)
      stream_logs="true"
      shift
      ;;
    --no-stream|--quiet)
      stream_logs="false"
      shift
      ;;
    -h|--help)
      cat <<'EXEC_USAGE'
Usage: dev.kit exec [--print] [--show-log] [--stream|--no-stream] "<request>"

Options:
  --print, --dry-run  Print the normalized prompt without running codex
  --show-log          Print full codex exec logs after completion
  --stream            Stream codex exec logs to stdout (default)
  --no-stream, --quiet  Suppress streaming logs (log file only)
EXEC_USAGE
      exit 0
      ;;
  esac

  local user_prompt=""
  if [ "$#" -gt 0 ]; then
    user_prompt="$*"
  else
    if [ -t 0 ]; then
      echo "Missing request. Example: dev.kit exec \"optimize dev.kit repo\"" >&2
      exit 1
    fi
    user_prompt="$(cat)"
  fi

  ensure_dev_kit_home
  local repo_root=""
  repo_root="$(get_repo_root || true)"
  local local_config=""
  local_config="$(local_config_path || true)"
  local prompt_key=""
  prompt_key="$(config_value_scoped exec.prompt "")"

  if [ -z "$prompt_key" ]; then
    prompt_key="base"
  fi

  local prompt_path=""
  case "$prompt_key" in
    base|default) prompt_path="$REPO_DIR/src/prompts/index.md" ;;
    ai) prompt_path="$REPO_DIR/src/prompts/ai/index.md" ;;
    ai.codex|codex) prompt_path="$REPO_DIR/src/prompts/ai/codex/index.md" ;;
    ai.claude|claude) prompt_path="$REPO_DIR/src/prompts/ai/claude/index.md" ;;
    developer|dev|dev.kit.developer) prompt_path="$REPO_DIR/src/prompts/developer/index.md" ;;
    *)
      if [[ "$prompt_key" == *"/"* ]] || [[ "$prompt_key" == *.md ]] || [[ "$prompt_key" == "~/"* ]]; then
        prompt_path="$(expand_path "$prompt_key")"
      fi
      ;;
  esac

  if [ -z "$prompt_path" ] || [ ! -f "$prompt_path" ]; then
    prompt_path="$REPO_DIR/src/prompts/index.md"
  fi

  local prompt_body=""
  if [ -f "$prompt_path" ]; then
    prompt_body="$(cat "$prompt_path")"
  fi

  local cfg_exec_prompt=""
  local cfg_ai_enabled=""
  local cfg_developer_enabled=""
  local cfg_quiet=""
  local cfg_capture_enabled=""
  local cfg_install_path_prompt=""
  cfg_exec_prompt="$(config_value_scoped exec.prompt "base")"
  cfg_ai_enabled="$(config_value_scoped ai.enabled "false")"
  cfg_developer_enabled="$(config_value_scoped developer.enabled "false")"
  cfg_quiet="$(config_value_scoped quiet "false")"
  cfg_capture_enabled="$(config_value_scoped capture.enabled "false")"
  cfg_install_path_prompt="$(config_value_scoped install.path_prompt "true")"

  local config_local_contents="(none)"
  if [ -n "$local_config" ] && [ -f "$local_config" ]; then
    config_local_contents="$(cat "$local_config")"
  fi
  local config_global_contents="(none)"
  if [ -f "$CONFIG_FILE" ]; then
    config_global_contents="$(cat "$CONFIG_FILE")"
  fi

  detect_cli() {
    local name="$1"
    local path=""
    if command -v "$name" >/dev/null 2>&1; then
      path="$(command -v "$name")"
      printf "found (%s)" "$path"
    else
      printf "missing"
    fi
  }

  local normalized_prompt=""
  normalized_prompt="$(cat <<EOF
$prompt_body

---

This will generate a response based on the prompt above. Like advanced filtering

User request:
$user_prompt
EOF
)"

  if [ "$print_only" = "true" ]; then
    printf "%s\n" "$normalized_prompt"
    exit 0
  fi

  if [ "$cfg_ai_enabled" != "true" ]; then
    echo "AI integration disabled. Enable with: dev.kit config set --key ai.enabled true" >&2
    echo "Tip: use --print to view the normalized prompt without running codex." >&2
    exit 1
  fi

  if command -v codex >/dev/null 2>&1; then
    ensure_dev_kit_home
    local developer_enabled=""
    developer_enabled="$(config_value_scoped developer.enabled "false")"
    local log_dir="$DEV_KIT_HOME/exec"
    if [ "$developer_enabled" = "true" ] || [ "$prompt_key" = "developer" ] || [ "$prompt_key" = "dev" ]; then
      if [ -n "$repo_root" ]; then
        log_dir="$repo_root/.udx/dev.kit/logs"
      else
        log_dir="$DEV_KIT_HOME/logs"
      fi
    fi
    mkdir -p "$log_dir"
    local log_path="$log_dir/exec-$(date +%Y%m%d%H%M%S).log"
    local result_path
    result_path="$(mktemp)"

    print_section "dev.kit exec"
    print_check "prompt" "[ok]" "normalized ($prompt_path)"
    print_check "codex" "[ok]" "running"

    if [ "$stream_logs" = "true" ]; then
      if codex exec --output-last-message "$result_path" "$normalized_prompt" 2>&1 | tee "$log_path"; then
        print_check "codex" "[ok]" "log: $log_path"
      else
        local status=$?
        print_check "codex" "[warn]" "exit: $status (log: $log_path)"
        if [ "$show_log" = "true" ] && [ "$stream_logs" != "true" ]; then
          cat "$log_path"
        else
          echo "codex failed. Re-run with --show-log to see details." >&2
        fi
        rm -f "$result_path"
        exit "$status"
      fi
    elif codex exec --output-last-message "$result_path" "$normalized_prompt" >"$log_path" 2>&1; then
      print_check "codex" "[ok]" "log: $log_path"
    else
      local status=$?
      print_check "codex" "[warn]" "exit: $status (log: $log_path)"
      if [ "$show_log" = "true" ]; then
        cat "$log_path"
      else
        echo "codex failed. Re-run with --show-log to see details." >&2
      fi
      rm -f "$result_path"
      exit "$status"
    fi

    echo ""
    echo "Result:"
    if [ -s "$result_path" ]; then
      cat "$result_path"
    else
      echo "(no final response captured; see log: $log_path)"
    fi
    echo ""
    echo "Next: review the workflow output; refine the request and re-run if needed."
    rm -f "$result_path"
    if [ "$show_log" = "true" ] && [ "$stream_logs" != "true" ]; then
      echo ""
      echo "Full log:"
      cat "$log_path"
    fi
    exit 0
  fi

  echo "codex not found. Run with --print to copy the prompt manually." >&2
  exit 1
}
