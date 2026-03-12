#!/usr/bin/env bash

dev_kit_repo_name() {
  basename "${1:-$(pwd)}"
}

dev_kit_has_file() {
  local repo_dir="$1"
  local path="$2"
  [ -e "$repo_dir/$path" ]
}

dev_kit_repo_has_glob() {
  local repo_dir="$1"
  local pattern="$2"

  find "$repo_dir" -path "$repo_dir/.git" -prune -o -type f -name "$pattern" -print -quit | grep -q .
}

dev_kit_repo_has_dir() {
  local repo_dir="$1"
  local path="$2"
  [ -d "$repo_dir/$path" ]
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

dev_kit_repo_find_from_glob_list() {
  local repo_dir="$1"
  local list_name="$2"
  local pattern=""

  while IFS= read -r pattern; do
    [ -n "$pattern" ] || continue
    find "$repo_dir" -path "$repo_dir/.git" -prune -o -type f -path "$repo_dir/$pattern" -print
  done <<EOF
$(dev_kit_detection_list "$list_name")
EOF
}

dev_kit_repo_markdown_files() {
  local repo_dir="$1"

  dev_kit_repo_find_from_glob_list "$repo_dir" "markdown_file_globs" | sort
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

dev_kit_repo_has_node_test_script() {
  local repo_dir="$1"

  [ -f "$repo_dir/package.json" ] || return 1

  awk '
    /"scripts"[[:space:]]*:[[:space:]]*{/ { in_scripts=1 }
    in_scripts && /"test"[[:space:]]*:/ { found=1 }
    in_scripts && /}/ { if (!found) exit }
    END { exit found ? 0 : 1 }
  ' "$repo_dir/package.json"
}

dev_kit_repo_has_composer_test_script() {
  local repo_dir="$1"

  [ -f "$repo_dir/composer.json" ] || return 1

  awk '
    /"scripts"[[:space:]]*:[[:space:]]*{/ { in_scripts=1 }
    in_scripts && /"test"[[:space:]]*:/ { found=1 }
    in_scripts && /}/ { if (!found) exit }
    END { exit found ? 0 : 1 }
  ' "$repo_dir/composer.json"
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

  printf "%s" "$profiles"
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
  local repo_dir="$1"

  dev_kit_repo_profiles "$repo_dir" | dev_kit_lines_to_csv
}

dev_kit_repo_profiles_json() {
  local repo_dir="$1"

  dev_kit_repo_profiles "$repo_dir" | dev_kit_lines_to_json_array
}

dev_kit_repo_readme_status() {
  local repo_dir="$1"

  if dev_kit_repo_has_any_file_from_list "$repo_dir" "documentation_files"; then
    printf "%s" "present"
    return 0
  fi

  printf "%s" "missing"
}

dev_kit_repo_documented_env_var() {
  local repo_dir="$1"
  local doc_file=""
  local regex=""

  regex="$(dev_kit_detection_pattern "env_var")"
  [ -n "$regex" ] || return 1

  while IFS= read -r doc_file; do
    if awk -v regex="$regex" '
      match($0, regex) {
        found=1
        exit
      }
      END { exit found ? 0 : 1 }
    ' "$doc_file" >/dev/null 2>&1; then
      return 0
    fi
  done <<EOF
$(dev_kit_repo_markdown_files "$repo_dir")
EOF

  return 1
}

dev_kit_repo_factor_status() {
  local repo_dir="$1"
  local factor="$2"

  case "$factor" in
    documentation)
      dev_kit_repo_readme_status "$repo_dir"
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
      if dev_kit_repo_has_any_file_from_list "$repo_dir" "config_contract_files"; then
        printf "%s" "present"
      elif dev_kit_repo_documented_env_var "$repo_dir"; then
        printf "%s" "partial"
      else
        printf "%s" "missing"
      fi
      ;;
    verification)
      if dev_kit_repo_has_make_target "$repo_dir" "test" || dev_kit_repo_has_node_test_script "$repo_dir" || dev_kit_repo_has_composer_test_script "$repo_dir" || dev_kit_repo_documented_command "$repo_dir" "verification" >/dev/null; then
        printf "%s" "present"
      elif dev_kit_repo_has_any_dir_from_list "$repo_dir" "test_dirs" || dev_kit_repo_has_any_file_from_list "$repo_dir" "verification_files" || dev_kit_repo_has_any_glob_from_list "$repo_dir" "verification_globs"; then
        printf "%s" "partial"
      else
        printf "%s" "missing"
      fi
      ;;
    runtime)
      if dev_kit_repo_has_any_file_from_list "$repo_dir" "runtime_files" || dev_kit_repo_has_make_target "$repo_dir" "run" || dev_kit_repo_documented_command "$repo_dir" "run" >/dev/null; then
        printf "%s" "present"
      elif dev_kit_repo_has_any_dir_from_list "$repo_dir" "shell_dirs"; then
        printf "%s" "partial"
      else
        printf "%s" "missing"
      fi
      ;;
    build_release_run)
      if (dev_kit_repo_has_any_file_from_list "$repo_dir" "dependency_partial_files" || dev_kit_repo_documented_command "$repo_dir" "build" >/dev/null || dev_kit_repo_has_make_target "$repo_dir" "build") && (dev_kit_repo_documented_command "$repo_dir" "run" >/dev/null || dev_kit_repo_has_make_target "$repo_dir" "run" || dev_kit_has_file "$repo_dir" "Procfile"); then
        printf "%s" "present"
      elif dev_kit_repo_has_any_file_from_list "$repo_dir" "dependency_partial_files" || dev_kit_repo_documented_command "$repo_dir" "build" >/dev/null || dev_kit_repo_documented_command "$repo_dir" "run" >/dev/null || dev_kit_repo_has_make_target "$repo_dir" "build" || dev_kit_repo_has_make_target "$repo_dir" "run"; then
        printf "%s" "partial"
      else
        printf "%s" "missing"
      fi
      ;;
    *) printf "%s" "unknown" ;;
  esac
}

