#!/usr/bin/env bash

DEV_KIT_REMOTE_LOOKUPS="${DEV_KIT_REMOTE_LOOKUPS:-0}"
DEV_KIT_REPO_DEFAULT_BRANCH_CACHE=""
DEV_KIT_MODULE_REPO_DIR_CACHE=""

dev_kit_local_repos_root_path() {
  local root=""

  root="$(dev_kit_knowledge_local_repos_root)"
  [ -n "$root" ] || return 1
  printf "%s/%s" "$HOME" "$root"
}

dev_kit_repo_workflow_ref_lines() {
  local repo_dir="$1"
  local workflow_file=""
  local workflow_ref=""

  [ -d "$repo_dir/.github/workflows" ] || return 0

  while IFS= read -r workflow_file; do
    [ -n "$workflow_file" ] || continue
    while IFS= read -r workflow_ref; do
      [ -n "$workflow_ref" ] || continue
      printf '%s\n' "$workflow_ref"
    done <<EOF
$(grep -E '^[[:space:]]*uses:' "$workflow_file" | sed -n 's/^[[:space:]]*uses:[[:space:]]*"\{0,1\}\([^"[:space:]]*\)"\{0,1\}.*/\1/p' | awk '/^udx\//')
EOF
  done <<EOF
$(find "$repo_dir/.github/workflows" -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)
EOF
}

dev_kit_repo_workflow_refs_text() {
  local repo_dir="$1"
  local refs=""

  refs="$(dev_kit_repo_workflow_ref_lines "$repo_dir" | awk '!seen[$0]++')"
  if [ -z "$refs" ]; then
    printf "%s" "none"
    return 0
  fi

  printf "%s" "$refs" | dev_kit_lines_to_csv
}

dev_kit_repo_workflow_refs_json() {
  local repo_dir="$1"
  local refs=""

  refs="$(dev_kit_repo_workflow_ref_lines "$repo_dir" | awk '!seen[$0]++')"
  if [ -z "$refs" ]; then
    printf "%s" "[]"
    return 0
  fi

  printf "%s" "$refs" | dev_kit_lines_to_json_array
}

dev_kit_local_udx_repo_dirs() {
  local root=""

  root="$(dev_kit_local_repos_root_path 2>/dev/null || true)"
  [ -d "$root" ] || return 0
  find "$root" -mindepth 1 -maxdepth 1 -type d | sort
}

dev_kit_local_repo_path() {
  local repo_slug="$1"
  local root=""

  root="$(dev_kit_local_repos_root_path 2>/dev/null || true)"
  [ -n "$root" ] || return 1
  printf "%s/%s" "$root" "${repo_slug#*/}"
}

dev_kit_repo_slug_from_ref() {
  local ref="$1"
  printf "%s" "$ref" | awk -F'/' '{ if (NF >= 2) printf "%s/%s", $1, $2 }'
}

