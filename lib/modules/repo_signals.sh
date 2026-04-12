#!/usr/bin/env bash

DEV_KIT_REPO_ROOT_CACHE_INPUT=""
DEV_KIT_REPO_ROOT_CACHE_VALUE=""
DEV_KIT_REPO_MARKERS_CACHE_REPO=""
DEV_KIT_REPO_MARKERS_CACHE_VALUE=""

dev_kit_detection_catalog_path() {
  printf "%s" "$REPO_DIR/src/configs/detection-patterns.yaml"
}

dev_kit_detection_signals_path() {
  printf "%s" "$REPO_DIR/src/configs/detection-signals.yaml"
}

dev_kit_detection_pattern() {
  local kind="$1"

  dev_kit_yaml_mapping_scalar "$(dev_kit_detection_catalog_path)" "command_patterns" "$kind"
}

dev_kit_detection_list() {
  local list_name="$1"

  dev_kit_yaml_config_list "$(dev_kit_detection_signals_path)" "$list_name"
}

dev_kit_detection_scalar() {
  local key="$1"

  dev_kit_yaml_config_scalar "$(dev_kit_detection_signals_path)" "$key"
}

dev_kit_repo_name() {
  basename "${1:-$(pwd)}"
}

dev_kit_repo_has_root_file_marker() {
  local repo_dir="$1"
  local path=""

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if dev_kit_has_file "$repo_dir" "$path"; then
      return 0
    fi
  done <<EOF
$(dev_kit_context_list "repo_root_files")
EOF

  return 1
}

dev_kit_repo_has_root_dir_marker() {
  local repo_dir="$1"
  local path=""

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if dev_kit_repo_has_dir "$repo_dir" "$path"; then
      return 0
    fi
  done <<EOF
$(dev_kit_context_list "repo_root_dirs")
EOF

  return 1
}

dev_kit_repo_has_root_marker() {
  local repo_dir="${1:-$(pwd)}"

  if [ -d "$repo_dir/.git" ]; then
    return 0
  fi

  if dev_kit_repo_has_root_file_marker "$repo_dir"; then
    return 0
  fi

  if dev_kit_repo_has_root_dir_marker "$repo_dir"; then
    return 0
  fi

  if dev_kit_has_file "$repo_dir" ".github/workflows" || dev_kit_repo_has_dir "$repo_dir" ".github/workflows"; then
    return 0
  fi

  return 1
}

dev_kit_repo_root() {
  local input_dir="${1:-$(pwd)}"
  local repo_dir=""
  local parent_dir=""

  repo_dir="$(cd "$input_dir" 2>/dev/null && pwd || printf '%s' "$input_dir")"

  if [ "$DEV_KIT_REPO_ROOT_CACHE_INPUT" = "$repo_dir" ]; then
    printf "%s" "$DEV_KIT_REPO_ROOT_CACHE_VALUE"
    return 0
  fi

  while [ -n "$repo_dir" ] && [ "$repo_dir" != "/" ]; do
    if dev_kit_repo_has_root_marker "$repo_dir"; then
      DEV_KIT_REPO_ROOT_CACHE_INPUT="$input_dir"
      DEV_KIT_REPO_ROOT_CACHE_VALUE="$repo_dir"
      printf "%s" "$repo_dir"
      return 0
    fi
    parent_dir="$(dirname "$repo_dir")"
    [ "$parent_dir" = "$repo_dir" ] && break
    repo_dir="$parent_dir"
  done

  DEV_KIT_REPO_ROOT_CACHE_INPUT="$input_dir"
  DEV_KIT_REPO_ROOT_CACHE_VALUE=""
}

dev_kit_repo_looks_like_repo() {
  [ -n "$(dev_kit_repo_root "${1:-$(pwd)}")" ]
}

