#!/bin/bash

dev_kit_cmd_exec() {
  shift || true
  local print_only="false"
  local show_log="false"
  local stream_logs="true"
  local skip_git_repo_check="false"

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      --print|--dry-run)
        print_only="true"
        shift
        ;;
      --show-log)
        show_log="true"
        shift
        ;;
      --skip-git-repo-check)
        skip_git_repo_check="true"
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
Usage: dev.kit exec [--print] [--show-log] [--skip-git-repo-check] [--stream|--no-stream] "<request>"

Options:
  --print, --dry-run  Print the normalized prompt without running codex
  --show-log          Print full codex exec logs after completion
  --skip-git-repo-check  Allow running Codex outside a Git repository
  --stream            Stream codex exec logs to stdout (default)
  --no-stream, --quiet  Suppress streaming logs (log file only)
EXEC_USAGE
        exit 0
        ;;
      --*)
        echo "Unknown option: ${1:-}" >&2
        exit 1
        ;;
      *)
        break
        ;;
    esac
  done

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

  dev_kit_prompt_build "$prompt_key" "$user_prompt"

  local prompt_body=""
  prompt_body="$DEV_KIT_PROMPT_BODY"
  local prompt_paths=()
  prompt_paths=("${DEV_KIT_PROMPT_PATHS[@]}")

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
  normalized_prompt="$prompt_body"

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
    local log_dir="$DEV_KIT_STATE/exec"
    if [ "$developer_enabled" = "true" ] || [ "$prompt_key" = "developer" ] || [ "$prompt_key" = "dev" ]; then
      if [ -n "$repo_root" ]; then
        log_dir="$repo_root/.udx/dev.kit/logs"
      else
        log_dir="$DEV_KIT_STATE/logs"
      fi
    fi
    mkdir -p "$log_dir"
    local log_path="$log_dir/exec-$(date +%Y%m%d%H%M%S).log"
    local result_path
    result_path="$(mktemp)"
    local prompt_paths_display="(none)"
    if [ "${#prompt_paths[@]}" -gt 0 ]; then
      prompt_paths_display="${prompt_paths[0]}"
      local idx=1
      while [ "$idx" -lt "${#prompt_paths[@]}" ]; do
        prompt_paths_display="${prompt_paths_display}, ${prompt_paths[$idx]}"
        idx=$((idx + 1))
      done
    fi

    print_section "dev.kit exec"
    print_check "prompt" "[ok]" "normalized ($prompt_paths_display)"
    print_check "codex" "[ok]" "running"

    local codex_skip_arg=""
    if [ "$skip_git_repo_check" = "true" ]; then
      codex_skip_arg="--skip-git-repo-check"
    fi
    if [ "$stream_logs" = "true" ]; then
      if codex exec ${codex_skip_arg:+"$codex_skip_arg"} --output-last-message "$result_path" "$normalized_prompt" 2>&1 | tee "$log_path"; then
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
    elif codex exec ${codex_skip_arg:+"$codex_skip_arg"} --output-last-message "$result_path" "$normalized_prompt" >"$log_path" 2>&1; then
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