dev_kit_repo_is_udx_slug() {
  case "$1" in
    udx/*) return 0 ;;
  esac
  return 1
}

dev_kit_cache_get() {
  local cache_data="$1"
  local cache_key="$2"

  printf '%s\n' "$cache_data" | awk -F'|' -v key="$cache_key" '$1 == key { print substr($0, index($0, "|") + 1); exit }'
}

dev_kit_cache_put() {
  local cache_name="$1"
  local cache_key="$2"
  local cache_value="$3"
  local current=""

  current="$(eval "printf '%s' \"\${$cache_name:-}\"")"
  current="$(printf '%s\n' "$current" | awk -F'|' -v key="$cache_key" '$1 != key')"
  if [ -n "$current" ]; then
    current="${current}"$'\n'
  fi
  eval "$cache_name=\$(printf '%s' \"\$current\$cache_key|$cache_value\")"
}

dev_kit_repo_remote_default_branch() {
  local repo_slug="$1"
  local cached=""
  local repo_path=""
  local origin_head=""

  dev_kit_repo_is_udx_slug "$repo_slug" || return 1
  cached="$(dev_kit_cache_get "$DEV_KIT_REPO_DEFAULT_BRANCH_CACHE" "$repo_slug")"
  if [ -n "$cached" ]; then
    printf '%s' "$cached"
    return 0
  fi

  repo_path="$(dev_kit_local_repo_path "$repo_slug" 2>/dev/null || true)"
  if [ -d "$repo_path/.git" ]; then
    origin_head="$(git -C "$repo_path" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || true)"
    if [ -n "$origin_head" ]; then
      origin_head="${origin_head##*/}"
      dev_kit_cache_put "DEV_KIT_REPO_DEFAULT_BRANCH_CACHE" "$repo_slug" "$origin_head"
      printf '%s' "$origin_head"
      return 0
    fi
  fi

  if [ "$DEV_KIT_REMOTE_LOOKUPS" != "1" ]; then
    return 0
  fi

  command -v gh >/dev/null 2>&1 || return 1
  cached="$(gh api "repos/$repo_slug" --jq '.default_branch' 2>/dev/null || true)"
  if [ -n "$cached" ]; then
    dev_kit_cache_put "DEV_KIT_REPO_DEFAULT_BRANCH_CACHE" "$repo_slug" "$cached"
    printf '%s' "$cached"
  fi
}

dev_kit_ref_path_without_repo() {
  local ref="$1"
  printf "%s" "$ref" | cut -d/ -f3-
}

dev_kit_ref_without_version() {
  local ref="$1"
  printf "%s" "${ref%@*}"
}

dev_kit_repo_ref_local_file() {
  local ref="$1"
  local repo_slug=""
  local repo_path=""
  local rel_path=""

  repo_slug="$(dev_kit_repo_slug_from_ref "$ref")"
  [ -n "$repo_slug" ] || return 1
  repo_path="$(dev_kit_local_repo_path "$repo_slug" 2>/dev/null || true)"
  rel_path="$(dev_kit_ref_path_without_repo "$(dev_kit_ref_without_version "$ref")")"
  [ -n "$repo_path" ] || return 1
  [ -n "$rel_path" ] || return 1
  printf "%s/%s" "$repo_path" "$rel_path"
}

dev_kit_repo_workflow_doc_candidate_paths() {
  local ref="$1"
  local workflow_name=""
  local ref_path=""

  ref_path="$(dev_kit_ref_path_without_repo "$(dev_kit_ref_without_version "$ref")")"
  workflow_name="$(basename "$ref_path")"
  workflow_name="${workflow_name%.yml}"
  workflow_name="${workflow_name%.yaml}"

  printf "docs/%s.md\n" "$workflow_name"
  printf "docs/%s.md\n" "$(printf '%s' "$workflow_name" | tr '-' '_')"
}

dev_kit_repo_workflow_dependency_lines() {
  local repo_dir="$1"
  local workflow_ref=""
  local workflow_file=""
  local dependency_ref=""

  while IFS= read -r workflow_ref; do
    [ -n "$workflow_ref" ] || continue
    printf 'workflow|%s\n' "$workflow_ref"
    workflow_file="$(dev_kit_repo_ref_local_file "$workflow_ref" 2>/dev/null || true)"
    [ -f "$workflow_file" ] || continue
    while IFS= read -r dependency_ref; do
      [ -n "$dependency_ref" ] || continue
      printf 'dependency|%s|%s\n' "$workflow_ref" "$dependency_ref"
    done <<EOF
$(grep -E '^[[:space:]]*uses:' "$workflow_file" | sed -n 's/^[[:space:]]*uses:[[:space:]]*"\{0,1\}\([^"[:space:]]*\)"\{0,1\}.*/\1/p' | awk '!seen[$0]++')
EOF
  done <<EOF
$(dev_kit_repo_workflow_ref_lines "$repo_dir" | awk '!seen[$0]++')
EOF
}