dev_kit_repo_marker_lines() {
  local repo_dir="${1:-$(pwd)}"
  local marker_group=""
  local marker_kind=""
  local marker_prefix=""
  local path=""
  local markers=""

  if [ "$DEV_KIT_REPO_MARKERS_CACHE_REPO" = "$repo_dir" ]; then
    printf "%s" "$DEV_KIT_REPO_MARKERS_CACHE_VALUE"
    return 0
  fi

  DEV_KIT_REPO_MARKERS_CACHE_REPO="$repo_dir"
  while IFS= read -r marker_group; do
    [ -n "$marker_group" ] || continue
    marker_kind="$(dev_kit_context_marker_group_field "$marker_group" "kind")"
    marker_prefix="$(dev_kit_context_marker_group_field "$marker_group" "prefix")"
    [ -n "$marker_kind" ] || continue
    [ -n "$marker_prefix" ] || continue

    while IFS= read -r path; do
      [ -n "$path" ] || continue
      case "$marker_kind" in
        file)
          if dev_kit_has_file "$repo_dir" "$path"; then
            markers="${markers}${marker_prefix}:${path}
"
          fi
          ;;
        dir)
          if dev_kit_repo_has_dir "$repo_dir" "$path"; then
            markers="${markers}${marker_prefix}:${path}
"
          fi
          ;;
      esac
    done <<EOF
$(dev_kit_context_marker_group_paths "$marker_group")
EOF
  done <<EOF
$(dev_kit_context_marker_group_ids)
EOF

  DEV_KIT_REPO_MARKERS_CACHE_VALUE="$(printf "%s" "$markers" | dev_kit_unique_lines_ci)"
  printf "%s" "$DEV_KIT_REPO_MARKERS_CACHE_VALUE"
}

dev_kit_repo_markers_text() {
  local repo_dir="${1:-$(pwd)}"
  local markers=""

  markers="$(dev_kit_repo_marker_lines "$repo_dir")"
  if [ -z "$markers" ]; then
    printf "%s" "none"
    return 0
  fi

  printf "%s" "$markers" | dev_kit_lines_to_csv
}

dev_kit_repo_markers_json() {
  local repo_dir="${1:-$(pwd)}"
  local markers=""

  markers="$(dev_kit_repo_marker_lines "$repo_dir")"
  if [ -z "$markers" ]; then
    printf "%s" "[]"
    return 0
  fi

  printf "%s" "$markers" | dev_kit_lines_to_json_array
}

dev_kit_has_file() {
  local repo_dir="$1"
  local path="$2"
  [ -e "$repo_dir/$path" ]
}

dev_kit_repo_has_dir() {
  local repo_dir="$1"
  local path="$2"
  [ -d "$repo_dir/$path" ]
}

