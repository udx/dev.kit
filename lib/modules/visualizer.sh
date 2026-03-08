#!/usr/bin/env bash

# dev.kit Visualizer Module
# Programmatic engine for Mermaid diagram creation and SVG export.

# Create a new Mermaid diagram from a template
# Usage: dev_kit_visualizer_create <type> <output_path> [template_dir]
dev_kit_visualizer_create() {
  local type="${1:-flowchart}"
  local output_path="$2"
  local template_dir="${3:-$REPO_DIR/src/ai/data/skill-packs/dev-kit-visualizer/assets/templates}"
  
  local diagram_type
  case "$type" in
    auto|flowchart) diagram_type="flowchart" ;;
    sequence|sequenceDiagram) diagram_type="sequenceDiagram" ;;
    state|stateDiagram-v2) diagram_type="stateDiagram-v2" ;;
    er|erDiagram) diagram_type="erDiagram" ;;
    *) echo "Error: Unsupported diagram type: $type" >&2; return 1 ;;
  esac

  local template="$template_dir/default-flowchart.mmd"
  case "$diagram_type" in
    sequenceDiagram) template="$template_dir/default-sequence.mmd" ;;
    stateDiagram-v2) template="$template_dir/default-state.mmd" ;;
    erDiagram)       template="$template_dir/default-er.mmd" ;;
  esac

  if [ ! -f "$template" ]; then
    echo "Error: Template missing: $template" >&2
    return 1
  fi

  local target="$output_path"
  [[ "$target" != *.mmd ]] && target="${target}.mmd"
  
  # Ensure unique path
  if [ -e "$target" ]; then
    local stem="${target%.mmd}"
    local i=1
    while [ -e "${stem}-${i}.mmd" ]; do i=$((i+1)); done
    target="${stem}-${i}.mmd"
  fi

  mkdir -p "$(dirname "$target")"
  cp "$template" "$target"
  echo "$target"
}

# Export a Mermaid (.mmd) file to SVG
# Usage: dev_kit_visualizer_export <input_path> <output_path>
dev_kit_visualizer_export() {
  local input_path="$1"
  local output_path="$2"
  
  if [ ! -f "$input_path" ]; then
    echo "Error: Input file missing: $input_path" >&2
    return 1
  fi

  local target="$output_path"
  [[ "$target" != *.svg ]] && target="${target}.svg"

  # Ensure unique path
  if [ -e "$target" ]; then
    local stem="${target%.svg}"
    local i=1
    while [ -e "${stem}-${i}.svg" ]; do i=$((i+1)); done
    target="${stem}-${i}.svg"
  fi

  mkdir -p "$(dirname "$target")"

  if ! command -v mmdc >/dev/null 2>&1; then
    echo "Warning: mmdc (Mermaid CLI) not found. Falling back to online view." >&2
    local mmd_content
    mmd_content="$(cat "$input_path")"
    echo "View Online: https://mermaid.live/edit#base64:$(printf "%s" "$mmd_content" | base64 | tr -d '\n')"
    return 0
  fi

  if mmdc -i "$input_path" -o "$target" >/dev/null 2>&1; then
    echo "$target"
  else
    echo "Error: mmdc export failed." >&2
    return 1
  fi
}