dev_kit_repo_package_dependency_lines() {
  local repo_dir="$1"

  [ -f "$repo_dir/package.json" ] || return 0

  if command -v rg >/dev/null 2>&1; then
    rg -o '"@udx/[^"]+"' "$repo_dir/package.json" | tr -d '"' | sed 's#^@udx/#udx/#' | awk '!seen[$0]++'
    return 0
  fi

  grep -Eo '"@udx/[^"]+"' "$repo_dir/package.json" | tr -d '"' | sed 's#^@udx/#udx/#' | awk '!seen[$0]++'
}

dev_kit_repo_docker_dependency_lines() {
  local repo_dir="$1"
  local docker_file="$repo_dir/Dockerfile"

  [ -f "$docker_file" ] || return 0

  awk '
    toupper($1) == "FROM" {
      image = $2
      sub(/^[[:space:]]+/, "", image)
      sub(/[[:space:]]+$/, "", image)
      sub(/@.*/, "", image)
      split(image, parts, ":")
      image = parts[1]
      if (image ~ /^ghcr\.io\/udx\//) {
        sub(/^ghcr\.io\//, "", image)
        print image
      } else if (image ~ /^usabilitydynamics\//) {
        sub(/^usabilitydynamics\//, "udx/", image)
        print image
      }
    }
  ' "$docker_file" | awk '!seen[$0]++'
}

dev_kit_repo_dependency_repo_lines() {
  local repo_dir="$1"
  local line=""
  local repo_slug=""

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    case "$line" in
      workflow\|*)
        repo_slug="$(dev_kit_repo_slug_from_ref "${line#workflow|}")"
        ;;
      dependency\|*)
        repo_slug="$(dev_kit_repo_slug_from_ref "$(printf '%s' "$line" | cut -d'|' -f3)")"
        ;;
      *)
        repo_slug="$line"
        ;;
    esac
    [ -n "$repo_slug" ] || continue
    dev_kit_repo_is_udx_slug "$repo_slug" || continue
    printf '%s\n' "$repo_slug"
  done <<EOF
$(dev_kit_repo_workflow_dependency_lines "$repo_dir")
$(dev_kit_repo_package_dependency_lines "$repo_dir")
$(dev_kit_repo_docker_dependency_lines "$repo_dir")
EOF
}

dev_kit_repo_dependency_repo_text() {
  local repo_dir="$1"
  local lines=""

  lines="$(dev_kit_repo_dependency_repo_lines "$repo_dir" | awk '!seen[$0]++')"
  if [ -z "$lines" ]; then
    printf "%s" "none"
    return 0
  fi

  printf "%s" "$lines" | dev_kit_lines_to_csv
}

dev_kit_repo_dependency_repo_json() {
  local repo_dir="$1"
  local lines=""

  lines="$(dev_kit_repo_dependency_repo_lines "$repo_dir" | awk '!seen[$0]++')"
  if [ -z "$lines" ]; then
    printf "%s" "[]"
    return 0
  fi

  printf "%s" "$lines" | dev_kit_lines_to_json_array
}

dev_kit_local_module_repo_dirs() {
  local cached=""
  local repo_path=""
  local lines=""

  cached="$DEV_KIT_MODULE_REPO_DIR_CACHE"
  if [ -n "$cached" ]; then
    printf '%s\n' "$cached"
    return 0
  fi

  lines="$(
    while IFS= read -r repo_path; do
      [ -n "$repo_path" ] || continue
      [ -d "$repo_path/cd/terraform/modules" ] || continue
      printf '%s\n' "$repo_path"
    done <<EOF
$(dev_kit_local_udx_repo_dirs)
EOF
  )"

  DEV_KIT_MODULE_REPO_DIR_CACHE="$lines"
  [ -n "$lines" ] || return 0
  printf '%s\n' "$lines"
}

dev_kit_repo_module_repo_paths() {
  local repo_dir="$1"
  local repo_slug=""
  local repo_path=""

  while IFS= read -r repo_slug; do
    [ -n "$repo_slug" ] || continue
    repo_path="$(dev_kit_local_repo_path "$repo_slug" 2>/dev/null || true)"
    [ -d "$repo_path" ] || continue
    printf '%s\n' "$repo_path"
  done <<EOF
$(dev_kit_repo_dependency_repo_lines "$repo_dir" | awk '!seen[$0]++')
EOF

  dev_kit_local_module_repo_dirs
}

