#!/usr/bin/env bash

# Per-process file cache: survives subshell boundaries because it uses a temp file.
# Global variable caches don't survive $(subshell) calls — each subshell gets a copy
# of the parent's env and any writes are discarded when the subshell exits.
# Using $$ (parent PID, stable across all subshells) means all subshells share one file.
_DEV_KIT_PROC_CACHE="${TMPDIR:-/tmp}/dev-kit-${$}.cache"

dev_kit_cache_get() {
  local key="$1"
  [ -f "$_DEV_KIT_PROC_CACHE" ] || return 1
  local val
  # Return last match so re-sets for the same key return fresh data
  val="$(awk -v k="${key}=" 'substr($0,1,length(k))==k{v=substr($0,length(k)+1)} END{if(v!="") print v}' \
    "$_DEV_KIT_PROC_CACHE" 2>/dev/null)"
  [ -n "$val" ] || return 1
  # Decode unit-separator back to newlines (multi-line values)
  printf '%s' "$val" | tr '\037' '\n'
}

dev_kit_cache_set() {
  # Encode newlines as unit-separator (0x1f) so multi-line values stay on one line
  local encoded
  encoded="$(printf '%s' "$2" | tr '\n' '\037')"
  printf '%s=%s\n' "$1" "$encoded" >> "$_DEV_KIT_PROC_CACHE"
}

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
    printf '"%s"' "$(dev_kit_json_escape "$item")"
    first=0
  done
  printf "]"
}

dev_kit_unique_lines() {
  awk 'NF && !seen[$0]++'
}

dev_kit_unique_lines_ci() {
  awk '
    NF {
      lowered = tolower($0)
      if (!seen[lowered]++) {
        print
      }
    }
  '
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

dev_kit_yaml_config_list() {
  local file_path="$1"
  local key="$2"

  awk -v key="$key" '
    $1 == "config:" {
      in_config = 1
      next
    }

    in_config && $0 ~ /^  [A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      in_target = (current == key)
      next
    }

    in_target && $0 ~ /^    - / {
      sub(/^[[:space:]]*-[[:space:]]*/, "", $0)
      print
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

dev_kit_yaml_nested_mapping_scalar() {
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
      next
    }

    in_section && $0 ~ /^    [A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      in_key = (current == key)
      next
    }

    in_key && $0 ~ /^      [A-Za-z0-9_-]+:/ {
      current = $1
      sub(":", "", current)
      if (current != nested_key) {
        next
      }
      sub(/^[[:space:]]*[A-Za-z0-9_-]+:[[:space:]]*/, "", $0)
      print
      exit
    }
  ' "$file_path"
}

dev_kit_yaml_named_block_ids() {
  local file_path="$1"
  local section="$2"

  awk -v section="$section" '
    $1 == "config:" { in_config = 1; next }
    in_config && $0 ~ "^  " section ":" { in_section = 1; next }
    in_section && $0 ~ /^  [A-Za-z0-9_-]+:/ && $0 !~ "^  " section ":" { exit }
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
    in_section && $0 ~ /^  [A-Za-z0-9_-]+:/ && $0 !~ "^  " section ":" { exit }
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
    in_section && $0 ~ /^  [A-Za-z0-9_-]+:/ && $0 !~ "^  " section ":" { exit }
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
