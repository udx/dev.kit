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

dev_kit_json_escape() {
  printf '%s' "$1" | awk '
    BEGIN { ORS = "" }
    {
      if (NR > 1) {
        printf "\\n"
      }
      gsub(/\\/, "\\\\")
      gsub(/"/, "\\\"")
      gsub(/\t/, "\\t")
      gsub(/\r/, "\\r")
      printf "%s", $0
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
    $1 == "config:" {
      in_config = 1
      next
    }

    in_config && $0 ~ /^  [A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      in_section = (current == section)
      next
    }

    in_section && $0 ~ /^    [A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      if (current != key) {
        next
      }

      sub(/^[[:space:]]*[A-Za-z0-9_-]+:[[:space:]]*/, "", $0)
      print
      exit
    }
  ' "$file_path"
}

dev_kit_yaml_mapping_list() {
  local file_path="$1"
  local section="$2"
  local key="$3"

  awk -v section="$section" -v key="$key" '
    $1 == "config:" {
      in_config = 1
      next
    }

    in_config && $0 ~ /^  [A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      in_section = (current == section)
      in_target = 0
      next
    }

    in_section && $0 ~ /^    [A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      in_target = (current == key)
      next
    }

    in_target && $0 ~ /^      - / {
      sub(/^[[:space:]]*-[[:space:]]*/, "", $0)
      print
    }
  ' "$file_path"
}
