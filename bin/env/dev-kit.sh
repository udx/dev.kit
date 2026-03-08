#!/bin/bash

# dev.kit session init
if [ -n "${DEV_KIT_DISABLE:-}" ]; then
  return 0
fi

export DEV_KIT_HOME="${DEV_KIT_HOME:-$HOME/.udx/dev.kit}"

dev_kit_bootstrap_state_path() {
  local path=""
  if [ -f "$DEV_KIT_HOME/config.env" ]; then
    path="$(awk -F= '
      $1 ~ "^[[:space:]]*state_path[[:space:]]*$" {
        gsub(/[[:space:]]/,"",$2);
        print $2;
        exit
      }
    ' "$DEV_KIT_HOME/config.env")"
  fi
  printf "%s" "$path"
}

dev_kit_expand_path() {
  local val="$1"
  if [[ "$val" == "~/"* ]]; then
    echo "$HOME/${val:2}"
    return
  fi
  if [[ "$val" == /* ]]; then
    echo "$val"
    return
  fi
  if [ -n "$val" ]; then
    echo "$DEV_KIT_HOME/$val"
    return
  fi
  echo ""
}

bootstrap_state_path="$(dev_kit_bootstrap_state_path)"
bootstrap_state_path="$(dev_kit_expand_path "$bootstrap_state_path")"

export DEV_KIT_STATE="${DEV_KIT_STATE:-${bootstrap_state_path:-$DEV_KIT_HOME/state}}"
export DEV_KIT_SOURCE="${DEV_KIT_SOURCE:-$DEV_KIT_HOME/source}"
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
      echo "  run: dev.kit skills run \"...\""
      echo "  config: dev.kit config show"
    fi
  fi
}

dev_kit_auto_sync() {
  local auto_sync; auto_sync="$(dev_kit_config_bool ai.auto_sync false)"
  local ai_enabled; ai_enabled="$(dev_kit_config_bool ai.enabled false)"
  
  if [ "$auto_sync" = "true" ] && [ "$ai_enabled" = "true" ]; then
    (dev.kit ai sync >/dev/null 2>&1 &)
  fi
}

dev_kit_banner_prompt() {
  if [ -z "${DEV_KIT_BANNER_PENDING:-}" ]; then
    return 0
  fi
  DEV_KIT_BANNER_PENDING=""
  dev_kit_banner
  dev_kit_auto_sync
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

if [ -n "${PROMPT_COMMAND:-}" ]; then
  PROMPT_COMMAND="dev_kit_banner_prompt; ${PROMPT_COMMAND}"
else
  PROMPT_COMMAND="dev_kit_banner_prompt"
fi
