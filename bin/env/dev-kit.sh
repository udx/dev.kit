#!/bin/bash

# dev.kit session init
if [ -n "${DEV_KIT_DISABLE:-}" ]; then
  return 0
fi

export DEV_KIT_HOME="${DEV_KIT_HOME:-$HOME/.udx/dev.kit}"
export DEV_KIT_CONFIG="$DEV_KIT_HOME/config.env"
export DEV_KIT_CAPTURE_ENV="$DEV_KIT_HOME/capture.env"
export DEV_KIT_CAPTURE_STATE="$DEV_KIT_HOME/capture.state"
export DEV_KIT_CAPTURE_LOG="$DEV_KIT_HOME/capture.log"

DEV_KIT_CONTEXT_LIB="${DEV_KIT_CONTEXT_LIB:-$DEV_KIT_HOME/lib/context.sh}"
if [ -f "$DEV_KIT_CONTEXT_LIB" ]; then
  # shellcheck disable=SC1090
  . "$DEV_KIT_CONTEXT_LIB"
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

dev_kit_capture_repo_root() {
  if command -v git >/dev/null 2>&1; then
    git rev-parse --show-toplevel 2>/dev/null || true
  fi
}

dev_kit_capture_repo_env() {
  local root
  root="$(dev_kit_capture_repo_root)"
  if [ -n "$root" ]; then
    echo "$root/.udx/dev.kit/capture/capture.env"
  fi
}

dev_kit_capture_repo_state() {
  local root
  root="$(dev_kit_capture_repo_root)"
  if [ -n "$root" ]; then
    echo "$root/.udx/dev.kit/capture/capture.state"
  fi
}

dev_kit_capture_repo_log() {
  local root
  root="$(dev_kit_capture_repo_root)"
  if [ -n "$root" ]; then
    echo "$root/.udx/dev.kit/capture/capture.log"
  fi
}

dev_kit_capture_enabled() {
  local enabled
  enabled="$(dev_kit_config_bool capture.enabled false)"
  local repo_env
  repo_env="$(dev_kit_capture_repo_env)"
  if [ -n "$repo_env" ] && [ -f "$repo_env" ]; then
    # shellcheck disable=SC1090
    . "$repo_env"
  elif [ -f "$DEV_KIT_CAPTURE_ENV" ]; then
    # shellcheck disable=SC1090
    . "$DEV_KIT_CAPTURE_ENV"
  fi
  if [ -n "${DEV_KIT_CAPTURE:-}" ]; then
    [ "${DEV_KIT_CAPTURE}" = "1" ] && return 0 || return 1
  fi
  [ "$enabled" = "true" ]
}

dev_kit_state_get() {
  local key="$1"
  local default="${2:-}"
  local val=""
  local state_file repo_state
  repo_state="$(dev_kit_capture_repo_state)"
  if [ -n "$repo_state" ] && [ -f "$repo_state" ]; then
    state_file="$repo_state"
  else
    state_file="$DEV_KIT_CAPTURE_STATE"
  fi
  if [ -f "$state_file" ]; then
    val="$(awk -F= -v k="$key" '
      $1 == k { print $2; exit }
    ' "$state_file")"
  fi
  if [ -n "$val" ]; then
    echo "$val"
  else
    echo "$default"
  fi
}

dev_kit_state_set() {
  local key="$1"
  local value="$2"
  local tmp
  local state_file repo_state
  repo_state="$(dev_kit_capture_repo_state)"
  if [ -n "$repo_state" ]; then
    state_file="$repo_state"
  else
    state_file="$DEV_KIT_CAPTURE_STATE"
  fi
  tmp="$(mktemp)"
  if [ -f "$state_file" ]; then
    awk -F= -v k="$key" '
      $1 != k { print $0 }
    ' "$state_file" > "$tmp"
  fi
  printf "%s=%s\n" "$key" "$value" >> "$tmp"
  mkdir -p "$(dirname "$state_file")"
  mv "$tmp" "$state_file"
}

dev_kit_capture_prune() {
  local file="$1"
  local days="$2"
  if [ -z "$days" ] || [ "$days" = "0" ] || [ ! -f "$file" ]; then
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$file" "$days" <<'PY'
import datetime,sys

path = sys.argv[1]
days = int(sys.argv[2])
cutoff = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=days)

