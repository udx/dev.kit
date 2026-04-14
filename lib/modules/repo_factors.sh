#!/usr/bin/env bash

dev_kit_repo_factor_applicable() {
  local repo_dir="$1"
  local factor="$2"

  case "$factor" in
    documentation|config|pipeline)
      return 0
      ;;
    dependencies)
      # Always applicable for archetypes that must have dependency manifests
      if dev_kit_repo_has_archetype "$repo_dir" "application" || \
         dev_kit_repo_has_archetype "$repo_dir" "runtime-image"; then
        return 0
      fi
      # For all other archetypes: only applicable if manifest files exist
      if dev_kit_repo_has_any_file_from_list "$repo_dir" "dependency_manifest_files" || \
         dev_kit_repo_has_any_file_from_list "$repo_dir" "dependency_partial_files"; then
        return 0
      fi
      return 1
      ;;
    *)
      return 1
      ;;
  esac
}

dev_kit_repo_factor_status() {
  local repo_dir="$1"
  local factor="$2"
  local _ck="fstatus:${repo_dir}:${factor}"
  local _cv
  if _cv="$(dev_kit_cache_get "$_ck")"; then
    printf '%s' "$_cv"; return 0
  fi
  local _result
  _result="$(_dev_kit_repo_factor_status_compute "$repo_dir" "$factor")"
  dev_kit_cache_set "$_ck" "$_result"
  printf '%s' "$_result"
}

_dev_kit_repo_factor_status_compute() {
  local repo_dir="$1"
  local factor="$2"
  local present_threshold=""
  local partial_threshold=""

  if ! dev_kit_repo_factor_applicable "$repo_dir" "$factor"; then
    printf "%s" "not_applicable"
    return 0
  fi

  case "$factor" in
    documentation)
      # README or docs/ is enough — no deep validation needed
      if dev_kit_repo_has_any_file_from_list "$repo_dir" "documentation_files" || \
         dev_kit_repo_has_any_file_from_list "$repo_dir" "documentation_hub_files"; then
        printf "%s" "present"
      else
        printf "%s" "missing"
      fi
      ;;
    dependencies)
      if dev_kit_repo_has_any_file_from_list "$repo_dir" "dependency_manifest_files"; then
        printf "%s" "present"
      elif dev_kit_repo_has_any_file_from_list "$repo_dir" "dependency_partial_files"; then
        printf "%s" "partial"
      else
        printf "%s" "missing"
      fi
      ;;
    config)
      if dev_kit_repo_has_any_file_from_list "$repo_dir" "config_contract_files" && dev_kit_repo_documented_env_var "$repo_dir"; then
        printf "%s" "present"
      elif dev_kit_repo_has_any_file_from_list "$repo_dir" "config_contract_files" || dev_kit_repo_documented_env_var "$repo_dir"; then
        printf "%s" "partial"
      else
        printf "%s" "missing"
      fi
      ;;
    pipeline)
      # CI/CD pipeline: workflows, test commands, deploy configs are all the same signal.
      if dev_kit_repo_has_any_glob_from_list "$repo_dir" "workflow_globs" && \
         (dev_kit_repo_has_make_target "$repo_dir" "test" || \
          dev_kit_repo_has_node_test_script "$repo_dir" || \
          dev_kit_repo_has_composer_test_script "$repo_dir" || \
          dev_kit_repo_has_any_file_from_list "$repo_dir" "deploy_files" || \
          dev_kit_repo_has_any_dir_from_list "$repo_dir" "infra_dirs"); then
        printf "%s" "present"
      elif dev_kit_repo_has_any_glob_from_list "$repo_dir" "workflow_globs" || \
           dev_kit_repo_has_any_dir_from_list "$repo_dir" "test_dirs" || \
           dev_kit_repo_has_any_file_from_list "$repo_dir" "deploy_files" || \
           dev_kit_repo_has_any_file_from_list "$repo_dir" "container_files"; then
        printf "%s" "partial"
      else
        printf "%s" "missing"
      fi
      ;;
    *)
      printf "%s" "unknown"
      ;;
  esac
}

dev_kit_repo_factor_evidence() {
  local repo_dir="$1"
  local factor="$2"
  local evidence=""
  local documented=""
  local path=""
  local pattern=""

  if ! dev_kit_repo_factor_applicable "$repo_dir" "$factor"; then
    printf "%s\n" "not applicable"
    return 0
  fi

  case "$factor" in
    documentation)
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        if dev_kit_has_file "$repo_dir" "$path"; then
          evidence="${evidence}${path}
"
        fi
      done <<EOF
