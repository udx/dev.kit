#!/usr/bin/env bash

_DEV_KIT_COMPLETION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_dev_kit_complete() {
  local cur cmd
  cur="${COMP_WORDS[COMP_CWORD]}"
  cmd="${COMP_WORDS[1]}"

  _dev_kit_cmd() {
    printf "%s" "$(cd "${_DEV_KIT_COMPLETION_DIR}/.." && pwd)/dev-kit"
  }

  _dev_kit_list_commands() {
    "$(_dev_kit_cmd)" help 2>/dev/null | awk '
      /^Commands:/ { flag=1; next }
      flag && $0 ~ /^  [a-zA-Z0-9-]+/ { print $1 }
      flag && $0 == "" { exit }
    '
  }

  _dev_kit_list_options() {
    local target="${1:-help}"
    "$(_dev_kit_cmd)" "$target" --help 2>/dev/null | awk '
      /^Options:/ { flag=1; next }
      flag && $0 ~ /^  --/ { print $1 }
      flag && $0 == "" { exit }
    '
  }

  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$(_dev_kit_list_commands) --json" -- "$cur") )
    return 0
  fi

  if [ "$COMP_CWORD" -eq 2 ] && [ "$cmd" = "action" ]; then
    COMPREPLY=( $(compgen -W "--json" -- "$cur") )
    return 0
  fi

  if [[ "$cur" == -* ]]; then
    COMPREPLY=( $(compgen -W "$(_dev_kit_list_options "$cmd")" -- "$cur") )
    return 0
  fi

  COMPREPLY=()
}

complete -F _dev_kit_complete dev.kit