dev_kit_repo_factor_evidence() {
  local repo_dir="$1"
  local factor="$2"
  local evidence=""
  local documented=""

  case "$factor" in
    documentation)
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        if dev_kit_has_file "$repo_dir" "$path"; then
          evidence="${evidence}${path}
"
        fi
      done <<EOF
$(dev_kit_detection_list "documentation_files")
EOF
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
$(dev_kit_detection_list "verification_globs")
EOF
      ;;
    runtime)
      while IFS= read -r path; do
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
      if dev_kit_repo_has_any_file_from_list "$repo_dir" "dependency_partial_files"; then
        evidence="${evidence}Dockerfile
"
      fi
      if dev_kit_has_file "$repo_dir" "Procfile"; then
        evidence="${evidence}Procfile
"
      fi
      ;;
    *) ;;
  esac

  if [ -z "$evidence" ]; then
    printf "%s\n" "none"
    return 0
  fi

  printf "%s" "$evidence" | awk '!seen[$0]++'
}

dev_kit_repo_factor_evidence_text() {
  local repo_dir="$1"
  local factor="$2"

  dev_kit_repo_factor_evidence "$repo_dir" "$factor" | dev_kit_lines_to_csv
}

dev_kit_repo_factor_evidence_json() {
  local repo_dir="$1"
  local factor="$2"

  dev_kit_repo_factor_evidence "$repo_dir" "$factor" | dev_kit_lines_to_json_array
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
    *) command="" ;;
  esac

  if [ -n "$command" ]; then
    printf "%s" "$command"
    return 0
  fi

  return 1
}

dev_kit_repo_factor_ids() {
  printf '%s\n' documentation dependencies config verification runtime build_release_run
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
    verification:missing) printf "%s" "missing-verification-entrypoint" ;;
    verification:partial) printf "%s" "partial-verification-entrypoint" ;;
    runtime:missing) printf "%s" "missing-runtime-entrypoint" ;;
    runtime:partial) printf "%s" "partial-runtime-entrypoint" ;;
    build_release_run:missing) printf "%s" "missing-build-release-run" ;;
    build_release_run:partial) printf "%s" "partial-build-release-run" ;;
    *) return 1 ;;
  esac
}

dev_kit_repo_findings_json() {
  local repo_dir="$1"
  local emitted=0
  local factor=""
  local status=""
  local rule_id=""
  local message=""

  printf "["
  while IFS= read -r factor; do
    status="$(dev_kit_repo_factor_status "$repo_dir" "$factor")"
    rule_id="$(dev_kit_repo_factor_rule_id "$factor" "$status" || true)"
    [ -n "$rule_id" ] || continue
    message="$(dev_kit_rule_message "$rule_id")"
    if [ "$emitted" -eq 1 ]; then
      printf ","
    fi
    printf '\n    { "id": "%s", "factor": "%s", "status": "%s", "message": "%s" }' "$rule_id" "$factor" "$status" "$message"
    emitted=1
  done <<EOF
$(dev_kit_repo_factor_ids)
EOF

  if [ "$emitted" -eq 1 ]; then
    printf '\n  '
  fi

  printf "]"
}

