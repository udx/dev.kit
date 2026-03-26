#!/usr/bin/env bash

# @description: Save repo-local working context for the next session

dev_kit_cmd_save() {
  local format="${1:-text}"
  local repo_dir="$(pwd)"
  local yes=0
  local context_dir=""
  local reply=""

  shift || true

  if [ "$format" = "json" ]; then
    echo "JSON output is not supported for save" >&2
    return 1
  fi

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --yes)
        yes=1
        ;;
      *)
        repo_dir="$1"
        ;;
    esac
    shift
  done

  context_dir="$(dev_kit_repo_context_dir "$repo_dir")"

  if [ -d "$context_dir" ] && [ "$yes" -ne 1 ]; then
    printf "Repo-local dev.kit context already exists at %s and will be overwritten. Continue? [y/N] " "$context_dir" >&2
    read -r reply || true
    case "$reply" in
      y|Y|yes|YES) ;;
      *)
        echo "Cancelled."
        return 1
        ;;
    esac
  fi

  rm -rf "$context_dir"
  mkdir -p "$context_dir"

  dev_kit_repo_write_context_todo "$repo_dir" "$context_dir"
  dev_kit_repo_write_context_summary "$repo_dir" "$context_dir"
  dev_kit_repo_write_context_refs "$repo_dir" "$context_dir"

  echo "Saved repo-local context:"
  echo "  - ./.udx/dev.kit/todo.md"
  echo "  - ./.udx/dev.kit/context.md"
  echo "  - ./.udx/dev.kit/refs.md"
  echo "Refresh it with dev.kit save --yes after repo files, docs, workflows, or entrypoints change."
}
