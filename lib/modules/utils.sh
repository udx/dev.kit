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
  while IFS= read -r item || [ -n "$item" ]; do
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

dev_kit_yaml_nested_mapping_list() {
  local file_path="$1"
  local section="$2"
  local key="$3"
  local nested_key="$4"

  awk -v section="$section" -v key="$key" -v nested_key="$nested_key" '
    $1 == "config:" {
      in_config = 1
      next
    }

    in_config && $0 ~ /^  [A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      in_section = (current == section)
      in_key = 0
      in_nested = 0
      next
    }

    in_section && $0 ~ /^    [A-Za-z0-9_.-]+:/ {
      current = $1
      sub(":", "", current)
      in_key = (current == key)
      in_nested = 0
      next
    }

    in_key && $0 ~ /^      [A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      in_nested = (current == nested_key)
      next
    }

    in_nested && $0 ~ /^        - / {
      sub(/^[[:space:]]*-[[:space:]]*/, "", $0)
      print
    }
  ' "$file_path"
}

dev_kit_yaml_named_block_ids() {
  local file_path="$1"
  local section="$2"

  awk -v section="$section" '
    $1 == "config:" {
      in_config = 1
      next
    }

    in_config && $0 ~ "^  " section ":" {
      in_section = 1
      next
    }

    in_section && $0 ~ /^    [A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      print current
    }
  ' "$file_path"
}

dev_kit_yaml_named_block_scalar() {
  local file_path="$1"
  local section="$2"
  local block_id="$3"
  local key="$4"

  awk -v section="$section" -v block_id="$block_id" -v key="$key" '
    $1 == "config:" { in_config = 1; next }
    in_config && $0 ~ "^  " section ":" { in_section = 1; next }
    in_section && $0 ~ /^    [A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      in_target = (current == block_id)
      next
    }
    in_target && $0 ~ "^      " key ":" {
      sub(/^[[:space:]]*[A-Za-z0-9_-]+:[[:space:]]*/, "", $0)
      print
      exit
    }
  ' "$file_path"
}

dev_kit_yaml_named_block_list() {
  local file_path="$1"
  local section="$2"
  local block_id="$3"
  local key="$4"

  awk -v section="$section" -v block_id="$block_id" -v key="$key" '
    $1 == "config:" { in_config = 1; next }
    in_config && $0 ~ "^  " section ":" { in_section = 1; next }
    in_section && $0 ~ /^    [A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      in_target = (current == block_id)
      in_list = 0
      next
    }
    in_target && $0 ~ /^      [A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      in_list = (current == key)
      next
    }
    in_list && $0 ~ /^        - / {
      sub(/^[[:space:]]*-[[:space:]]*/, "", $0)
      print
    }
  ' "$file_path"
}
