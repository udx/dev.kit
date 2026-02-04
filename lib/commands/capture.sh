#!/bin/bash

dev_kit_cmd_capture() {
  shift || true
  local sub="${1:-}"

  case "$sub" in
    ""|path)
      local dir=""
      if ! dir="$(capture_dir)"; then
        echo "capture disabled (capture.mode=off)" >&2
        exit 1
      fi
      echo "$dir"
      ;;
    show)
      local dir=""
      if ! dir="$(capture_dir)"; then
        echo "capture disabled (capture.mode=off)" >&2
        exit 1
      fi
      local input_path="$dir/last-input.log"
      local output_path="$dir/last-output.log"
      echo "input: $input_path"
      echo "output: $output_path"
      if [ -f "$input_path" ]; then
        echo ""
        echo "Last input:"
        cat "$input_path"
      fi
      if [ -f "$output_path" ]; then
        echo ""
        echo "Last output:"
        cat "$output_path"
      fi
      ;;
    help|-h|--help)
      cat <<'CAPTURE_USAGE'
Usage: dev.kit capture [path|show]

Commands:
  path   Print capture directory for current context (default)
  show   Print capture paths and contents for last input/output
CAPTURE_USAGE
      ;;
    *)
      echo "Unknown capture command: $sub" >&2
      echo "Run: dev.kit capture --help" >&2
      exit 1
      ;;
  esac
}
