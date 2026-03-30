#!/usr/bin/env bash

dev_kit_repo_factor_applicable() {
  local repo_dir="$1"
  local factor="$2"

  case "$factor" in
    documentation|architecture|config|verification)
      return 0
      ;;
    dependencies)
      if dev_kit_repo_has_any_file_from_list "$repo_dir" "dependency_manifest_files" || \
         dev_kit_repo_has_any_file_from_list "$repo_dir" "dependency_partial_files" || \
         dev_kit_repo_has_archetype "$repo_dir" "application" || \
         dev_kit_repo_has_archetype "$repo_dir" "library-cli" || \
         dev_kit_repo_has_archetype "$repo_dir" "runtime-image"; then
        return 0
      fi
      return 1
      ;;
    runtime)
      if dev_kit_repo_has_runtime_signals "$repo_dir" || \
         dev_kit_repo_has_archetype "$repo_dir" "application" || \
         dev_kit_repo_has_archetype "$repo_dir" "runtime-image"; then
        return 0
      fi
      return 1
      ;;
    build_release_run)
      if dev_kit_repo_has_build_signals "$repo_dir" || \
         dev_kit_repo_has_runtime_signals "$repo_dir" || \
         dev_kit_repo_has_archetype "$repo_dir" "application" || \
         dev_kit_repo_has_archetype "$repo_dir" "runtime-image"; then
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
  local present_threshold=""
  local partial_threshold=""

  if ! dev_kit_repo_factor_applicable "$repo_dir" "$factor"; then
    printf "%s" "not_applicable"
    return 0
  fi

  case "$factor" in
    documentation)
      if dev_kit_repo_has_any_file_from_list "$repo_dir" "documentation_files"; then
        printf "%s" "present"
      elif dev_kit_repo_has_any_file_from_list "$repo_dir" "documentation_hub_files" || \
           dev_kit_repo_has_documentation_sections "$repo_dir"; then
        printf "%s" "partial"
      else
        printf "%s" "missing"
      fi
      ;;
    architecture)
      present_threshold="$(dev_kit_detection_scalar "architecture_present_category_min")"
      partial_threshold="$(dev_kit_detection_scalar "architecture_partial_category_min")"
      [ -n "$present_threshold" ] || present_threshold=3
      [ -n "$partial_threshold" ] || partial_threshold=2
      if [ "$(dev_kit_repo_count_category_hits "$repo_dir")" -ge "$present_threshold" ] && \
         dev_kit_repo_has_thin_command_layer "$repo_dir" && \
         ! dev_kit_repo_has_oversized_module "$repo_dir"; then
        printf "%s" "present"
      elif [ "$(dev_kit_repo_count_category_hits "$repo_dir")" -ge "$partial_threshold" ] || \
           [ "$(dev_kit_repo_count_dir_hits_from_list "$repo_dir" "architecture_partial_dirs")" -ge 2 ] || \
           dev_kit_repo_has_architecture_sections "$repo_dir"; then
        printf "%s" "partial"
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
    verification)
      if dev_kit_repo_has_make_target "$repo_dir" "test" || \
         dev_kit_repo_has_node_test_script "$repo_dir" || \
         dev_kit_repo_has_composer_test_script "$repo_dir" || \
         dev_kit_repo_documented_command "$repo_dir" "verification" >/dev/null; then
        printf "%s" "present"
      elif dev_kit_repo_has_any_dir_from_list "$repo_dir" "test_dirs" || \
           dev_kit_repo_has_any_file_from_list "$repo_dir" "verification_files" || \
           dev_kit_repo_has_any_glob_from_list "$repo_dir" "verification_globs" || \
           dev_kit_repo_has_any_glob_from_list "$repo_dir" "workflow_globs"; then
        printf "%s" "partial"
      else
        printf "%s" "missing"
      fi
      ;;
    runtime)
      if dev_kit_repo_has_any_file_from_list "$repo_dir" "runtime_files" && \
         (dev_kit_repo_has_make_target "$repo_dir" "run" || dev_kit_repo_documented_command "$repo_dir" "run" >/dev/null || dev_kit_has_file "$repo_dir" "Procfile"); then
        printf "%s" "present"
      elif dev_kit_repo_has_runtime_signals "$repo_dir" || dev_kit_repo_has_any_dir_from_list "$repo_dir" "shell_dirs"; then
        printf "%s" "partial"
      else
        printf "%s" "missing"
      fi
      ;;
    build_release_run)
      if dev_kit_repo_has_build_signals "$repo_dir" && dev_kit_repo_has_runtime_signals "$repo_dir"; then
        printf "%s" "present"
      elif dev_kit_repo_has_build_signals "$repo_dir" || dev_kit_repo_has_runtime_signals "$repo_dir"; then
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
    architecture)
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        if dev_kit_repo_has_dir "$repo_dir" "$path"; then
          evidence="${evidence}${path}/
"
        fi
      done <<EOF
