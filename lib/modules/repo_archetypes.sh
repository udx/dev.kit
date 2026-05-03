#!/usr/bin/env bash

DEV_KIT_REPO_FACETS_CACHE_REPO=""
DEV_KIT_REPO_FACETS_CACHE_VALUE=""
DEV_KIT_REPO_ARCHETYPES_CACHE_REPO=""
DEV_KIT_REPO_ARCHETYPES_CACHE_VALUE=""

dev_kit_repo_has_kubernetes_manifest() {
  local repo_dir="$1"
  local file_path=""

  while IFS= read -r file_path; do
    [ -n "$file_path" ] || continue
    if dev_kit_repo_file_has_all_patterns "$file_path" "yaml_api_version" "yaml_kind"; then
      return 0
    fi
  done <<EOF
$(dev_kit_repo_find_from_glob_list "$repo_dir" "yaml_manifest_globs")
EOF

  return 1
}

dev_kit_repo_has_yaml_manifest() {
  local repo_dir="$1"
  local file_path=""
  local rel_path=""

  while IFS= read -r file_path; do
    [ -n "$file_path" ] || continue
    rel_path="${file_path#"${repo_dir}/"}"
    case "$rel_path" in
      .github/workflows/*|.rabbit/context.yaml) continue ;;
    esac
    if awk '
      /^[[:space:]]*#/ { next }
      /^[[:space:]]*(kind|apiVersion|version|services|resources|modules|config):[[:space:]]*/ { found=1; exit }
      END { exit found ? 0 : 1 }
    ' "$file_path"; then
      return 0
    fi
  done <<EOF
$(dev_kit_repo_find_from_glob_list "$repo_dir" "yaml_manifest_globs")
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

  if [ "$has_wordpress" -eq 0 ] && { dev_kit_repo_has_any_file_from_list "$repo_dir" "wordpress_files" || \
     dev_kit_repo_has_any_dir_from_list "$repo_dir" "wordpress_dirs"; }; then
    has_wordpress=1
    facets="${facets}framework:wordpress
"
  fi

  if dev_kit_repo_has_next_app "$repo_dir"; then
    facets="${facets}framework:next
"
  fi

  if dev_kit_repo_has_yaml_manifest "$repo_dir"; then
    facets="${facets}manifest:yaml
"
  fi

  # K8s: only actual manifests with apiVersion + kind — chart metadata alone does not imply platform:kubernetes
  if dev_kit_repo_has_kubernetes_manifest "$repo_dir"; then
    has_kubernetes=1
    facets="${facets}platform:kubernetes
deploy:kubernetes-manifests
"
  fi

  # Terraform: standalone detection independent of K8s
  if dev_kit_repo_has_any_file_from_list "$repo_dir" "terraform_files" || \
     dev_kit_repo_has_any_dir_from_list "$repo_dir" "terraform_dirs" || \
     dev_kit_repo_has_any_glob_from_list "$repo_dir" "terraform_globs"; then
    facets="${facets}deploy:terraform
"
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

  if dev_kit_repo_has_node_bin "$repo_dir"; then
    facets="${facets}package:cli
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
     dev_kit_repo_has_facet_in_text "$facets" "deploy:terraform" || \
     dev_kit_repo_has_facet_in_text "$facets" "deploy:kubernetes-manifests"; then
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
         ! dev_kit_has_file "$repo_dir" "package.json" && \
         ! dev_kit_has_file "$repo_dir" "composer.json" && \
         ! dev_kit_repo_has_any_file_from_list "$repo_dir" "deploy_files"; }; then
      facets="${facets}repo:workflow-primary
"
    fi
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
$(dev_kit_archetype_rule_ids)
EOF
}

dev_kit_repo_archetypes() {
  local repo_dir="$1"
  local _ck="archetypes:${repo_dir}"
  local _cv

  # File cache (survives subshell boundaries)
  if _cv="$(dev_kit_cache_get "$_ck")"; then
    printf '%s' "$_cv"; return 0
  fi

  # Global variable cache (fast within same process, lost across subshells)
  if [ "$DEV_KIT_REPO_ARCHETYPES_CACHE_REPO" = "$repo_dir" ]; then
    dev_kit_cache_set "$_ck" "$DEV_KIT_REPO_ARCHETYPES_CACHE_VALUE"
    printf "%s" "$DEV_KIT_REPO_ARCHETYPES_CACHE_VALUE"
    return 0
  fi

  local archetypes=""
  archetypes="$(dev_kit_repo_configured_archetypes "$repo_dir")"

  local result="unknown"
  if [ -n "$archetypes" ]; then
    result="$(printf "%s" "$archetypes" | awk '!seen[$0]++')"
  fi

  DEV_KIT_REPO_ARCHETYPES_CACHE_REPO="$repo_dir"
  DEV_KIT_REPO_ARCHETYPES_CACHE_VALUE="$result"
  dev_kit_cache_set "$_ck" "$result"
  printf '%s' "$result"
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
  local _ck="archetype:${repo_dir}"
  local _cv
  if _cv="$(dev_kit_cache_get "$_ck")"; then
    printf '%s' "$_cv"; return 0
  fi

  local archetypes="" archetype="" _result="unknown"
  archetypes="$(dev_kit_repo_archetypes "$repo_dir")"
  while IFS= read -r archetype; do
    [ -n "$archetype" ] || continue
    case "
$archetypes
" in
      *"
$archetype
"*) _result="$archetype"; break ;;
    esac
  done <<EOF
$(dev_kit_archetype_rule_ids)
EOF

  dev_kit_cache_set "$_ck" "$_result"
  printf '%s' "$_result"
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
