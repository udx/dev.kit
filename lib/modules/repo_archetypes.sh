#!/usr/bin/env bash

DEV_KIT_REPO_FACETS_CACHE_REPO=""
DEV_KIT_REPO_FACETS_CACHE_VALUE=""
DEV_KIT_REPO_ARCHETYPES_CACHE_REPO=""
DEV_KIT_REPO_ARCHETYPES_CACHE_VALUE=""

dev_kit_repo_has_any_dir_from_signal_list() {
  local repo_dir="$1"
  local list_name="$2"
  local path=""

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if dev_kit_repo_has_dir "$repo_dir" "$path"; then
      return 0
    fi
  done <<EOF
$(dev_kit_archetype_signal_list "$list_name")
EOF

  return 1
}

dev_kit_repo_has_any_file_from_signal_list() {
  local repo_dir="$1"
  local list_name="$2"
  local path=""

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if dev_kit_has_file "$repo_dir" "$path"; then
      return 0
    fi
  done <<EOF
$(dev_kit_archetype_signal_list "$list_name")
EOF

  return 1
}

dev_kit_repo_has_any_glob_from_signal_list() {
  local repo_dir="$1"
  local list_name="$2"
  local pattern=""

  while IFS= read -r pattern; do
    [ -n "$pattern" ] || continue
    if dev_kit_repo_has_glob "$repo_dir" "$pattern"; then
      return 0
    fi
  done <<EOF
$(dev_kit_archetype_signal_list "$list_name")
EOF

  return 1
}

dev_kit_repo_has_facet_in_text() {
  local facets="$1"
  local facet="$2"

  case "
$facets
" in
    *"
$facet
"*) return 0 ;;
  esac

  return 1
}

dev_kit_repo_facets() {
  local repo_dir="$1"
  local facets=""
  local markers=""
  local has_wordpress=0
  local has_kubernetes=0
  local has_container=0
  local has_worker_deploy=0

  if [ "$DEV_KIT_REPO_FACETS_CACHE_REPO" = "$repo_dir" ]; then
    printf "%s" "$DEV_KIT_REPO_FACETS_CACHE_VALUE"
    return 0
  fi

  markers="$(dev_kit_repo_marker_lines "$repo_dir")"

  case "
$markers
" in
    *"
framework:wp-config.php
"*)
      has_wordpress=1
      facets="${facets}framework:wordpress
"
      ;;
  esac

  if [ "$has_wordpress" -eq 0 ] && { dev_kit_repo_has_any_file_from_signal_list "$repo_dir" "wordpress_files" || \
     dev_kit_repo_has_any_dir_from_signal_list "$repo_dir" "wordpress_dirs"; }; then
    has_wordpress=1
    facets="${facets}framework:wordpress
"
  fi

  if dev_kit_repo_has_any_file_from_signal_list "$repo_dir" "kubernetes_files" || \
     dev_kit_repo_has_any_dir_from_signal_list "$repo_dir" "kubernetes_dirs" || \
     dev_kit_repo_has_any_glob_from_signal_list "$repo_dir" "kubernetes_globs"; then
    has_kubernetes=1
    facets="${facets}platform:kubernetes
"
    if dev_kit_repo_has_any_dir_from_signal_list "$repo_dir" "kubernetes_dirs"; then
      facets="${facets}deploy:kubernetes-manifests
"
    fi
    if dev_kit_repo_has_dir "$repo_dir" "terraform" || dev_kit_repo_has_glob "$repo_dir" "*.tf"; then
      facets="${facets}deploy:terraform
"
    fi
  fi

  case "
$markers
" in
    *"
runtime:Dockerfile
"*)
      has_container=1
      facets="${facets}runtime:container
"
      ;;
  esac

  if [ "$has_container" -eq 0 ] && { dev_kit_repo_has_any_file_from_list "$repo_dir" "container_files" || \
     dev_kit_repo_has_any_glob_from_list "$repo_dir" "container_globs"; }; then
    has_container=1
    facets="${facets}runtime:container
"
  fi

  case "
$markers
" in
    *"
manifest:package.json
"*)
      facets="${facets}package:node
"
      ;;
  esac

  if ! dev_kit_repo_has_facet_in_text "$facets" "package:node" && dev_kit_has_file "$repo_dir" "package.json"; then
    facets="${facets}package:node
"
  fi

  case "
$markers
" in
    *"
manifest:composer.json
"*)
      facets="${facets}package:composer
"
      ;;
  esac

  if ! dev_kit_repo_has_facet_in_text "$facets" "package:composer" && dev_kit_has_file "$repo_dir" "composer.json"; then
    facets="${facets}package:composer
"
  fi

  if dev_kit_repo_has_worker_deploy_config "$repo_dir"; then
    has_worker_deploy=1
    facets="${facets}deploy:worker-config
"
  fi

  if dev_kit_repo_has_build_signals "$repo_dir"; then
    facets="${facets}lifecycle:build
"
  fi

  if dev_kit_repo_has_runtime_signals "$repo_dir"; then
    facets="${facets}lifecycle:runtime
"
  fi

  if dev_kit_repo_has_any_file_from_list "$repo_dir" "deploy_files" || \
     dev_kit_repo_has_any_dir_from_list "$repo_dir" "infra_dirs" || \
     [ "$has_worker_deploy" -eq 1 ]; then
    facets="${facets}lifecycle:deploy
"
  fi

  if dev_kit_repo_has_any_glob_from_list "$repo_dir" "workflow_globs" && \
     dev_kit_repo_has_pattern_in_glob_list "$repo_dir" "workflow_globs" "workflow_contract"; then
    facets="${facets}workflow:github
"
    if dev_kit_repo_has_any_file_from_list "$repo_dir" "workflow_primary_files" || \
       { [ "$has_wordpress" -eq 0 ] && \
         [ "$has_kubernetes" -eq 0 ] && \
         [ "$has_container" -eq 0 ] && \
         [ "$has_worker_deploy" -eq 0 ] && \
         ! dev_kit_has_file "$repo_dir" "package.json" && \
         ! dev_kit_has_file "$repo_dir" "composer.json" && \
         ! dev_kit_repo_has_any_file_from_list "$repo_dir" "deploy_files"; }; then
      facets="${facets}repo:workflow-primary
"
    fi
  fi

  if dev_kit_has_file "$repo_dir" "package.json" && \
     { [ "$has_container" -eq 1 ] || [ "$has_worker_deploy" -eq 1 ] || dev_kit_repo_has_any_file_from_list "$repo_dir" "deploy_files"; } && \
     dev_kit_repo_has_any_dir_from_signal_list "$repo_dir" "automation_dirs"; then
    facets="${facets}workload:automation
"
  fi

  if [ -z "$facets" ]; then
    DEV_KIT_REPO_FACETS_CACHE_REPO="$repo_dir"
    DEV_KIT_REPO_FACETS_CACHE_VALUE=""
    return 0
  fi

  DEV_KIT_REPO_FACETS_CACHE_REPO="$repo_dir"
  DEV_KIT_REPO_FACETS_CACHE_VALUE="$(printf "%s" "$facets" | awk '!seen[$0]++')"
  printf "%s" "$DEV_KIT_REPO_FACETS_CACHE_VALUE"
}