dev_kit_repo_find_module_root() {
  local repo_dir="$1"
  local module_name="$2"
  local repo_path=""
  local module_root=""

  while IFS= read -r repo_path; do
    [ -n "$repo_path" ] || continue
    module_root="$repo_path/cd/terraform/modules/$module_name"
    if [ -d "$module_root" ]; then
      printf '%s' "$module_root"
      return 0
    fi
  done <<EOF
$(dev_kit_repo_module_repo_paths "$repo_dir" | awk '!seen[$0]++')
EOF

  return 1
}

dev_kit_repo_infra_module_lines() {
  local repo_dir="$1"
  local file_path=""
  local rel_path=""
  local module=""

  [ -d "$repo_dir/.rabbit/infra_configs" ] || return 0

  while IFS= read -r file_path; do
    [ -n "$file_path" ] || continue
    module="$(sed -n 's/^[[:space:]]*module:[[:space:]]*"\{0,1\}\([^"#[:space:]]*\).*/\1/p' "$file_path" | awk 'NF { print; exit }')"
    [ -n "$module" ] || continue
    rel_path="./${file_path#$repo_dir/}"
    printf '%s|%s\n' "$module" "$rel_path"
  done <<EOF
$(find "$repo_dir/.rabbit/infra_configs" -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)
EOF
}

dev_kit_repo_infra_module_docs_lines() {
  local repo_dir="$1"
  local line=""
  local module=""
  local source_path=""
  local module_root=""

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    module="${line%%|*}"
    source_path="${line#*|}"
    module_root="$(dev_kit_repo_find_module_root "$repo_dir" "$module" 2>/dev/null || true)"
    [ -d "$module_root" ] || continue
    printf '%s|%s|%s/readme.md|%s/configs/default.yml\n' "$module" "$source_path" "$module_root" "$module_root"
  done <<EOF
$(dev_kit_repo_infra_module_lines "$repo_dir" | awk -F'|' '!seen[$1]++')
EOF
}

dev_kit_repo_infra_module_docs_text() {
  local repo_dir="$1"
  local line=""
  local module=""
  local source_path=""
  local doc_path=""
  local default_path=""

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    module="${line%%|*}"
    line="${line#*|}"
    source_path="${line%%|*}"
    line="${line#*|}"
    doc_path="${line%%|*}"
    default_path="${line#*|}"
    printf '  - %s: %s -> %s, %s\n' "$module" "$source_path" "$doc_path" "$default_path"
  done <<EOF
$(dev_kit_repo_infra_module_docs_lines "$repo_dir")
EOF
}

dev_kit_repo_infra_module_docs_json() {
  local repo_dir="$1"
  local line=""
  local module=""
  local source_path=""
  local doc_path=""
  local default_path=""
  local first=1

  printf "["
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    module="${line%%|*}"
    line="${line#*|}"
    source_path="${line%%|*}"
    line="${line#*|}"
    doc_path="${line%%|*}"
    default_path="${line#*|}"
    if [ "$first" -eq 0 ]; then
      printf ", "
    fi
    printf '{ "module": "%s", "source_path": "%s", "doc_path": "%s", "default_path": "%s" }' \
      "$(dev_kit_json_escape "$module")" \
      "$(dev_kit_json_escape "$source_path")" \
      "$(dev_kit_json_escape "$doc_path")" \
      "$(dev_kit_json_escape "$default_path")"
    first=0
  done <<EOF
$(dev_kit_repo_infra_module_docs_lines "$repo_dir")
EOF
  printf "]"
}

dev_kit_repo_env_override_hint() {
  local repo_dir="$1"
  local development_dir="$repo_dir/.rabbit/infra_configs/development"
  local envs=""

  [ -d "$development_dir" ] || return 0
  envs="$(find "$development_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | dev_kit_lines_to_csv)"
  if [ -n "$envs" ]; then
    printf "./.rabbit/infra_configs/development/<env>/ (existing: %s)" "$envs"
    return 0
  fi

  printf "%s" "./.rabbit/infra_configs/development/<env>/"
}

dev_kit_repo_source_chain_text() {
  local repo_dir="$1"
  local line=""
  local kind=""
  local workflow_ref=""
  local dependency_ref=""
  local local_file=""
  local doc_file=""
  local candidate=""
  local repo_slug=""
  local default_branch=""
  local repo_doc=""

  while IFS= read -r repo_doc; do
    [ -n "$repo_doc" ] || continue
    printf '  - repo docs: %s\n' "$repo_doc"
  done <<EOF
$(dev_kit_repo_doc_refs "$repo_dir" | awk '!seen[$0]++')
EOF

  if [ -d "$repo_dir/.rabbit/infra_configs" ]; then
    printf '  - repo infra: ./.rabbit/infra_configs\n'
    printf '  - env overrides: %s\n' "$(dev_kit_repo_env_override_hint "$repo_dir")"
  fi

  if [ -d "$repo_dir/.github/workflows" ]; then
    printf '  - caller workflows: ./.github/workflows\n'
  fi

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    kind="${line%%|*}"
    line="${line#*|}"
    case "$kind" in
      workflow)
        workflow_ref="$line"
        local_file="$(dev_kit_repo_ref_local_file "$workflow_ref" 2>/dev/null || true)"
        repo_slug="$(dev_kit_repo_slug_from_ref "$workflow_ref")"
        default_branch="$(dev_kit_repo_remote_default_branch "$repo_slug")"
        if [ -f "$local_file" ]; then
          printf '  - reusable workflow: %s -> %s' "$workflow_ref" "$local_file"
          if [ -n "$default_branch" ]; then
            printf ' [default branch: %s]' "$default_branch"
          fi
          printf '\n'
          while IFS= read -r candidate; do
            [ -n "$candidate" ] || continue
            doc_file="$(dirname "$local_file")/../../$candidate"
            if [ -f "$doc_file" ]; then
              printf '  - workflow docs: %s\n' "$doc_file"
              break
            fi
          done <<EOF
$(dev_kit_repo_workflow_doc_candidate_paths "$workflow_ref")
EOF
        else
          printf '  - reusable workflow: %s\n' "$workflow_ref"
        fi
        ;;
      dependency)
        dependency_ref="${line#*|}"
        dependency_ref="${dependency_ref#*|}"
        repo_slug="$(dev_kit_repo_slug_from_ref "$dependency_ref")"
        dev_kit_repo_is_udx_slug "$repo_slug" || continue
        local_file="$(dev_kit_repo_ref_local_file "$dependency_ref" 2>/dev/null || true)"
        default_branch="$(dev_kit_repo_remote_default_branch "$repo_slug")"
        if [ -f "$local_file" ]; then
          printf '  - workflow dependency: %s -> %s' "$dependency_ref" "$local_file"
          if [ -n "$default_branch" ]; then
            printf ' [default branch: %s]' "$default_branch"
          fi
          printf '\n'
        else
          printf '  - workflow dependency: %s' "$dependency_ref"
          if [ -n "$default_branch" ]; then
            printf ' [default branch: %s]' "$default_branch"
          fi
          printf '\n'
        fi
        ;;
    esac
  done <<EOF