$(printf '%s\n%s\n' "$(dev_kit_detection_list "architecture_layer_dirs")" "$(dev_kit_detection_list "architecture_partial_dirs")")
EOF
      if dev_kit_repo_has_architecture_sections "$repo_dir"; then
        evidence="${evidence}documented architecture sections
"
      fi
      if dev_kit_repo_has_thin_command_layer "$repo_dir"; then
        evidence="${evidence}thin command layer
"
      fi
      if dev_kit_repo_has_oversized_module "$repo_dir"; then
        evidence="${evidence}oversized module detected
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
    verification)
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
      documented="$(dev_kit_repo_documented_command "$repo_dir" "verification" || true)"
      if [ -n "$documented" ]; then
        evidence="${evidence}docs: ${documented}
"
      fi
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        if dev_kit_has_file "$repo_dir" "$path" || dev_kit_repo_has_dir "$repo_dir" "$path"; then
          evidence="${evidence}${path}
"
        fi
      done <<EOF
$(printf '%s\n%s\n' "$(dev_kit_detection_list "test_dirs")" "$(dev_kit_detection_list "verification_files")")
EOF
      while IFS= read -r pattern; do
        [ -n "$pattern" ] || continue
        if dev_kit_repo_has_glob "$repo_dir" "$pattern"; then
          evidence="${evidence}${pattern}
"
        fi
      done <<EOF
$(printf '%s\n%s\n' "$(dev_kit_detection_list "verification_globs")" "$(dev_kit_detection_list "workflow_globs")")
EOF
      ;;
    runtime)
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        if dev_kit_has_file "$repo_dir" "$path"; then
          evidence="${evidence}${path}
"
        fi
      done <<EOF
$(dev_kit_detection_list "runtime_files")
EOF
      if dev_kit_repo_has_make_target "$repo_dir" "run"; then
        evidence="${evidence}Makefile:run
"
      fi
      documented="$(dev_kit_repo_documented_command "$repo_dir" "run" || true)"
      if [ -n "$documented" ]; then
        evidence="${evidence}docs: ${documented}
"
      fi
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        if dev_kit_repo_has_dir "$repo_dir" "$path"; then
          evidence="${evidence}${path}/
"
        fi
      done <<EOF
$(dev_kit_detection_list "shell_dirs")
EOF
      ;;
    build_release_run)
      if dev_kit_repo_has_make_target "$repo_dir" "build"; then
        evidence="${evidence}Makefile:build
"
      fi
      if dev_kit_repo_has_make_target "$repo_dir" "run"; then
        evidence="${evidence}Makefile:run
"
      fi
      documented="$(dev_kit_repo_documented_command "$repo_dir" "build" || true)"
      if [ -n "$documented" ]; then
        evidence="${evidence}docs build: ${documented}
"
      fi
      documented="$(dev_kit_repo_documented_command "$repo_dir" "run" || true)"
      if [ -n "$documented" ]; then
        evidence="${evidence}docs run: ${documented}
"
      fi
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        if dev_kit_has_file "$repo_dir" "$path"; then
          evidence="${evidence}${path}
"
        fi
      done <<EOF
$(printf '%s\n%s\n' "$(dev_kit_detection_list "dependency_partial_files")" "$(dev_kit_detection_list "runtime_files")")
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
    verification)
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
    runtime)
      if dev_kit_repo_has_make_target "$repo_dir" "run"; then
        printf "%s" "make run"
        return 0
      fi
      command="$(dev_kit_repo_documented_command "$repo_dir" "run" || true)"
      ;;
    build_release_run)
      if dev_kit_repo_has_make_target "$repo_dir" "build"; then
        printf "%s" "make build"
        return 0
      fi
      command="$(dev_kit_repo_documented_command "$repo_dir" "build" || true)"
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
  printf '%s\n' documentation architecture dependencies config verification runtime build_release_run
}

dev_kit_repo_factor_rule_id() {
  local factor="$1"
  local status="$2"

  case "${factor}:${status}" in
    documentation:missing) printf "%s" "missing-documentation" ;;
    architecture:missing) printf "%s" "missing-architecture-contract" ;;
    architecture:partial) printf "%s" "partial-architecture-contract" ;;
    dependencies:missing) printf "%s" "missing-dependency-manifest" ;;
    dependencies:partial) printf "%s" "partial-dependency-contract" ;;
    config:missing) printf "%s" "missing-config-contract" ;;
    config:partial) printf "%s" "partial-config-contract" ;;
    verification:missing) printf "%s" "missing-verification-entrypoint" ;;
    verification:partial) printf "%s" "partial-verification-entrypoint" ;;
    runtime:missing) printf "%s" "missing-runtime-entrypoint" ;;
    runtime:partial) printf "%s" "partial-runtime-entrypoint" ;;
    build_release_run:missing) printf "%s" "missing-build-release-run" ;;
    build_release_run:partial) printf "%s" "partial-build-release-run" ;;
    *) return 1 ;;
  esac
}
