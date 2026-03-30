#!/usr/bin/env bash

dev_kit_bootstrap() {
  export DEV_KIT_BIN_DIR="${DEV_KIT_BIN_DIR:-$HOME/.local/bin}"
  export DEV_KIT_HOME="${DEV_KIT_HOME:-$HOME/.udx/dev.kit}"
}

dev_kit_command_description() {
  local file="$1"
  awk -F': ' '/^# @description:/ { print $2; exit }' "$file"
}

dev_kit_public_command_names() {
  printf '%s\n' explore action learn uninstall
}

dev_kit_command_file_path() {
  local root_dir="$1"
  local command_name="$2"

  printf "%s/lib/commands/%s.sh" "$root_dir" "${command_name//-/_}"
}
