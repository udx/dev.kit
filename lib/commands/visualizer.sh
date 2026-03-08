#!/usr/bin/env bash

# @description: Generate and export high-fidelity Mermaid diagrams (SVG).
# @intent: diagram, mermaid, svg, export, flowchart, sequence
# @objective: Enable seamless transition from "Intent" to "Visual Asset" by automating both the creation of Mermaid (.mmd) diagrams and their rendering into SVG documentation.
# @usage: dev.kit visualizer create flowchart "assets/arch.mmd"
# @usage: dev.kit visualizer export "assets/arch.mmd"
# @workflow: 1. Request diagram type -> 2. Generate .mmd -> 3. Refine logic -> 4. Export .svg

dev_kit_cmd_visualizer() {
  local sub="${1:-help}"
  
  case "$sub" in
    create|new)
      local type="${2:-flowchart}"
      local output="${3:-assets/diagrams/new-diagram.mmd}"
      if command -v dev_kit_visualizer_create >/dev/null 2>&1; then
        dev_kit_visualizer_create "$type" "$output"
      else
        echo "Error: Visualizer module not loaded." >&2
        exit 1
      fi
      ;;
    export|render)
      local input="${2:-}"
      local output="${3:-}"
      if [ -z "$input" ]; then
        echo "Error: Input file required. Usage: dev.kit visualizer export <input.mmd> [output.svg]" >&2
        exit 64
      fi
      if command -v dev_kit_visualizer_export >/dev/null 2>&1; then
        dev_kit_visualizer_export "$input" "$output"
      else
        echo "Error: Visualizer module not loaded." >&2
        exit 1
      fi
      ;;
    help|-h|--help)
      cat <<'VISUALIZER_HELP'
Usage: dev.kit visualizer <command>

Commands:
  create <type> [output]  Create a new Mermaid diagram from template
  export <input> [output] Export a Mermaid (.mmd) file to SVG

Diagram Types:
  flowchart, sequence, state, er (auto defaults to flowchart)

Example:
  dev.kit visualizer create flowchart assets/arch.mmd
  dev.kit visualizer export assets/arch.mmd assets/arch.svg
VISUALIZER_HELP
      ;;
    *)
      echo "Unknown visualizer command: $sub" >&2
      exit 1
      ;;
  esac
}
