#!/bin/bash

# dev.kit session init
if [ -n "${DEV_KIT_DISABLE:-}" ]; then
  return 0
fi

export DEV_KIT_HOME="${DEV_KIT_HOME:-$HOME/.udx/dev.kit}"
export DEV_KIT_SOURCE="${DEV_KIT_SOURCE:-$DEV_KIT_HOME/source}"
export DEV_KIT_STATE="${DEV_KIT_STATE:-$DEV_KIT_HOME/state}"
if [ ! -d "$DEV_KIT_SOURCE" ]; then
  DEV_KIT_SOURCE="$DEV_KIT_HOME"
fi
if [ ! -d "$DEV_KIT_STATE" ]; then
  DEV_KIT_STATE="$DEV_KIT_HOME"
fi
export DEV_KIT_CONFIG="${DEV_KIT_CONFIG:-$DEV_KIT_STATE/config.env}"
if [ ! -f "$DEV_KIT_CONFIG" ] && [ -f "$DEV_KIT_HOME/config.env" ]; then
  export DEV_KIT_CONFIG="$DEV_KIT_HOME/config.env"
fi

DEV_KIT_ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_KIT_UI_LIB="${DEV_KIT_UI_LIB:-$DEV_KIT_SOURCE/lib/ui.sh}"
if [ ! -f "$DEV_KIT_UI_LIB" ]; then
  DEV_KIT_UI_LIB="$DEV_KIT_ENV_DIR/../../lib/ui.sh"
fi
if [ -f "$DEV_KIT_UI_LIB" ]; then
  # shellcheck disable=SC1090
  . "$DEV_KIT_UI_LIB"
fi

dev_kit_config_value() {
  local key="$1"
  local default="${2:-}"
  local val=""
  if [ -f "$DEV_KIT_CONFIG" ]; then
    val="$(awk -F= -v k="$key" '
      $1 ~ "^[[:space:]]*"k"[[:space:]]*$" {
        sub(/^[[:space:]]*/,"",$2);
        sub(/[[:space:]]*$/,"",$2);
        print $2;
        exit
      }
    ' "$DEV_KIT_CONFIG")"
  fi
  if [ -n "$val" ]; then
    echo "$val"
  else
    echo "$default"
  fi
}

dev_kit_config_bool() {
  local key="$1"
  local default="${2:-false}"
  local val
  val="$(dev_kit_config_value "$key" "$default")"
  case "$val" in
    true|false) echo "$val" ;;
    *) echo "$default" ;;
  esac
}

dev_kit_banner() {
  local quiet
  quiet="$(dev_kit_config_bool quiet false)"
  case "$-" in
    *i*) ;;
    *) return 0 ;;
  esac
  if [ "$quiet" != "true" ] && [ -z "${DEV_KIT_BANNER_SHOWN_LOCAL:-}" ]; then
    DEV_KIT_BANNER_SHOWN_LOCAL=1
    if command -v ui_banner >/dev/null 2>&1; then
      ui_banner "dev.kit"
    else
      echo ""
      echo "dev.kit: ready"
      echo "  run: dev.kit exec \"...\""
      echo "  config: dev.kit config show"
    fi
  fi
}

dev_kit_banner_prompt() {
  if [ -z "${DEV_KIT_BANNER_PENDING:-}" ]; then
    return 0
  fi
  DEV_KIT_BANNER_PENDING=""
  dev_kit_banner
}

dev_kit_capture_repo_root() {
  if command -v git >/dev/null 2>&1; then
    git rev-parse --show-toplevel 2>/dev/null || true
  fi
}

dev_kit_capture_mode() {
  local mode=""
  mode="$(dev_kit_config_value capture.mode "")"
  if [ -n "$mode" ]; then
    echo "$mode"
    return
  fi
  local enabled
  enabled="$(dev_kit_config_bool capture.enabled true)"
  if [ "$enabled" = "true" ]; then
    echo "global"
  else
    echo "off"
  fi
}

dev_kit_capture_repo_id() {
  local root=""
  root="$(dev_kit_capture_repo_root)"
  if [ -z "$root" ]; then
    root="$PWD"
  fi
  if command -v shasum >/dev/null 2>&1; then
    printf "%s" "$root" | shasum -a 256 | awk '{print $1}'
  else
    printf "%s" "$root" | cksum | awk '{print $1}'
  fi
}

dev_kit_capture_dir() {
  local mode base repo_id
  mode="$(dev_kit_capture_mode)"
  case "$mode" in
    off) return 1 ;;
    repo)
      base="$(dev_kit_capture_repo_root)"
      if [ -z "$base" ]; then
        base="$PWD"
      fi
      echo "$base/.udx/dev.kit/capture"
      ;;
    global|*)
      base="$(dev_kit_config_value capture.dir "")"
      if [ -z "$base" ]; then
        base="$DEV_KIT_STATE/capture"
      elif [[ "$base" == "~/"* ]]; then
        base="$HOME/${base:2}"
      elif [[ "$base" != /* ]]; then
        base="$DEV_KIT_STATE/$base"
      fi
      repo_id="$(dev_kit_capture_repo_id)"
      echo "$base/$repo_id"
      ;;
  esac
}

dev_kit_capture_enabled() {
  local mode=""
  mode="$(dev_kit_capture_mode)"
  [ "$mode" != "off" ]
}

dev_kit_capture_cleanup() {
  if ! dev_kit_capture_enabled; then
    return 0
  fi
  local dir
  dir="$(dev_kit_capture_dir)" || return 0
  if [ -d "$dir" ]; then
    rm -f "$dir/last-input.log" "$dir/last-output.log" "$dir/capture.log"
    rmdir "$dir" 2>/dev/null || true
  fi
}

dev_kit_capture_log() {
  if ! dev_kit_capture_enabled; then
    return 0
  fi
  local cmd line
  line="$(history 1 | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//')"
  line="$(printf "%s" "$line" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+//')"
  cmd="${line# }"
  if [[ "$cmd" != dev.kit\ * && "$cmd" != dev.kit ]]; then
    dev_kit_capture_cleanup
    return 0
  fi
}

if [ -z "${DEV_KIT_BANNER_SHOWN_LOCAL:-}" ]; then
  DEV_KIT_BANNER_PENDING=1
fi

if [ -n "${BASH_VERSION:-}" ] && [ -f "$DEV_KIT_SOURCE/completions/dev.kit.bash" ]; then
  # shellcheck disable=SC1090
  . "$DEV_KIT_SOURCE/completions/dev.kit.bash"
elif [ -n "${ZSH_VERSION:-}" ] && [ -f "$DEV_KIT_SOURCE/completions/_dev.kit" ]; then
  # shellcheck disable=SC1090
  . "$DEV_KIT_SOURCE/completions/_dev.kit"
fi

if [ -n "${DEV_KIT_CAPTURE_HOOKED:-}" ]; then
  return 0
fi

DEV_KIT_CAPTURE_HOOKED=1
if [ -n "${PROMPT_COMMAND:-}" ]; then
  PROMPT_COMMAND="dev_kit_banner_prompt; dev_kit_capture_log; ${PROMPT_COMMAND}"
else
  PROMPT_COMMAND="dev_kit_banner_prompt; dev_kit_capture_log"
fi