dev_kit_repo_find() {
  local repo_dir="$1"
  local prune_path=""
  local prune_args=()
  local last_index=0
  shift

  while IFS= read -r prune_path; do
    [ -n "$prune_path" ] || continue
    prune_args+=(-path "$repo_dir/$prune_path" -o)
  done <<EOF
$(dev_kit_detection_list "prune_dirs")
EOF

  if [ "${#prune_args[@]}" -eq 0 ]; then
    find "$repo_dir" "$@"
    return 0
  fi

  last_index=$((${#prune_args[@]} - 1))
  unset "prune_args[$last_index]"

  find "$repo_dir" "(" "${prune_args[@]}" ")" -prune -o "$@"
}

dev_kit_repo_has_glob() {
  local repo_dir="$1"
  local pattern="$2"

  if [[ "$pattern" == */* ]]; then
    dev_kit_repo_find "$repo_dir" -type f -path "$repo_dir/$pattern" -print -quit | grep -q .
    return $?
  fi

  dev_kit_repo_find "$repo_dir" -type f -name "$pattern" -print -quit | grep -q .
}

dev_kit_repo_find_from_glob_list() {
  local repo_dir="$1"
  local list_name="$2"
  local pattern=""

  while IFS= read -r pattern; do
    [ -n "$pattern" ] || continue
    if [[ "$pattern" == */* ]]; then
      dev_kit_repo_find "$repo_dir" -type f -path "$repo_dir/$pattern" -print
    else
      dev_kit_repo_find "$repo_dir" -type f -name "$pattern" -print
    fi
  done <<EOF
$(dev_kit_detection_list "$list_name")
EOF
}

dev_kit_repo_markdown_files() {
  local repo_dir="$1"

  dev_kit_repo_find_from_glob_list "$repo_dir" "markdown_file_globs" | sort -u
}

dev_kit_repo_has_any_file_from_list() {
  local repo_dir="$1"
  local list_name="$2"
  local path=""

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if dev_kit_has_file "$repo_dir" "$path"; then
      return 0
    fi
  done <<EOF
$(dev_kit_detection_list "$list_name")
EOF

  return 1
}

dev_kit_repo_has_any_dir_from_list() {
  local repo_dir="$1"
  local list_name="$2"
  local path=""

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if dev_kit_repo_has_dir "$repo_dir" "$path"; then
      return 0
    fi
  done <<EOF
$(dev_kit_detection_list "$list_name")
EOF

  return 1
}

dev_kit_repo_has_any_glob_from_list() {
  local repo_dir="$1"
  local list_name="$2"
  local pattern=""

  while IFS= read -r pattern; do
    [ -n "$pattern" ] || continue
    if dev_kit_repo_has_glob "$repo_dir" "$pattern"; then
      return 0
    fi
  done <<EOF
$(dev_kit_detection_list "$list_name")
EOF

  return 1
}

dev_kit_repo_pattern_in_file() {
  local file_path="$1"
  local regex="$2"

  awk -v regex="$regex" '
    match($0, regex) {
      found=1
      exit
    }
    END { exit found ? 0 : 1 }
  ' "$file_path" >/dev/null 2>&1
}

dev_kit_repo_has_pattern_in_glob_list() {
  local repo_dir="$1"
  local list_name="$2"
  local pattern_name="$3"
  local regex=""
  local file_path=""

  regex="$(dev_kit_detection_pattern "$pattern_name")"
  [ -n "$regex" ] || return 1

  while IFS= read -r file_path; do
    [ -n "$file_path" ] || continue
    if dev_kit_repo_pattern_in_file "$file_path" "$regex"; then
      return 0
    fi
  done <<EOF
$(dev_kit_repo_find_from_glob_list "$repo_dir" "$list_name")
EOF

  return 1
}

dev_kit_repo_file_has_all_patterns() {
  local file_path="$1"
  shift
  local pattern_name=""
  local regex=""

  [ -f "$file_path" ] || return 1

  for pattern_name in "$@"; do
    regex="$(dev_kit_detection_pattern "$pattern_name")"
    [ -n "$regex" ] || return 1
    if ! dev_kit_repo_pattern_in_file "$file_path" "$regex"; then
      return 1
    fi
  done

  return 0
}


dev_kit_repo_documented_command() {
  local repo_dir="$1"
  local kind="$2"
  local doc_file=""
  local regex=""
  local command=""

  regex="$(dev_kit_detection_pattern "$kind")"
  [ -n "$regex" ] || return 1

  while IFS= read -r doc_file; do
    command="$(awk -v regex="$regex" '
      match($0, regex) {
        print substr($0, RSTART, RLENGTH)
        exit
      }
    ' "$doc_file")"
    if [ -n "$command" ]; then
      printf "%s" "$command"
      return 0
    fi
  done <<EOF
$(dev_kit_repo_markdown_files "$repo_dir")
EOF

  return 1
}

dev_kit_repo_has_make_target() {
  local repo_dir="$1"
  local target="$2"
  local makefile=""

  while IFS= read -r makefile; do
    [ -n "$makefile" ] || continue
    if [ -f "$repo_dir/$makefile" ] && grep -Eq "^${target}:" "$repo_dir/$makefile"; then
      return 0
    fi
  done <<EOF
$(dev_kit_detection_list "makefiles")
EOF

  return 1
}

dev_kit_repo_manifest_has_script() {
  local repo_dir="$1"
  local manifest="$2"
  local script_name="$3"

  [ -f "$repo_dir/$manifest" ] || return 1

  awk -v script_name="$script_name" '
    /"scripts"[[:space:]]*:[[:space:]]*{/ { in_scripts=1 }
    in_scripts && $0 ~ "\"" script_name "\"[[:space:]]*:" { found=1 }
    in_scripts && /}/ { if (!found) exit }
    END { exit found ? 0 : 1 }
  ' "$repo_dir/$manifest"
}

dev_kit_repo_has_node_test_script() {
  dev_kit_repo_manifest_has_script "$1" "package.json" "test"
}

dev_kit_repo_has_composer_test_script() {
  dev_kit_repo_manifest_has_script "$1" "composer.json" "test"
}

dev_kit_repo_documented_env_var() {
  local repo_dir="$1"
  local doc_file=""
  local regex=""

  regex="$(dev_kit_detection_pattern "env_var")"
  [ -n "$regex" ] || return 1

  while IFS= read -r doc_file; do
    [ -n "$doc_file" ] || continue
    if dev_kit_repo_pattern_in_file "$doc_file" "$regex"; then
      return 0
    fi
  done <<EOF
$(dev_kit_repo_markdown_files "$repo_dir")
EOF

  return 1
}

dev_kit_repo_has_documentation_sections() {
  local repo_dir="$1"
  local doc_file=""
  local regex=""

  regex="$(dev_kit_detection_pattern "documentation_sections")"
  [ -n "$regex" ] || return 1

  while IFS= read -r doc_file; do
    [ -n "$doc_file" ] || continue
    if dev_kit_repo_pattern_in_file "$doc_file" "$regex"; then
      return 0
    fi
  done <<EOF
$(dev_kit_repo_markdown_files "$repo_dir")
EOF

  return 1
}

dev_kit_repo_has_architecture_sections() {
  local repo_dir="$1"
  local doc_file=""
  local regex=""

  regex="$(dev_kit_detection_pattern "architecture_sections")"
  [ -n "$regex" ] || return 1

  while IFS= read -r doc_file; do
    [ -n "$doc_file" ] || continue
    if dev_kit_repo_pattern_in_file "$doc_file" "$regex"; then
      return 0
    fi
  done <<EOF
$(dev_kit_repo_markdown_files "$repo_dir")
EOF

  return 1
}

dev_kit_repo_count_dir_hits_from_list() {
  local repo_dir="$1"
  local list_name="$2"
  local path=""
  local count=0

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if dev_kit_repo_has_dir "$repo_dir" "$path"; then
      count=$((count + 1))
    fi
  done <<EOF
$(dev_kit_detection_list "$list_name")
EOF

  printf '%s' "$count"
}

dev_kit_repo_count_category_hits() {
  local repo_dir="$1"
  local count=0

  if dev_kit_repo_count_dir_hits_from_list "$repo_dir" "architecture_command_dirs" | awk '$1 > 0 { exit 0 } $1 <= 0 { exit 1 }'; then
    count=$((count + 1))
  fi

  if dev_kit_repo_count_dir_hits_from_list "$repo_dir" "architecture_logic_dirs" | awk '$1 > 0 { exit 0 } $1 <= 0 { exit 1 }'; then
    count=$((count + 1))
  fi

  if dev_kit_repo_count_dir_hits_from_list "$repo_dir" "architecture_view_dirs" | awk '$1 > 0 { exit 0 } $1 <= 0 { exit 1 }'; then
    count=$((count + 1))
  fi

  if dev_kit_repo_count_dir_hits_from_list "$repo_dir" "architecture_config_dirs" | awk '$1 > 0 { exit 0 } $1 <= 0 { exit 1 }'; then
    count=$((count + 1))
  fi

  printf '%s' "$count"
}

dev_kit_repo_max_lines_in_dirs() {
  local repo_dir="$1"
  local dir_list="$2"
  local max_lines=0
  local dir_path=""
  local pattern=""
  local file_path=""
  local line_count=0

  while IFS= read -r dir_path; do
    [ -n "$dir_path" ] || continue
    [ -d "$repo_dir/$dir_path" ] || continue

    while IFS= read -r pattern; do
      [ -n "$pattern" ] || continue
      while IFS= read -r file_path; do
        [ -n "$file_path" ] || continue
        line_count="$(wc -l < "$file_path" | tr -d ' ')"
        if [ "$line_count" -gt "$max_lines" ]; then
          max_lines="$line_count"
        fi
      done <<EOF_FILES
$(find "$repo_dir/$dir_path" -type f -name "$pattern" -print)
EOF_FILES
    done <<EOF_PATTERNS
$(dev_kit_detection_list "architecture_source_globs")
EOF_PATTERNS
  done <<EOF_DIRS
$(dev_kit_detection_list "$dir_list")
EOF_DIRS

  printf '%s' "$max_lines"
}

dev_kit_repo_has_thin_command_layer() {
  local repo_dir="$1"
  local max_lines=""
  local threshold=""

  threshold="$(dev_kit_detection_scalar "architecture_command_max_lines")"
  [ -n "$threshold" ] || threshold=120

  if ! dev_kit_repo_count_dir_hits_from_list "$repo_dir" "architecture_command_dirs" | awk '$1 > 0 { exit 0 } $1 <= 0 { exit 1 }'; then
    return 1
  fi

  max_lines="$(dev_kit_repo_max_lines_in_dirs "$repo_dir" "architecture_command_dirs")"
  [ -n "$max_lines" ] || max_lines=0
  [ "$max_lines" -le "$threshold" ]
}

dev_kit_repo_has_oversized_module() {
  local repo_dir="$1"
  local max_lines=""
  local threshold=""

  threshold="$(dev_kit_detection_scalar "architecture_module_max_lines")"
  [ -n "$threshold" ] || threshold=400

  max_lines="$(dev_kit_repo_max_lines_in_dirs "$repo_dir" "architecture_logic_dirs")"
  [ -n "$max_lines" ] || max_lines=0
  [ "$max_lines" -gt "$threshold" ]
}

dev_kit_repo_profiles() {
  local repo_dir="$1"
  local profiles=""

  if dev_kit_repo_has_any_file_from_list "$repo_dir" "node_files"; then
    profiles="${profiles}node
"
  fi

  if dev_kit_repo_has_any_file_from_list "$repo_dir" "php_files"; then
    profiles="${profiles}php
"
  fi

  if dev_kit_repo_has_any_glob_from_list "$repo_dir" "shell_globs" || dev_kit_repo_has_any_dir_from_list "$repo_dir" "shell_dirs"; then
    profiles="${profiles}shell
"
  fi

  if dev_kit_repo_has_any_file_from_list "$repo_dir" "container_files" || dev_kit_repo_has_any_glob_from_list "$repo_dir" "container_globs"; then
    profiles="${profiles}container
"
  fi

  if [ -z "$profiles" ]; then
    printf "%s\n" "unknown"
    return 0
  fi

  printf "%s" "$profiles" | awk '!seen[$0]++'
}

dev_kit_repo_primary_profile() {
  local repo_dir="$1"
  local profiles=""
  local profile=""

  profiles="$(dev_kit_repo_profiles "$repo_dir")"

  for profile in node php container shell unknown; do
    case "
$profiles
" in
      *"
$profile
"*) printf "%s" "$profile"; return 0 ;;
    esac
  done

  printf "%s" "unknown"
}

dev_kit_repo_profiles_text() {
  dev_kit_repo_profiles "$1" | dev_kit_lines_to_csv
}

dev_kit_repo_profiles_json() {
  dev_kit_repo_profiles "$1" | dev_kit_lines_to_json_array
}