dev_kit_repo_has_facet() {
  local repo_dir="$1"
  local facet="$2"
  local facets=""

  facets="$(dev_kit_repo_facets "$repo_dir")"
  dev_kit_repo_has_facet_in_text "$facets" "$facet"
}

dev_kit_repo_matches_configured_archetype() {
  local repo_dir="$1"
  local archetype="$2"
  local facet=""
  local facets=""

  facets="$(dev_kit_repo_facets "$repo_dir")"

  while IFS= read -r facet; do
    [ -n "$facet" ] || continue
    if ! dev_kit_repo_has_facet_in_text "$facets" "$facet"; then
      return 1
    fi
  done <<EOF
$(dev_kit_archetype_facets "$archetype" "required")
EOF

  return 0
}

dev_kit_repo_configured_archetypes() {
  local repo_dir="$1"
  local archetype=""

  while IFS= read -r archetype; do
    [ -n "$archetype" ] || continue
    if dev_kit_repo_matches_configured_archetype "$repo_dir" "$archetype"; then
      printf "%s\n" "$archetype"
    fi
  done <<EOF
$(dev_kit_archetype_rule_list "configured")
EOF
}

dev_kit_repo_legacy_archetypes() {
  local repo_dir="$1"
  local archetypes=""
  local facets=""
  local has_dependency_manifest=0
  local has_runtime_signal=0
  local has_build_signal=0
  local has_shell_surface=0
  local has_container=0
  local has_deploy_signal=0
  local has_workflow_signal=0

  facets="$(dev_kit_repo_facets "$repo_dir")"

  if dev_kit_repo_has_facet_in_text "$facets" "package:node" || \
     dev_kit_repo_has_facet_in_text "$facets" "package:composer" || \
     dev_kit_repo_has_any_file_from_list "$repo_dir" "dependency_manifest_files"; then
    has_dependency_manifest=1
  fi

  if dev_kit_repo_has_facet_in_text "$facets" "lifecycle:runtime" || \
     dev_kit_repo_has_any_file_from_list "$repo_dir" "runtime_files" || \
     dev_kit_repo_has_make_target "$repo_dir" "run" || \
     dev_kit_repo_documented_command "$repo_dir" "run" >/dev/null; then
    has_runtime_signal=1
  fi

  if dev_kit_repo_has_facet_in_text "$facets" "lifecycle:build" || \
     dev_kit_repo_has_any_file_from_list "$repo_dir" "dependency_partial_files" || \
     dev_kit_repo_has_make_target "$repo_dir" "build" || \
     dev_kit_repo_documented_command "$repo_dir" "build" >/dev/null; then
    has_build_signal=1
  fi

  if dev_kit_repo_has_any_dir_from_list "$repo_dir" "shell_dirs" || dev_kit_repo_has_any_glob_from_list "$repo_dir" "shell_globs"; then
    has_shell_surface=1
  fi

  if dev_kit_repo_has_facet_in_text "$facets" "runtime:container"; then
    has_container=1
  fi

  if dev_kit_repo_has_facet_in_text "$facets" "lifecycle:deploy"; then
    has_deploy_signal=1
  fi

  if dev_kit_repo_has_facet_in_text "$facets" "workflow:github"; then
    has_workflow_signal=1
  fi

  if [ "$has_container" -eq 1 ] && { [ "$has_runtime_signal" -eq 1 ] || [ "$has_build_signal" -eq 1 ] || [ "$has_deploy_signal" -eq 1 ]; }; then
    archetypes="${archetypes}runtime-image
"
  fi

  if [ "$has_dependency_manifest" -eq 1 ] && { [ "$has_runtime_signal" -eq 1 ] || [ "$has_build_signal" -eq 1 ] || [ "$has_deploy_signal" -eq 1 ]; }; then
    archetypes="${archetypes}application
"
  fi

  if [ "$has_dependency_manifest" -eq 1 ] && [ "$has_runtime_signal" -eq 0 ] && [ "$has_build_signal" -eq 0 ]; then
    archetypes="${archetypes}library-cli
"
  fi

  if [ "$has_dependency_manifest" -eq 0 ] && [ "$has_shell_surface" -eq 1 ] && [ "$has_runtime_signal" -eq 0 ] && [ "$has_workflow_signal" -eq 0 ]; then
    archetypes="${archetypes}library-cli
"
  fi

  if [ "$has_deploy_signal" -eq 1 ] || dev_kit_repo_has_any_dir_from_list "$repo_dir" "infra_dirs"; then
    archetypes="${archetypes}infra-config
"
  fi

  printf "%s" "$archetypes" | awk 'NF && !seen[$0]++'
}

