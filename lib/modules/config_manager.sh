#!/usr/bin/env bash

# @description: High-fidelity configuration management and environment orchestration.
# @intent: config, setting, env, setup, manage, hydration
# @objective: Provide a unified interface for reading and writing configuration across multiple scopes (global, repo, environment).

# Get a configuration value with scoping (Repo -> Global -> Environment -> Default)
# Usage: config_value_scoped <key> [default]
config_value_scoped() {
  local key="$1"
  local default="${2:-}"
  local val=""

  # 1. Check local repo .env (Priority 1)
  local local_path
  local_path="$(get_repo_state_dir || true)/config.env"
  if [ -f "$local_path" ]; then
    val="$(config_get_value "$local_path" "$key" "")"
  fi

  # 2. Check global .env (Priority 2)
  if [ -z "$val" ]; then
    val="$(config_get_value "$CONFIG_FILE" "$key" "")"
  fi

  # 3. Check YAML Orchestrator (Priority 3 / Defaults)
  if [ -z "$val" ] && [ -f "${ENVIRONMENT_YAML:-}" ]; then
    local yaml_key="$key"
    # Map dots to nested structure if needed (e.g. system.quiet)
    case "$key" in
      quiet|developer|state_path) yaml_key="system.$key" ;;
      *) yaml_key="$key" ;;
    esac
    val="$(dev_kit_yaml_value "$ENVIRONMENT_YAML" "$yaml_key" "")"
  fi

  if [ -n "$val" ]; then
    echo "$val"
  else
    echo "$default"
  fi
}

# Raw configuration value extractor
# Usage: config_get_value <file> <key> [default]
config_get_value() {
  local file="$1"
  local key="$2"
  local default="${3:-}"
  local val=""
  if [ -f "$file" ]; then
    val="$(awk -F= -v k="$key" '
      $1 ~ "^[[:space:]]*"k"[[:space:]]*$" {
        sub(/^[[:space:]]*/,"",$2);
        sub(/[[:space:]]*$/,"",$2);
        print $2;
        exit
      }
    ' "$file")"
  fi
  if [ -n "$val" ]; then
    echo "$val"
  else
    echo "$default"
  fi
}

# Update a configuration value in a specific file
# Usage: config_set_value <key> <value> <file>
config_set_value() {
  local key="$1"
  local value="$2"
  local path="$3"
  local tmp
  tmp="$(mktemp)"
  if [ -f "$path" ]; then
    awk -v k="$key" -v v="$value" '
      BEGIN { found=0 }
      {
        if ($0 ~ "^[[:space:]]*"k"[[:space:]]*=") {
          found=1
          print k" = "v
          next
        }
        print
      }
      END {
        if (!found) {
          print k" = "v
        }
      }
    ' "$path" > "$tmp"
  else
    printf "%s = %s\n" "$key" "$value" > "$tmp"
  fi
  mkdir -p "$(dirname "$path")"
  mv "$tmp" "$path"
}
