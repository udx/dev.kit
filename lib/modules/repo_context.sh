#!/usr/bin/env bash

dev_kit_repo_priority_refs_json() {
  dev_kit_repo_priority_refs "$1" | dev_kit_lines_to_json_array
}

dev_kit_repo_priority_refs() {
  local repo_dir="${1:-$(pwd)}"
  local path=""

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if [ -e "$repo_dir/$path" ]; then
      printf "./%s\n" "$path"
    fi
  done <<EOF
$(dev_kit_context_list "priority_paths")
EOF
}
