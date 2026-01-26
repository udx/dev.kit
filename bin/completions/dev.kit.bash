#!/bin/bash

_dev_kit_complete() {
  local cur prev cmd sub
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  cmd="${COMP_WORDS[1]}"

  _dev_kit_list_subcommands() {
    dev.kit "$1" -h 2>/dev/null | awk '
      /^Commands:/ {flag=1; next}
      flag && $0 ~ /^  [a-zA-Z0-9]/ {print $1}
      flag && $0 == "" {exit}
    '
  }

  _dev_kit_list_options() {
    dev.kit "$1" -h 2>/dev/null | awk '
      /^Options:/ {flag=1; next}
      flag && $0 == "" {exit}
      flag {
        for (i=1; i<=NF; i++) {
          if ($i ~ /^--/) {
            gsub(/,/, "", $i);
            print $i
          }
        }
      }
    ' | sort -u
  }

  if [ $COMP_CWORD -eq 1 ]; then
    local cmds
    cmds="$(dev.kit help 2>/dev/null | awk '/^  /{print $1}')"
    COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
    return 0
  fi

  if [ $COMP_CWORD -eq 2 ]; then
    local subs
    subs="$(_dev_kit_list_subcommands "$cmd")"
    if [ -n "$subs" ]; then
      COMPREPLY=( $(compgen -W "$subs" -- "$cur") )
      return 0
    fi
  fi

  if [[ "$cur" == -* ]]; then
    local opts
    opts="$(_dev_kit_list_options "$cmd")"
    if [ -n "$opts" ]; then
      COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
      return 0
    fi
  fi
}

complete -F _dev_kit_complete dev.kit
