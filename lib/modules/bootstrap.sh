#!/usr/bin/env bash

dev_kit_bootstrap() {
  export DEV_KIT_BIN_DIR="${DEV_KIT_BIN_DIR:-$HOME/.local/bin}"
  export DEV_KIT_HOME="${DEV_KIT_HOME:-$HOME/.udx/dev.kit}"
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
