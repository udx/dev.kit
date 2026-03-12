#!/usr/bin/env bash

dev_kit_template_path() {
  printf "%s" "$REPO_DIR/src/templates/$1"
}

dev_kit_template_render() {
  local template_name="$1"
  local template_path=""
  local pair=""
  local key=""
  local value=""
  local env_name=""
  local rendered=""

  template_path="$(dev_kit_template_path "$template_name")"
  [ -f "$template_path" ] || return 1

  for pair in "${@:2}"; do
    key="${pair%%=*}"
    value="${pair#*=}"
    env_name="DEV_KIT_TEMPLATE_${key}"
    export "${env_name}=${value}"
  done

  rendered="$(
    awk '
      {
        line = $0
        while (match(line, /\{\{[A-Za-z0-9_]+\}\}/)) {
          token = substr(line, RSTART, RLENGTH)
          key = substr(token, 3, RLENGTH - 4)
          value = ENVIRON["DEV_KIT_TEMPLATE_" key]
          line = substr(line, 1, RSTART - 1) value substr(line, RSTART + RLENGTH)
        }
        print line
      }
    ' "$template_path"
  )"

  printf '%s\n' "$rendered"

  for pair in "${@:2}"; do
    key="${pair%%=*}"
    unset "DEV_KIT_TEMPLATE_${key}"
  done
}
