#!/usr/bin/env bash

dev_kit_repo_archetypes() {
  local repo_dir="$1"
  local archetypes=""
  local has_dependency_manifest=0
  local has_runtime_signal=0
  local has_build_signal=0
  local has_shell_surface=0

  if dev_kit_repo_has_any_file_from_list "$repo_dir" "dependency_manifest_files"; then
    has_dependency_manifest=1
  fi

  if dev_kit_repo_has_any_file_from_list "$repo_dir" "runtime_files" || dev_kit_repo_has_make_target "$repo_dir" "run" || dev_kit_repo_documented_command "$repo_dir" "run" >/dev/null; then
    has_runtime_signal=1
  fi

  if dev_kit_repo_has_any_file_from_list "$repo_dir" "dependency_partial_files" || dev_kit_repo_has_make_target "$repo_dir" "build" || dev_kit_repo_documented_command "$repo_dir" "build" >/dev/null; then
    has_build_signal=1
  fi

  if dev_kit_repo_has_any_dir_from_list "$repo_dir" "shell_dirs" || dev_kit_repo_has_any_glob_from_list "$repo_dir" "shell_globs"; then
    has_shell_surface=1
  fi

  if dev_kit_repo_has_any_glob_from_list "$repo_dir" "workflow_globs" && dev_kit_repo_has_pattern_in_glob_list "$repo_dir" "workflow_globs" "workflow_contract"; then
    archetypes="${archetypes}workflow-repo
"
  fi

  if dev_kit_repo_has_any_file_from_list "$repo_dir" "container_files" && { [ "$has_runtime_signal" -eq 1 ] || [ "$has_build_signal" -eq 1 ] || dev_kit_repo_has_any_file_from_list "$repo_dir" "deploy_files"; }; then
    archetypes="${archetypes}runtime-image
"
  fi

  if [ "$has_dependency_manifest" -eq 1 ] && { [ "$has_runtime_signal" -eq 1 ] || [ "$has_build_signal" -eq 1 ] || dev_kit_repo_has_any_file_from_list "$repo_dir" "deploy_files"; }; then
    archetypes="${archetypes}application
"
  fi

  if [ "$has_dependency_manifest" -eq 1 ] && [ "$has_runtime_signal" -eq 0 ] && [ "$has_build_signal" -eq 0 ]; then
    archetypes="${archetypes}library-cli
"
  fi

  if [ "$has_dependency_manifest" -eq 0 ] && [ "$has_shell_surface" -eq 1 ] && [ "$has_runtime_signal" -eq 0 ] && ! dev_kit_repo_has_any_glob_from_list "$repo_dir" "workflow_globs"; then
    archetypes="${archetypes}library-cli
"
  fi

  if dev_kit_repo_has_any_file_from_list "$repo_dir" "deploy_files" || dev_kit_repo_has_any_dir_from_list "$repo_dir" "infra_dirs"; then
    archetypes="${archetypes}infra-config
"
  fi

  if [ -z "$archetypes" ]; then
    printf "%s\n" "unknown"
    return 0
  fi

  printf "%s" "$archetypes" | awk '!seen[$0]++'
}

dev_kit_repo_has_archetype() {
  local repo_dir="$1"
  local archetype="$2"

  case "
$(dev_kit_repo_archetypes "$repo_dir")
" in
    *"
$archetype
"*) return 0 ;;
  esac

  return 1
}

dev_kit_repo_primary_archetype() {
  local repo_dir="$1"
  local archetypes=""
  local archetype=""

  archetypes="$(dev_kit_repo_archetypes "$repo_dir")"

  for archetype in workflow-repo runtime-image application infra-config library-cli unknown; do
    case "
$archetypes
" in
      *"
$archetype
"*) printf "%s" "$archetype"; return 0 ;;
    esac
  done

  printf "%s" "unknown"
}

dev_kit_repo_archetypes_text() {
  dev_kit_repo_archetypes "$1" | dev_kit_lines_to_csv
}

dev_kit_repo_archetypes_json() {
  dev_kit_repo_archetypes "$1" | dev_kit_lines_to_json_array
}

dev_kit_repo_has_runtime_signals() {
  local repo_dir="$1"

  dev_kit_repo_has_any_file_from_list "$repo_dir" "runtime_files" || \
    dev_kit_repo_has_make_target "$repo_dir" "run" || \
    dev_kit_repo_documented_command "$repo_dir" "run" >/dev/null
}

dev_kit_repo_has_build_signals() {
  local repo_dir="$1"

  dev_kit_repo_has_make_target "$repo_dir" "build" || \
    dev_kit_repo_documented_command "$repo_dir" "build" >/dev/null || \
    dev_kit_repo_has_any_file_from_list "$repo_dir" "dependency_partial_files"
}