def parse_ts(line):
  try:
    ts = line.split(" | ", 1)[0]
    return datetime.datetime.fromisoformat(ts)
  except Exception:
    return None

out = []
with open(path, "r", encoding="utf-8") as f:
  for line in f:
    ts = parse_ts(line)
    if ts is None or ts >= cutoff:
      out.append(line)

with open(path, "w", encoding="utf-8") as f:
  f.writelines(out)
PY
  fi
}

dev_kit_capture_log() {
  if ! dev_kit_capture_enabled; then
    return 0
  fi
  local auto_clean auto_clean_iteration cleaned header_written ttl_days
  auto_clean="$(dev_kit_config_bool capture.auto_clean false)"
  auto_clean_iteration="$(dev_kit_config_bool capture.auto_clean_iteration false)"
  local root cmd line file
  root="$(dev_kit_capture_repo_root)"
  if [ -n "$root" ]; then
    file="${DEV_KIT_CAPTURE_FILE:-$root/.udx/dev.kit/capture/capture.log}"
    ttl_days="$(dev_kit_config_value capture.ttl_days_repo 3)"
  else
    file="${DEV_KIT_CAPTURE_FILE:-$DEV_KIT_CAPTURE_LOG}"
    ttl_days="$(dev_kit_config_value capture.ttl_days_global 3)"
  fi
  mkdir -p "$(dirname "$file")"
  line="$(history 1 | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//')"
  line="$(printf "%s" "$line" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+//')"
  cmd="${line# }"
  if [[ "$cmd" != dev.kit\ * && "$cmd" != dev.kit ]]; then
    return 0
  fi
  if [ -z "$cmd" ]; then
    return 0
  fi
  if [ "${DEV_KIT_CAPTURE_LAST:-}" = "$cmd" ]; then
    return 0
  fi
  DEV_KIT_CAPTURE_LAST="$cmd"
  dev_kit_capture_prune "$file" "$ttl_days"
  cleaned="$(dev_kit_state_get cleaned 0)"
  header_written="$(dev_kit_state_get header_written 0)"
  if [ "$auto_clean_iteration" = "true" ]; then
    : > "$file"
    dev_kit_state_set cleaned 1
    header_written="0"
  elif [ "$auto_clean" = "true" ] && [ "$cleaned" != "1" ]; then
    : > "$file"
    dev_kit_state_set cleaned 1
    header_written="0"
  fi
  if [ "$header_written" != "1" ]; then
    printf '%s\n' "---- dev.kit capture ${DEV_KIT_CAPTURE_SESSION:-session} (${DEV_KIT_CAPTURE_STARTED_AT:-$(date -Iseconds)}) ----" >> "$file"
    dev_kit_state_set header_written 1
  fi
  printf "%s | %s | %s\n" "$(date -Iseconds)" "$PWD" "$cmd" >> "$file"
  if command -v context_register >/dev/null 2>&1; then
    context_register "capture" >/dev/null 2>&1 || true
  fi
}

if command -v dev.kit >/dev/null 2>&1; then
  dev.kit init >/dev/null 2>&1 || true
fi

if [ -n "${BASH_VERSION:-}" ] && [ -f "$DEV_KIT_HOME/completions/dev.kit.bash" ]; then
  # shellcheck disable=SC1090
  . "$DEV_KIT_HOME/completions/dev.kit.bash"
elif [ -n "${ZSH_VERSION:-}" ] && [ -f "$DEV_KIT_HOME/completions/_dev.kit" ]; then
  # shellcheck disable=SC1090
  . "$DEV_KIT_HOME/completions/_dev.kit"
fi

if [ -n "${DEV_KIT_CAPTURE_HOOKED:-}" ]; then
  return 0
fi

DEV_KIT_CAPTURE_HOOKED=1
if [ -n "${PROMPT_COMMAND:-}" ]; then
  PROMPT_COMMAND="dev_kit_capture_log; ${PROMPT_COMMAND}"
else
  PROMPT_COMMAND="dev_kit_capture_log"
fi
