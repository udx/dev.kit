#!/bin/bash

dev_kit_cmd_exec() {
  shift || true
  local print_only="false"
  local show_log="false"
  local stream_logs="false"
  local stream_logs_set="false"
  local skip_git_repo_check="false"
  local reset_context="false"
  local compact_context="false"
  local no_context="false"

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
        stream_logs_set="true"
        shift
        ;;
      --no-stream|--quiet)
        stream_logs="false"
        stream_logs_set="true"
        shift
        ;;
      --reset-context)
        reset_context="true"
        shift
        ;;
      --reset)
        reset_context="true"
        shift
        ;;
      --compact-context)
        compact_context="true"
        shift
        ;;
      --compact)
        compact_context="true"
        shift
        ;;
      --no-context)
        no_context="true"
        shift
        ;;
      -h|--help)
        cat <<'EXEC_USAGE'
Usage: dev.kit exec [--print] [--show-log] [--skip-git-repo-check] [--stream|--no-stream] [--reset|--reset-context] [--compact|--compact-context] [--no-context] "<request>"

Options:
  --print, --dry-run  Print the normalized prompt without running codex
  --show-log          Print full codex exec logs after completion
  --skip-git-repo-check  Allow running Codex outside a Git repository
  --stream            Stream codex exec logs to stdout
  --no-stream, --quiet  Suppress streaming logs (log file only)
  --reset, --reset-context     Clear stored context before running
  --compact, --compact-context Compact stored context before running
  --no-context         Run without reading or writing stored context
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
    prompt_key="ai"
  fi

  local context_path=""
  local context_text=""
  if [ "$no_context" != "true" ] && context_enabled; then
    context_path="$(context_file || true)"
    if [ -n "$context_path" ]; then
      mkdir -p "$(dirname "$context_path")"
      context_compact_file "$context_path" || true
      if [ "$reset_context" = "true" ]; then
        : > "$context_path"
      fi
      if [ "$compact_context" = "true" ]; then
        context_compact_file "$context_path" || true
      fi
      if [ -f "$context_path" ] && [ -s "$context_path" ]; then
        local max_bytes=""
        max_bytes="$(context_max_bytes)"
        if [ -n "$max_bytes" ]; then
          context_text="$(tail -c "$max_bytes" "$context_path")"
        else
          context_text="$(cat "$context_path")"
        fi
      fi
    fi
  fi

  DEV_KIT_PROMPT_CONTEXT="$context_text"
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
  local cfg_exec_stream=""
  cfg_exec_prompt="$(config_value_scoped exec.prompt "ai")"
  cfg_ai_enabled="$(config_value_scoped ai.enabled "false")"
  cfg_developer_enabled="$(config_value_scoped developer.enabled "false")"
  cfg_quiet="$(config_value_scoped quiet "false")"
  cfg_capture_enabled="$(config_value_scoped capture.enabled "false")"
  cfg_install_path_prompt="$(config_value_scoped install.path_prompt "true")"
  cfg_exec_stream="$(config_value_scoped exec.stream "false")"

  if [ "$stream_logs_set" = "false" ]; then
    if [ "$cfg_exec_stream" = "true" ]; then
      stream_logs="true"
    else
      stream_logs="false"
    fi
  fi

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
    printf "%s\n" "$normalized_prompt"
    echo "AI integration disabled. Enable with: dev.kit config set --key ai.enabled true" >&2
    echo "Prompt printed for manual use (Codex session, codex exec, or other AI/API/MCP)." >&2
    exit 0
  fi

  if command -v codex >/dev/null 2>&1; then
    ensure_dev_kit_home
    local repo_id=""
    repo_id="$(capture_repo_id || true)"
    local log_dir="$DEV_KIT_STATE/codex/logs"
    if [ -n "$repo_id" ]; then
      log_dir="$log_dir/$repo_id"
    fi
    mkdir -p "$log_dir"
    local run_id=""
    run_id="$(date +%Y%m%d%H%M%S)-$$"
    local log_path="$log_dir/exec-$run_id.log"
    local prompt_path="$log_dir/exec-$run_id.prompt.md"
    local request_path="$log_dir/exec-$run_id.request.txt"
    local result_out_path="$log_dir/exec-$run_id.result.md"
    local meta_path="$log_dir/exec-$run_id.meta"
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

    if [ "$cfg_quiet" != "true" ] && [ "$stream_logs" = "true" ]; then
      print_section "dev.kit exec"
      print_check "prompt" "[ok]" "normalized ($prompt_paths_display)"
      print_check "codex" "[ok]" "running"
    fi

    local codex_skip_arg=""
    if [ "$skip_git_repo_check" = "true" ]; then
      codex_skip_arg="--skip-git-repo-check"
    fi

    printf "%s\n" "$user_prompt" > "$request_path"
    printf "%s\n" "$normalized_prompt" > "$prompt_path"

    write_exec_meta() {
      local status="$1"
      local exit_code="$2"
      cat > "$meta_path" <<EOF
timestamp: $(date -Iseconds)
repo_root: ${repo_root:-}
repo_id: ${repo_id:-}
request_path: $request_path
prompt_key: $prompt_key
prompt_paths: $prompt_paths_display
prompt_path: $prompt_path
result_path: $result_out_path
raw_log_path: $log_path
status: $status
exit_code: $exit_code
EOF
    }
    write_exec_meta "running" "0"

    if [ "$stream_logs" = "true" ]; then
      if codex exec ${codex_skip_arg:+"$codex_skip_arg"} --output-last-message "$result_path" "$normalized_prompt" 2>&1 | tee "$log_path"; then
        if [ "$cfg_quiet" != "true" ] && [ "$stream_logs" = "true" ]; then
          print_check "codex" "[ok]" "log: $log_path"
        fi
        write_exec_meta "ok" "0"
      else
        local status=$?
        if [ "$cfg_quiet" != "true" ] && [ "$stream_logs" = "true" ]; then
          print_check "codex" "[warn]" "exit: $status (log: $log_path)"
        fi
        write_exec_meta "warn" "$status"
        if [ "$show_log" = "true" ] && [ "$stream_logs" != "true" ]; then
          cat "$log_path"
        else
          echo "codex failed. Re-run with --show-log to see details." >&2
        fi
        rm -f "$result_path"
        exit "$status"
      fi
    elif codex exec ${codex_skip_arg:+"$codex_skip_arg"} --output-last-message "$result_path" "$normalized_prompt" >"$log_path" 2>&1; then
      if [ "$cfg_quiet" != "true" ] && [ "$stream_logs" = "true" ]; then
        print_check "codex" "[ok]" "log: $log_path"
      fi
      write_exec_meta "ok" "0"
    else
      local status=$?
      if [ "$cfg_quiet" != "true" ] && [ "$stream_logs" = "true" ]; then
        print_check "codex" "[warn]" "exit: $status (log: $log_path)"
      fi
      write_exec_meta "warn" "$status"
      if [ "$show_log" = "true" ]; then
        cat "$log_path"
      else
        echo "codex failed. Re-run with --show-log to see details." >&2
      fi
      rm -f "$result_path"
      exit "$status"
    fi

    if [ "$cfg_quiet" != "true" ] && [ "$stream_logs" = "true" ]; then
      echo ""
      echo "Result:"
    fi
    if [ -s "$result_path" ]; then
      cat "$result_path"
      cp "$result_path" "$result_out_path"
      if [ "$no_context" != "true" ] && context_enabled && [ -n "$context_path" ]; then
        mkdir -p "$(dirname "$context_path")"
        {
          echo ""
          echo "-----"
          echo "timestamp: $(date -Iseconds)"
          echo "request:"
          printf "%s\n" "$user_prompt"
          echo "response:"
          cat "$result_path"
        } >> "$context_path"
        context_compact_file "$context_path" || true
      fi
    else
      echo "(no final response captured; see log: $log_path)"
    fi
    if [ "$cfg_quiet" != "true" ] && [ "$stream_logs" = "true" ]; then
      echo ""
    fi
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