dev_kit_repo_advices() {
  local repo_dir="$1"
  local factor=""
  local status=""
  local rule_id=""

  while IFS= read -r factor; do
    status="$(dev_kit_repo_factor_status "$repo_dir" "$factor")"
    rule_id="$(dev_kit_repo_factor_rule_id "$factor" "$status" || true)"
    [ -n "$rule_id" ] || continue
    printf 'advice: %s\n' "$(dev_kit_rule_message "$rule_id")"
  done <<EOF
$(dev_kit_repo_factor_ids)
EOF
}

dev_kit_repo_factor_summary_json() {
  local repo_dir="$1"
  local factor=""
  local status=""
  local first=1

  printf "{"
  while IFS= read -r factor; do
    status="$(dev_kit_repo_factor_status "$repo_dir" "$factor")"
    if [ "$first" -eq 0 ]; then
      printf ","
    fi
    printf '\n    "%s": {' "$factor"
    printf '\n      "status": "%s",' "$status"
    printf '\n      "evidence": '
    dev_kit_repo_factor_evidence_json "$repo_dir" "$factor"
    if dev_kit_repo_factor_entrypoint "$repo_dir" "$factor" >/dev/null 2>&1; then
      printf ',\n      "entrypoint": "%s"\n    }' "$(dev_kit_repo_factor_entrypoint "$repo_dir" "$factor")"
    else
      printf '\n    }'
    fi
    first=0
  done <<EOF
$(dev_kit_repo_factor_ids)
EOF
  printf '\n  }'
}

dev_kit_repo_agent_guidance_json() {
  local repo_dir="$1"
  local factor=""
  local first=1
  local status=""
  local entrypoint=""
  local guidance=""

  printf "["
  while IFS= read -r factor; do
    status="$(dev_kit_repo_factor_status "$repo_dir" "$factor")"
    case "$factor:$status" in
      verification:present)
        entrypoint="$(dev_kit_repo_factor_entrypoint "$repo_dir" "verification" || true)"
        guidance="Use ${entrypoint} as the canonical verification step before and after changes."
        ;;
      verification:partial)
        guidance="Verification assets exist, but the canonical test entrypoint is not normalized yet."
        ;;
      config:present)
        guidance="Treat configuration as external to code and preserve the documented config contract."
        ;;
      config:partial)
        guidance="Config signals exist, but the environment contract is incomplete or only partially documented."
        ;;
      runtime:present)
        entrypoint="$(dev_kit_repo_factor_entrypoint "$repo_dir" "runtime" || true)"
        guidance="Use ${entrypoint:-the documented runtime entrypoint} to reproduce runtime behavior instead of inventing ad hoc commands."
        ;;
      build_release_run:present)
        guidance="Keep build and runtime steps separated; use the discovered build/run entrypoints instead of editing in place."
        ;;
      documentation:missing)
        guidance="Expect more agent ambiguity until a repository README defines purpose and workflow."
        ;;
      *)
        guidance=""
        ;;
    esac
    [ -n "$guidance" ] || continue
    if [ "$first" -eq 0 ]; then
      printf ", "
    fi
    printf '"%s"' "$guidance"
    first=0
  done <<EOF
$(dev_kit_repo_factor_ids)
EOF
  printf "]"
}

dev_kit_repo_agent_guidance_text() {
  local repo_dir="$1"
  local factor=""
  local status=""
  local entrypoint=""
  local guidance=""

  while IFS= read -r factor; do
    status="$(dev_kit_repo_factor_status "$repo_dir" "$factor")"
    case "$factor:$status" in
      verification:present)
        entrypoint="$(dev_kit_repo_factor_entrypoint "$repo_dir" "verification" || true)"
        guidance="Use ${entrypoint} as the canonical verification step before and after changes."
        ;;
      verification:partial)
        guidance="Verification assets exist, but the canonical test entrypoint is not normalized yet."
        ;;
      config:present)
        guidance="Treat configuration as external to code and preserve the documented config contract."
        ;;
      config:partial)
        guidance="Config signals exist, but the environment contract is incomplete or only partially documented."
        ;;
      runtime:present)
        entrypoint="$(dev_kit_repo_factor_entrypoint "$repo_dir" "runtime" || true)"
        guidance="Use ${entrypoint:-the documented runtime entrypoint} to reproduce runtime behavior instead of inventing ad hoc commands."
        ;;
      build_release_run:present)
        guidance="Keep build and runtime steps separated; use the discovered build and run entrypoints instead of editing in place."
        ;;
      documentation:missing)
        guidance="Expect more agent ambiguity until a repository README defines purpose and workflow."
        ;;
      *)
        guidance=""
        ;;
    esac
    [ -n "$guidance" ] || continue
    printf '%s\n' "$guidance"
  done <<EOF
$(dev_kit_repo_factor_ids)
EOF
}
