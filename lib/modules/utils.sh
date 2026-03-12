#!/usr/bin/env bash

dev_kit_lines_to_csv() {
  awk '
    NF {
      if (count > 0) {
        printf ", "
      }
      printf "%s", $0
      count++
    }
  '
}

dev_kit_lines_to_json_array() {
  local first=1
  local item=""

  printf "["
  while IFS= read -r item; do
    [ -n "$item" ] || continue
    if [ "$first" -eq 0 ]; then
      printf ", "
    fi
    printf '"%s"' "$item"
    first=0
  done
  printf "]"
}

dev_kit_yaml_mapping_scalar() {
  local file_path="$1"
  local section="$2"
  local key="$3"

  awk -v section="$section" -v key="$key" '
    $1 == section ":" {
      in_section = 1
      next
    }

    in_section && $1 ~ /^[[:space:]]*[A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      if (current == key) {
        $1 = ""
        sub(/^[[:space:]]+/, "")
        print
        exit
      }
    }
  ' "$file_path"
}

dev_kit_yaml_mapping_list() {
  local file_path="$1"
  local section="$2"
  local key="$3"

  awk -v section="$section" -v key="$key" '
    $1 == section ":" {
      in_section = 1
      next
    }

    in_section && $1 ~ /^[[:space:]]*[A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      in_target = (current == key)
      next
    }

    in_target && $1 == "-" {
      print $2
    }
  ' "$file_path"
}
