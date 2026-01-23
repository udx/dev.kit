#!/bin/bash

_dev_kit_complete() {
  local cur prev cmd sub
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  cmd="${COMP_WORDS[1]}"

  if [ $COMP_CWORD -eq 1 ]; then
    COMPREPLY=( $(compgen -W "help version paths codex install update uninstall enable init test session doctor clock capture config" -- "$cur") )
    return 0
  fi

  case "$cmd" in
    codex)
      COMPREPLY=( $(compgen -W "config rules skills clock --get-rules --plan-rules --apply-rules --show --plan --apply" -- "$cur") )
      return 0
      ;;
    install)
      COMPREPLY=( )
      return 0
      ;;
    uninstall)
      COMPREPLY=( $(compgen -W "--purge" -- "$cur") )
      return 0
      ;;
    enable)
      COMPREPLY=( $(compgen -W "--shell=bash --shell=zsh --file= --force" -- "$cur") )
      return 0
      ;;
    test)
      COMPREPLY=( $(compgen -W "--module --module= --suite --suite= --all --mock --run --list --force" -- "$cur") )
      return 0
      ;;
    clock)
      if [ $COMP_CWORD -eq 2 ]; then
        COMPREPLY=( $(compgen -W "start status reset --scope --scope= --root --root= --global" -- "$cur") )
        return 0
      fi
      ;;
    session)
      if [ $COMP_CWORD -eq 2 ]; then
        COMPREPLY=( $(compgen -W "start status summary save" -- "$cur") )
        return 0
      fi
      if [ "${COMP_WORDS[2]}" = "save" ]; then
        COMPREPLY=( $(compgen -W "--force" -- "$cur") )
        return 0
      fi
      ;;
    capture)
      if [ $COMP_CWORD -eq 2 ]; then
        COMPREPLY=( $(compgen -W "start stop status show shell clear auto-clean" -- "$cur") )
        return 0
      fi
      sub="${COMP_WORDS[2]}"
      case "$sub" in
        start)
          COMPREPLY=( $(compgen -W "--input --no-shell" -- "$cur") )
          return 0
          ;;
        clear)
          COMPREPLY=( $(compgen -W "--force" -- "$cur") )
          return 0
          ;;
        auto-clean)
          COMPREPLY=( $(compgen -W "on off" -- "$cur") )
          return 0
          ;;
      esac
      ;;
    config)
      if [ $COMP_CWORD -eq 2 ]; then
        COMPREPLY=( $(compgen -W "show reset set global repo" -- "$cur") )
        return 0
      fi
      sub="${COMP_WORDS[2]}"
      if [ "$sub" = "global" ] || [ "$sub" = "repo" ]; then
        COMPREPLY=( $(compgen -W "--show --default --min --max --custom" -- "$cur") )
        return 0
      fi
      if [ "$sub" = "reset" ]; then
        COMPREPLY=( $(compgen -W "--force" -- "$cur") )
        return 0
      fi
      if [ "$sub" = "set" ] && [ $COMP_CWORD -eq 3 ]; then
        COMPREPLY=( $(compgen -W "quiet codex_suggest capture.enabled capture.full capture.auto_clean capture.auto_clean_iteration capture.ttl_days_global capture.ttl_days_repo" -- "$cur") )
        return 0
      fi
      ;;
  esac
}

complete -F _dev_kit_complete dev.kit