dev_kit_repo_archetypes() {
  local repo_dir="$1"
  local archetypes=""

  if [ "$DEV_KIT_REPO_ARCHETYPES_CACHE_REPO" = "$repo_dir" ]; then
    printf "%s" "$DEV_KIT_REPO_ARCHETYPES_CACHE_VALUE"
    return 0
  fi

  archetypes="$(printf '%s\n%s\n' "$(dev_kit_repo_configured_archetypes "$repo_dir")" "$(dev_kit_repo_legacy_archetypes "$repo_dir")" | awk 'NF && !seen[$0]++')"

  if [ -z "$archetypes" ]; then
    DEV_KIT_REPO_ARCHETYPES_CACHE_REPO="$repo_dir"
    DEV_KIT_REPO_ARCHETYPES_CACHE_VALUE="unknown"
    printf "%s\n" "unknown"
    return 0
  fi

  DEV_KIT_REPO_ARCHETYPES_CACHE_REPO="$repo_dir"
  DEV_KIT_REPO_ARCHETYPES_CACHE_VALUE="$(printf "%s" "$archetypes" | awk '!seen[$0]++')"
  printf "%s" "$DEV_KIT_REPO_ARCHETYPES_CACHE_VALUE"
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

  while IFS= read -r archetype; do
    [ -n "$archetype" ] || continue
    case "
$archetypes
" in
      *"
$archetype
"*) printf "%s" "$archetype"; return 0 ;;
    esac
  done <<EOF
$(dev_kit_archetype_rule_list "precedence")
EOF

  printf "%s" "unknown"
}

dev_kit_repo_archetypes_text() {
  dev_kit_repo_archetypes "$1" | dev_kit_lines_to_csv
}

dev_kit_repo_archetypes_json() {
  dev_kit_repo_archetypes "$1" | dev_kit_lines_to_json_array
}

dev_kit_repo_facets_text() {
  local facets=""

  facets="$(dev_kit_repo_facets "$1")"
  if [ -z "$facets" ]; then
    printf "%s" "none"
    return 0
  fi

  printf "%s" "$facets" | dev_kit_lines_to_csv
}

dev_kit_repo_facets_json() {
  local facets=""

  facets="$(dev_kit_repo_facets "$1")"
  if [ -z "$facets" ]; then
    printf "%s" "[]"
    return 0
  fi

  printf "%s" "$facets" | dev_kit_lines_to_json_array
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
