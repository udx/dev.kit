#!/bin/bash

dev_kit_cmd_config() {
  shift || true
  ensure_dev_kit_home
  local sub="${1:-}"

  ensure_global_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
      if [ -f "$REPO_DIR/config/default.env" ]; then
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cp "$REPO_DIR/config/default.env" "$CONFIG_FILE"
      fi
    fi
  }

  scope_path() {
    local scope="$1"
    local variant="$2"
    local base=""
    case "$scope" in
      global)
        if [ -n "${DEV_KIT_STATE:-}" ] && [ -d "$DEV_KIT_STATE" ]; then
          base="$DEV_KIT_STATE"
        else
          base="$DEV_KIT_HOME"
        fi
        ;;
      repo)
        if command -v git >/dev/null 2>&1; then
          base="$(git rev-parse --show-toplevel 2>/dev/null)/.udx/dev.kit"
        fi
        ;;
      *)
        return 1
        ;;
    esac
    if [ -z "$base" ]; then
      return 1
    fi
    case "$variant" in
      show) echo "$base/config.env" ;;
      default) echo "$base/config.default.env" ;;
      min) echo "$base/config.min.env" ;;
      max) echo "$base/config.max.env" ;;
      custom) echo "$base/config.custom.env" ;;
      *) return 1 ;;
    esac
  }

  prompt_value() {
    local label="$1"
    local default="${2:-}"
    local input=""
    if [ -t 0 ]; then
      if [ -n "$default" ]; then
        printf "%s [%s]: " "$label" "$default"
      else
        printf "%s: " "$label"
      fi
      read -r input || true
    fi
    if [ -n "$input" ]; then
      printf "%s" "$input"
    else
      printf "%s" "$default"
    fi
  }

  parse_key_flag() {
    local key=""
    local args=("$@")
    local i=0
    while [ $i -lt ${#args[@]} ]; do
      case "${args[$i]}" in
        --key=*)
          key="${args[$i]#--key=}"
          ;;
        --key)
          if [ $((i+1)) -lt ${#args[@]} ]; then
            key="${args[$((i+1))]}"
            i=$((i+1))
          fi
          ;;
      esac
      i=$((i+1))
    done
    printf "%s" "$key"
  }

  parse_force_flag() {
    local force="false"
    local args=("$@")
    local i=0
    while [ $i -lt ${#args[@]} ]; do
      case "${args[$i]}" in
        --force) force="true" ;;
      esac
      i=$((i+1))
    done
    printf "%s" "$force"
  }

  parse_developer_flag() {
    local developer="false"
    local args=("$@")
    local i=0
    while [ $i -lt ${#args[@]} ]; do
      case "${args[$i]}" in
        --developer) developer="true" ;;
      esac
      i=$((i+1))
    done
    printf "%s" "$developer"
  }

  update_config_value() {
    local key="$1"
    local value="$2"
    local path="${3:-$CONFIG_FILE}"
    local mode="${4:-set}"
    local tmp=""
    tmp="$(mktemp)"
    if [ -f "$path" ]; then
      awk -v k="$key" -v v="$value" -v mode="$mode" '
        BEGIN { found=0 }
        {
          if ($0 ~ "^[[:space:]]*"k"[[:space:]]*=") {
            found=1
            if (mode=="reset" && v=="") { next }
            print k" = "v
            next
          }
          print
        }
        END {
          if (!found && v!="") {
            print k" = "v
          }
        }
      ' "$path" > "$tmp"
    else
      if [ -n "$value" ]; then
        printf "%s = %s\n" "$key" "$value" > "$tmp"
      else
        : > "$tmp"
      fi
    fi
    mkdir -p "$(dirname "$path")"
    mv "$tmp" "$path"
    if [ -n "$value" ]; then
      echo "Set: $key = $value"
    else
      echo "Reset: $key"
    fi
  }

  confirm_action() {
    local msg="$1"
    if [ ! -t 0 ]; then
      echo "Non-interactive. Aborted."
      exit 1
    fi
    printf "%s [y/N] " "$msg"
    read -r answer || true
    case "$answer" in
      y|Y|yes|YES) ;;
      *) echo "Aborted."; exit 1 ;;
    esac
  }

  detect_cli() {
    local name="$1"
    local path=""
    if command -v "$name" >/dev/null 2>&1; then
      path="$(command -v "$name")"
      printf "%-10s %s\n" "$name" "found ($path)"
    else
      printf "%-10s %s\n" "$name" "missing"
    fi
  }

  case "$sub" in
    global|repo)
      local action="${2:---show}"
      local path=""
      case "$action" in
        --show|show) path="$(scope_path "$sub" show)" ;;
        --default|default) path="$(scope_path "$sub" default)" ;;
        --min|min) path="$(scope_path "$sub" min)" ;;
        --max|max) path="$(scope_path "$sub" max)" ;;
        --custom|custom) path="$(scope_path "$sub" custom)" ;;
        *)
          echo "Unknown config action: $action" >&2
          exit 1
          ;;
      esac
      if [ -z "${path:-}" ]; then
        echo "Config scope not available: $sub" >&2
        exit 1
      fi
      if [ "$sub" = "global" ]; then
        ensure_global_config
      fi
      if [ "$action" = "--custom" ] || [ "$action" = "custom" ]; then
        local schema_artifact="$REPO_DIR/docs/artifacts/modules/config/local-schema.json"
        local schema_source="$REPO_DIR/docs/src/configs/tooling/local/config-schema.json"
        local schema_path="$schema_artifact"
        if [ ! -f "$schema_path" ]; then
          schema_path="$schema_source"
        fi
        if [ ! -f "$schema_path" ]; then
          echo "Config schema not found: $schema_artifact or $schema_source" >&2
          exit 1
        fi
        if ! command -v jq >/dev/null 2>&1; then
          echo "jq is required for --custom config generation." >&2
          exit 1
        fi
        mkdir -p "$(dirname "$path")"
        : > "$path"
        while IFS= read -r field; do
          local field_json=""
          local key=""
          local default=""
          local desc=""
          local options=""
          field_json="$(printf "%s" "$field" | base64 --decode)"
          key="$(printf "%s" "$field_json" | jq -r '.key // empty')"
          default="$(printf "%s" "$field_json" | jq -r '.default // ""')"
          desc="$(printf "%s" "$field_json" | jq -r '.description // ""')"
          options="$(printf "%s" "$field_json" | jq -r '.options // [] | join(\", \")')"
          if [ -n "$desc" ]; then
            echo ""
            echo "$desc"
          fi
          if [ -n "$options" ]; then
            echo "options: $options"
          fi
          local value=""
          if [ -t 0 ]; then
            printf "%s [%s]: " "$key" "$default"
            read -r value || true
          fi
          if [ -z "$value" ]; then
            value="$default"
          fi
          if [ -n "$key" ]; then
            printf "%s = %s\n" "$key" "$value" >> "$path"
          fi
        done < <(jq -r '.fields[] | @base64' "$schema_path")
        echo "Saved: $path"
        exit 0
      fi
      if [ -f "$path" ]; then
        cat "$path"
        exit 0
      fi
      if [ "$sub" = "repo" ]; then
        ensure_global_config
        if [ -f "$CONFIG_FILE" ]; then
          cat "$CONFIG_FILE"
          exit 0
        fi
      fi
      echo "Config file not found: $path" >&2
      exit 1
      ;;
    show|"")
      local key
      key="$(parse_key_flag "$@")"
      if [ -n "$key" ]; then
        local val=""
        val="$(config_value "$CONFIG_FILE" "$key" "")"
        if [ -n "$val" ]; then
          echo "$key = $val"
        else
          echo "Key not found: $key" >&2
          exit 1
        fi
        exit 0
      fi
      if [ -f "$CONFIG_FILE" ]; then
        cat "$CONFIG_FILE"
      else
        echo "No config found: $CONFIG_FILE"
      fi
      echo ""
      echo "Detected CLIs (read-only):"
      detect_cli git
      detect_cli gh
      detect_cli docker
      detect_cli npm
      detect_cli codex
      detect_cli claude
      detect_cli gemini
      ;;
    reset)
      local force="false"
      force="$(parse_force_flag "$@")"
      local key=""
      key="$(parse_key_flag "$@")"
      if [ -n "$key" ]; then
        if [ "$force" != "true" ]; then
          confirm_action "Reset $key to default?"
        fi
        local default_val=""
        default_val="$(config_value "$REPO_DIR/config/default.env" "$key" "")"
        update_config_value "$key" "$default_val" "$CONFIG_FILE" "reset"
        exit 0
      fi
      if [ ! -f "$REPO_DIR/config/default.env" ]; then
        echo "Missing default config: $REPO_DIR/config/default.env"
        exit 1
      fi
      if [ -t 0 ] && [ "$force" != "true" ]; then
        confirm_action "Reset config to defaults?"
      fi
      cp "$REPO_DIR/config/default.env" "$CONFIG_FILE"
      cp "$REPO_DIR/config/default.env" "$DEV_KIT_HOME/config.env"
      echo "Reset: $CONFIG_FILE"
      ;;
  set)
      local force="false"
      force="$(parse_force_flag "$@")"
      local developer="false"
      developer="$(parse_developer_flag "$@")"
      local key=""
      local value=""
      key="$(parse_key_flag "$@")"
      if [ "$developer" = "true" ]; then
        update_config_value "exec.prompt" "developer" "$CONFIG_FILE" "set"
        update_config_value "developer.enabled" "true" "$CONFIG_FILE" "set"
        exit 0
      fi
      if [ -n "$key" ]; then
        value="${3:-}"
      else
        key="${2:-}"
        value="${3:-}"
      fi
      if [ -n "$key" ] && [ "${2:-}" = "--key" ] && [ -n "${3:-}" ]; then
        if [ "${4:-}" = "--value" ] && [ -n "${5:-}" ]; then
          value="${5:-}"
        else
          value="${4:-}"
        fi
      fi
      if [ -z "$key" ]; then
        if [ -t 0 ] && [ "$force" != "true" ]; then
          key="$(prompt_value "key" "")"
        else
          echo "Missing --key in non-interactive mode" >&2
          exit 1
        fi
      fi
      if [ -z "$value" ]; then
        if [ -t 0 ] && [ "$force" != "true" ]; then
          value="$(prompt_value "value" "")"
        else
          echo "Missing value in non-interactive mode" >&2
          exit 1
        fi
      fi
      if [ -z "$key" ] || [ -z "$value" ]; then
        echo "Usage: dev.kit config set --key <key> <value>" >&2
        exit 1
      fi
      update_config_value "$key" "$value" "$CONFIG_FILE" "set"
      if [ "$key" = "state_path" ]; then
        update_config_value "$key" "$value" "$DEV_KIT_HOME/config.env" "set"
      fi
      ;;
    -h|--help)
      cat <<'CONFIG_USAGE'
Usage: dev.kit config <command>

Commands:
  show           Print current config
  reset          Reset config to defaults (prompts)
  set            Set a config key/value (or --developer)
  global         Global config (use --show|--default|--min|--max|--custom)
  repo           Repo config (use --show|--default|--min|--max|--custom)

Options:
  --key <key>    Target a specific config key
  --value <val>  Set a config value when using --key
  --force        Skip confirmation prompts
  --developer    Enable developer mode (sets exec.prompt + developer.enabled)
CONFIG_USAGE
      ;;
    *)
      echo "Unknown config command: $sub" >&2
      exit 1
      ;;
  esac
}