$(printf '%s\n%s\n' "$(dev_kit_detection_list "documentation_files")" "$(dev_kit_detection_list "documentation_hub_files")")
EOF
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        if dev_kit_repo_has_dir "$repo_dir" "$path"; then
          evidence="${evidence}${path}/
"
        fi
      done <<EOF
$(dev_kit_detection_list "example_dirs")
EOF
      if dev_kit_repo_has_documentation_sections "$repo_dir"; then
        evidence="${evidence}structured docs sections
"
      fi
      ;;
    dependencies)
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        if dev_kit_has_file "$repo_dir" "$path"; then
          evidence="${evidence}${path}
"
        fi
      done <<EOF
$(printf '%s\n%s\n' "$(dev_kit_detection_list "dependency_manifest_files")" "$(dev_kit_detection_list "dependency_partial_files")")
EOF
      ;;
    config)
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        if dev_kit_has_file "$repo_dir" "$path"; then
          evidence="${evidence}${path}
"
        fi
      done <<EOF
$(dev_kit_detection_list "config_contract_files")
EOF
      if dev_kit_repo_documented_env_var "$repo_dir"; then
        evidence="${evidence}documented env vars
"
      fi
      ;;
    pipeline)
      # Test signals
      if dev_kit_repo_has_make_target "$repo_dir" "test"; then
        evidence="${evidence}Makefile:test
"
      fi
      if dev_kit_repo_has_node_test_script "$repo_dir"; then
        evidence="${evidence}package.json scripts.test
"
      fi
      if dev_kit_repo_has_composer_test_script "$repo_dir"; then
        evidence="${evidence}composer.json scripts.test
"
      fi
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        if dev_kit_has_file "$repo_dir" "$path" || dev_kit_repo_has_dir "$repo_dir" "$path"; then
          evidence="${evidence}${path}
"
        fi
      done <<EOF
$(dev_kit_detection_list "test_dirs")
EOF
      # Deploy/CI signals
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        if dev_kit_has_file "$repo_dir" "$path"; then
          evidence="${evidence}${path}
"
        fi
      done <<EOF
$(dev_kit_detection_list "deploy_files")
EOF
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        if dev_kit_repo_has_dir "$repo_dir" "$path"; then
          evidence="${evidence}${path}/
"
        fi
      done <<EOF
$(dev_kit_detection_list "infra_dirs")
EOF
      while IFS= read -r pattern; do
        [ -n "$pattern" ] || continue
        if dev_kit_repo_has_glob "$repo_dir" "$pattern"; then
          evidence="${evidence}${pattern}
"
        fi
      done <<EOF
$(dev_kit_detection_list "workflow_globs")
EOF
      ;;
    *)
      ;;
  esac

  if [ -z "$evidence" ]; then
    printf "%s\n" "none"
    return 0
  fi

  printf "%s" "$evidence" | awk '!seen[$0]++'
}

dev_kit_repo_factor_evidence_text() {
  dev_kit_repo_factor_evidence "$1" "$2" | dev_kit_lines_to_csv
}

dev_kit_repo_factor_evidence_json() {
  dev_kit_repo_factor_evidence "$1" "$2" | dev_kit_lines_to_json_array
}

dev_kit_repo_factor_entrypoint() {
  local repo_dir="$1"
  local factor="$2"
  local command=""

  case "$factor" in
    pipeline)
      if dev_kit_repo_has_make_target "$repo_dir" "test"; then
        printf "%s" "make test"
        return 0
      fi
      if dev_kit_repo_has_node_test_script "$repo_dir"; then
        printf "%s" "npm test"
        return 0
      fi
      if dev_kit_repo_has_composer_test_script "$repo_dir"; then
        printf "%s" "composer test"
        return 0
      fi
      command="$(dev_kit_repo_documented_command "$repo_dir" "verification" || true)"
      ;;
    *)
      command=""
      ;;
  esac

  if [ -n "$command" ]; then
    printf "%s" "$command"
    return 0
  fi

  return 1
}

dev_kit_repo_factor_ids() {
  printf '%s\n' documentation dependencies config pipeline
}

dev_kit_repo_factor_rule_id() {
  local factor="$1"
  local status="$2"

  case "${factor}:${status}" in
    documentation:missing) printf "%s" "missing-documentation" ;;
    dependencies:missing) printf "%s" "missing-dependency-manifest" ;;
    dependencies:partial) printf "%s" "partial-dependency-contract" ;;
    config:missing) printf "%s" "missing-config-contract" ;;
    config:partial) printf "%s" "partial-config-contract" ;;
    pipeline:missing) printf "%s" "missing-pipeline" ;;
    pipeline:partial) printf "%s" "partial-pipeline" ;;
    *) return 1 ;;
  esac
}
