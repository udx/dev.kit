#!/usr/bin/env bash

# @description: Inspect environment tools and dev.kit usage config

dev_kit_cmd_env() {
  local format="${1:-text}"
  local manage_config=0

  if [ "$#" -ge 1 ]; then
    shift
  fi

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --config) manage_config=1 ;;
      --*)
        printf 'Unknown flag: %s\n' "$1" >&2
        printf 'Usage: dev.kit env [--json] [--config]\n' >&2
        return 1
        ;;
    esac
    shift
  done

  if [ "$manage_config" -eq 1 ]; then
    dev_kit_env_config_ensure
  fi

  local config_path disabled_tools disabled_credentials
  config_path="$(dev_kit_env_config_path)"
  disabled_tools="$(dev_kit_env_config_list "disabled_tools")"
  disabled_credentials="$(dev_kit_env_config_list "disabled_credentials")"

  if [ "$format" = "json" ]; then
    printf '{\n'
    printf '  "command": "env",\n'
    printf '  "home": "%s",\n' "$(dev_kit_json_escape "$DEV_KIT_HOME")"
    printf '  "tools": %s,\n' "$(dev_kit_env_tools_json)"
    printf '  "capabilities": %s,\n' "$(dev_kit_global_context_capabilities_json)"
    printf '  "config": {\n'
    printf '    "path": "%s",\n' "$(dev_kit_json_escape "$config_path")"
    printf '    "exists": %s,\n' "$([ -f "$config_path" ] && printf 'true' || printf 'false')"
    printf '    "disabled_tools": %s,\n' "$(printf '%s' "$disabled_tools" | dev_kit_lines_to_json_array)"
    printf '    "disabled_credentials": %s\n' "$(printf '%s' "$disabled_credentials" | dev_kit_lines_to_json_array)"
    printf '  }\n'
    printf '}\n'
    return 0
  fi

  dev_kit_output_title "dev.kit env"

  local _env_line _env_cat _env_val _prev_cat=""
  while IFS= read -r _env_line; do
    [ -n "$_env_line" ] || continue
    _env_cat="${_env_line%%|*}"
    _env_val="${_env_line#*|}"
    if [ "$_env_cat" != "$_prev_cat" ]; then
      dev_kit_output_section "$_env_cat"
      _prev_cat="$_env_cat"
    fi
    dev_kit_output_list_item "$_env_val"
  done <<EOF
$(dev_kit_env_tools_text)
EOF

  dev_kit_output_section "config"
  dev_kit_output_row "path" "$config_path"
  if [ "$manage_config" -eq 1 ]; then
    dev_kit_output_list_item "Config ensured. Edit the file to disable tools or credential use."
  fi
  if [ -n "$disabled_tools" ]; then
    dev_kit_output_row "disabled tools" "$(printf '%s' "$disabled_tools" | dev_kit_lines_to_csv)"
  fi
  if [ -n "$disabled_credentials" ]; then
    dev_kit_output_row "disabled creds" "$(printf '%s' "$disabled_credentials" | dev_kit_lines_to_csv)"
  fi
  if [ -z "$disabled_tools" ] && [ -z "$disabled_credentials" ]; then
    dev_kit_output_list_item "No tool or credential overrides configured."
  fi
}