$(dev_kit_repo_workflow_dependency_lines "$repo_dir")
EOF

  dev_kit_repo_infra_module_docs_text "$repo_dir"
}

dev_kit_repo_source_chain_json() {
  local repo_dir="$1"
  local line=""
  local first=1
  local kind=""
  local emitted=0
  local workflow_ref=""
  local dependency_ref=""
  local local_file=""
  local candidate=""
  local doc_file=""
  local repo_slug=""
  local default_branch=""
  local repo_doc=""

  printf "["
  while IFS= read -r repo_doc; do
    [ -n "$repo_doc" ] || continue
    if [ "$first" -eq 0 ]; then
      printf ", "
    fi
    printf '{ "kind": "repo_docs", "refs": ["%s"] }' "$(dev_kit_json_escape "$repo_doc")"
    first=0
  done <<EOF
$(dev_kit_repo_doc_refs "$repo_dir" | awk '!seen[$0]++')
EOF

  if [ -d "$repo_dir/.rabbit/infra_configs" ]; then
    if [ "$first" -eq 0 ]; then
      printf ", "
    fi
    printf '{ "kind": "repo_infra", "refs": ["./.rabbit/infra_configs"] }'
    first=0
    printf ', { "kind": "env_overrides", "refs": ["%s"] }' "$(dev_kit_json_escape "$(dev_kit_repo_env_override_hint "$repo_dir")")"
  fi

  if [ -d "$repo_dir/.github/workflows" ]; then
    if [ "$first" -eq 0 ]; then
      printf ", "
    fi
    printf '{ "kind": "caller_workflows", "refs": ["./.github/workflows"] }'
    first=0
  fi

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    kind="${line%%|*}"
    line="${line#*|}"
    emitted=0
    case "$kind" in
      workflow)
        workflow_ref="$line"
        local_file="$(dev_kit_repo_ref_local_file "$workflow_ref" 2>/dev/null || true)"
        repo_slug="$(dev_kit_repo_slug_from_ref "$workflow_ref")"
        default_branch="$(dev_kit_repo_remote_default_branch "$repo_slug")"
        if [ "$first" -eq 0 ]; then
          printf ", "
        fi
        printf '{ "kind": "reusable_workflow", "refs": ["%s"' "$(dev_kit_json_escape "$workflow_ref")"
        if [ -f "$local_file" ]; then
          printf ', "%s"' "$(dev_kit_json_escape "$local_file")"
          while IFS= read -r candidate; do
            [ -n "$candidate" ] || continue
            doc_file="$(dirname "$local_file")/../../$candidate"
            if [ -f "$doc_file" ]; then
              printf ', "%s"' "$(dev_kit_json_escape "$doc_file")"
              break
            fi
          done <<EOF
