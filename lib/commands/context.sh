#!/bin/bash

dev_kit_cmd_context() {
  shift || true
  local sub="${1:-}"

  case "$sub" in
    ""|path)
      if ! context_enabled; then
        echo "context disabled (context.enabled=false)" >&2
        exit 1
      fi
      local path=""
      path="$(context_file)"
      echo "$path"
      ;;
    show)
      if ! context_enabled; then
        echo "context disabled (context.enabled=false)" >&2
        exit 1
      fi
      local path=""
      path="$(context_file)"
      echo "path: $path"
      if [ -f "$path" ]; then
        echo ""
        echo "Context:"
        cat "$path"
      fi
      ;;
    reset)
      if ! context_enabled; then
        echo "context disabled (context.enabled=false)" >&2
        exit 1
      fi
      local path=""
      path="$(context_file)"
      mkdir -p "$(dirname "$path")"
      : > "$path"
      echo "context cleared: $path"
      ;;
    compact)
      if ! context_enabled; then
        echo "context disabled (context.enabled=false)" >&2
        exit 1
      fi
      local path=""
      path="$(context_file)"
      if [ -f "$path" ]; then
        context_compact_file "$path"
        echo "context compacted: $path"
      else
        echo "context missing: $path"
      fi
      ;;
    help|-h|--help)
      cat <<'CONTEXT_USAGE'
Usage: dev.kit context [path|show|reset|compact]

Commands:
  path    Print the context file path for current context
  show    Print the context file path and contents
  reset   Clear the context file contents
  compact Compact the context file to context.max_bytes
CONTEXT_USAGE
      ;;
    *)
      echo "Unknown context command: $sub" >&2
      echo "Run: dev.kit context --help" >&2
      exit 1
      ;;
  esac
}
