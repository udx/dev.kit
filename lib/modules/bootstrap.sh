#!/usr/bin/env bash

dev_kit_load_defaults() {
  local config_file="$1"
  local key=""
  local value=""

  [ -f "$config_file" ] || return 0

  while IFS='=' read -r key value; do
    case "$key" in
      ''|\#*) continue ;;
    esac
    if [ -z "${!key+x}" ]; then
      eval "export ${key}=\"${value}\""
    fi
  done < "$config_file"
}

dev_kit_bootstrap() {
  local root_dir="$1"

  dev_kit_load_defaults "$root_dir/config/default.env"

  export DEV_KIT_OWNER="${DEV_KIT_OWNER:-udx}"
  export DEV_KIT_REPO="${DEV_KIT_REPO:-dev.kit}"
  export DEV_KIT_BIN_DIR="${DEV_KIT_BIN_DIR:-$HOME/.local/bin}"
  export DEV_KIT_HOME="${DEV_KIT_HOME:-$HOME/.${DEV_KIT_OWNER}/${DEV_KIT_REPO}}"
}

dev_kit_path_contains_bin_dir() {
  case ":$PATH:" in
    *":${DEV_KIT_BIN_DIR}:"*) return 0 ;;
    *) return 1 ;;
  esac
}

dev_kit_copy_file() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
}

dev_kit_copy_tree() {
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  cp -R "$src/." "$dst/"
}

dev_kit_command_name_from_file() {
  local file="$1"
  basename "$file" .sh | tr '_' '-'
}

dev_kit_command_description() {
  local file="$1"
  awk -F': ' '/^# @description:/ { print $2; exit }' "$file"
}

dev_kit_list_command_files() {
  local root_dir="$1"
  find "$root_dir/lib/commands" -maxdepth 1 -type f -name '*.sh' | sort
}