$(dev_kit_repo_workflow_doc_candidate_paths "$workflow_ref")
EOF
        fi
        printf '], "default_branch": "%s" }' "$(dev_kit_json_escape "$default_branch")"
        emitted=1
        ;;
      dependency)
        dependency_ref="${line#*|}"
        dependency_ref="${dependency_ref#*|}"
        repo_slug="$(dev_kit_repo_slug_from_ref "$dependency_ref")"
        dev_kit_repo_is_udx_slug "$repo_slug" || continue
        local_file="$(dev_kit_repo_ref_local_file "$dependency_ref" 2>/dev/null || true)"
        default_branch="$(dev_kit_repo_remote_default_branch "$repo_slug")"
        if [ "$first" -eq 0 ]; then
          printf ", "
        fi
        printf '{ "kind": "workflow_dependency", "refs": ["%s"' "$(dev_kit_json_escape "$dependency_ref")"
        if [ -f "$local_file" ]; then
          printf ', "%s"' "$(dev_kit_json_escape "$local_file")"
        fi
        printf '], "default_branch": "%s" }' "$(dev_kit_json_escape "$default_branch")"
        emitted=1
        ;;
    esac
    if [ "$emitted" -eq 1 ]; then
      first=0
    fi
  done <<EOF
$(dev_kit_repo_workflow_dependency_lines "$repo_dir")
EOF

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    if [ "$first" -eq 0 ]; then
      printf ", "
    fi
    printf '{ "kind": "module_docs", "refs": ["%s", "%s", "%s", "%s"] }' \
      "$(dev_kit_json_escape "${line%%|*}")" \
      "$(dev_kit_json_escape "$(printf '%s' "$line" | cut -d'|' -f2)")" \
      "$(dev_kit_json_escape "$(printf '%s' "$line" | cut -d'|' -f3)")" \
      "$(dev_kit_json_escape "$(printf '%s' "$line" | cut -d'|' -f4)")"
    first=0
  done <<EOF
$(dev_kit_repo_infra_module_docs_lines "$repo_dir")
EOF
  printf "]"
}
