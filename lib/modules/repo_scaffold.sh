#!/usr/bin/env bash

# Scaffold module — all write operations for dev.kit repo.
# Analysis (what's missing) stays in repo_factors.sh and repo_signals.sh.
# This module only handles creating or updating files and dirs.

# Manifest metadata must live in the manifest itself, not in shell code.
dev_kit_manifest_metadata() {
  local manifest_path="$1"
  local manifest_kind=""
  local manifest_description=""

  [ -f "$manifest_path" ] || return 1

  manifest_kind="$(awk '/^kind:/ { sub(/^kind:[[:space:]]*/, ""); print; exit }' "$manifest_path")"
  manifest_description="$(awk '
    /^description:/ {
      sub(/^description:[[:space:]]*/, "")
      print
      exit
    }
  ' "$manifest_path")"

  printf '%s|%s\n' "$manifest_kind" "$manifest_description"
}

dev_kit_manifest_module_values() {
  local manifest_path="$1"

  [ -f "$manifest_path" ] || return 0

  awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*module:[[:space:]]*/ {
      value = $0
      sub(/^[[:space:]]*module:[[:space:]]*/, "", value)
      gsub(/["'\''"]/, "", value)
      gsub(/[[:space:]]+$/, "", value)
      if (value != "") print value
    }
  ' "$manifest_path" | awk '!seen[$0]++'
}

dev_kit_manifest_module_backend() {
  local repo_root="$1"
  local module_name="$2"
  local base_dir=""
  local candidate=""

  while IFS= read -r base_dir; do
    [ -n "$base_dir" ] || continue
    candidate="${base_dir}/${module_name}"
    if [ -d "${repo_root}/${candidate}" ]; then
      printf 'terraformModule|%s\n' "$candidate"
      return 0
    fi
  done <<EOF
$(dev_kit_detection_list "manifest_backend_module_dirs")
EOF

  return 1
}

dev_kit_manifest_backend_yaml() {
  local repo_root="$1"
  local manifest_rel="$2"
  local manifest_path="${repo_root}/${manifest_rel}"
  local module_name=""
  local backend=""
  local backend_kind=""
  local backend_path=""

  while IFS= read -r module_name; do
    [ -n "$module_name" ] || continue
    backend="$(dev_kit_manifest_module_backend "$repo_root" "$module_name" 2>/dev/null || true)"
    if [ -n "$backend" ]; then
      backend_kind="${backend%%|*}"
      backend_path="${backend#*|}"
      printf '    backend:\n'
      printf '      kind: %s\n' "$backend_kind"
      printf '      module: %s\n' "$module_name"
      printf '      path: %s\n' "$backend_path"
      if [ -f "${repo_root}/${backend_path}/readme.md" ]; then
        printf '      docs: %s/readme.md\n' "$backend_path"
      elif [ -f "${repo_root}/${backend_path}/README.md" ]; then
        printf '      docs: %s/README.md\n' "$backend_path"
      fi
      return 0
    fi
  done <<EOF
$(dev_kit_manifest_module_values "$manifest_path")
EOF
}

dev_kit_manifest_yaml_item() {
  local repo_root="$1"
  local manifest_rel="$2"
  local manifest_kind="${3:-}"
  local manifest_description="${4:-}"
  local manifest_meta=""

  if [ -z "$manifest_kind" ] || [ -z "$manifest_description" ]; then
    manifest_meta="$(dev_kit_manifest_metadata "${repo_root}/${manifest_rel}" 2>/dev/null || true)"
    [ -z "$manifest_kind" ] && manifest_kind="${manifest_meta%%|*}"
    if [ -z "$manifest_description" ]; then
      manifest_description="${manifest_meta#*|}"
      [ "$manifest_description" = "$manifest_meta" ] && manifest_description=""
    fi
  fi

  printf '  - path: %s\n' "$manifest_rel"
  [ -n "$manifest_kind" ] && printf '    kind: %s\n' "$manifest_kind"
  [ -n "$manifest_description" ] && printf '    description: %s\n' "$manifest_description"
  dev_kit_manifest_backend_yaml "$repo_root" "$manifest_rel"
}

dev_kit_version_uri() {
  printf '%s' 'udx.dev/dev.kit/v1'
}

dev_kit_context_section_comment_block() {
  local section_id="$1"
  local title=""
  local summary=""
  local note=""
  local emitted=0

  title="$(dev_kit_context_section_field "$section_id" "title" 2>/dev/null || true)"
  summary="$(dev_kit_context_section_field "$section_id" "summary" 2>/dev/null || true)"

  if [ -n "$title" ] || [ -n "$summary" ]; then
    if [ -n "$title" ] && [ -n "$summary" ]; then
      printf '# %s — %s\n' "$title" "$summary"
    elif [ -n "$title" ]; then
      printf '# %s\n' "$title"
    else
      printf '# %s\n' "$summary"
    fi
    emitted=1
  fi

  while IFS= read -r note; do
    [ -n "$note" ] || continue
    printf '# Note: %s\n' "$note"
    emitted=1
  done <<EOF
$(dev_kit_context_section_notes "$section_id")
EOF

  [ "$emitted" -eq 1 ] && printf '\n'
}

dev_kit_dep_version_repo_slug() {
  local version_value="$1"
  local domain=""
  local repo_name=""
  local org_name=""

  domain="$(printf '%s' "$version_value" | cut -d/ -f1)"
  repo_name="$(printf '%s' "$version_value" | cut -d/ -f2)"

  [ -n "$domain" ] || return 1
  [ -n "$repo_name" ] || return 1

  case "$domain" in
    *.dev)
      org_name="${domain%%.*}"
      if [ -n "$org_name" ]; then
        printf '%s/%s' "$org_name" "$repo_name"
        return 0
      fi
      ;;
  esac

  printf '%s' "$repo_name"
}

dev_kit_context_factor_ids() {
  local factor_ids=""

  factor_ids="$(dev_kit_context_section_list "gaps" "factor_ids" 2>/dev/null || true)"
  if [ -n "$factor_ids" ]; then
    printf '%s' "$factor_ids"
    return 0
  fi

  printf '%s\n' documentation dependencies config pipeline
}

# Path of the canonical context file
dev_kit_context_yaml_path() {
  local repo_root="$1"
  printf '%s/.rabbit/context.yaml\n' "$repo_root"
}

# Report gaps as JSON array [{factor, status, message}]
# Reads from existing factor analysis — no new detection here
dev_kit_scaffold_gaps_json() {
  local repo_root="$1"
  local factor=""
  local status=""
  local first=1

  printf '[\n'
  while IFS= read -r factor; do
    [ -n "$factor" ] || continue
    status="$(dev_kit_repo_factor_status "$repo_root" "$factor")"
    [ "$status" = "missing" ] || [ "$status" = "partial" ] || continue
    local rule_id message
    rule_id="$(dev_kit_repo_factor_rule_id "$factor" "$status" 2>/dev/null || true)"
    message="$([ -n "$rule_id" ] && dev_kit_rule_message "$rule_id" || printf '%s is %s' "$factor" "$status")"
    [ "$first" -eq 0 ] && printf ',\n'
    printf '  { "factor": "%s", "status": "%s", "message": "%s" }' \
      "$factor" \
      "$status" \
      "$(dev_kit_json_escape "$message")"
    first=0
  done <<EOF
$(dev_kit_context_factor_ids)
EOF
  printf '\n]\n'
}

# ── Dependency resolution utilities ────────────────────────────────────────────

# Extract GitHub org from git remote origin URL.
# Returns empty string if not a github.com remote.
dev_kit_repo_org_from_remote() {
  local repo_root="$1"
  local url
  url="$(git -C "$repo_root" remote get-url origin 2>/dev/null || true)"
  if [[ "$url" =~ github\.com[:/]([^/]+)/ ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  fi
}

# Check if a dependency identifier belongs to the same GitHub org.
# dep_id: "org/repo" or bare name like "node". current_org: e.g. "udx".
dev_kit_dep_is_same_org() {
  local dep_id="$1" current_org="$2"
  [ -n "$current_org" ] || return 1
  case "$dep_id" in
    "${current_org}/"*) return 0 ;;
    *)                  return 1 ;;
  esac
}

# Try to match a Docker image name to a same-org GitHub repo.
# For images like "usabilitydynamics/udx-worker-tooling:0.19.0",
# the Docker Hub org differs from the GitHub org. Extract the image name
# and check if a matching repo exists in the current GitHub org.
# Returns org/repo if found, empty string otherwise.
dev_kit_dep_match_image_to_org() {
  local dep_id="$1" current_org="$2" repo_root="$3" gh_auth="$4"
  [ -n "$current_org" ] || return 0

  # Extract image name: strip org prefix, tag, and digest
  local img_name="${dep_id##*/}"
  img_name="${img_name%%:*}"
  img_name="${img_name%%@*}"
  [ -n "$img_name" ] || return 0

  local parent_dir
  parent_dir="$(dirname "$repo_root")"

  # Try exact match: org/image-name
  if [ -d "${parent_dir}/${img_name}/.git" ]; then
    printf '%s/%s' "$current_org" "$img_name"
    return 0
  fi

  # Try stripping org prefix: "udx-worker-tooling" → "worker-tooling"
  local stripped="${img_name#"${current_org}-"}"
  if [ "$stripped" != "$img_name" ] && [ -d "${parent_dir}/${stripped}/.git" ]; then
    printf '%s/%s' "$current_org" "$stripped"
    return 0
  fi

  # Try via gh api if available
  if [ "$gh_auth" = "available" ]; then
    if gh api "repos/${current_org}/${img_name}" --silent 2>/dev/null; then
      printf '%s/%s' "$current_org" "$img_name"
      return 0
    fi
    if [ "$stripped" != "$img_name" ]; then
      if gh api "repos/${current_org}/${stripped}" --silent 2>/dev/null; then
        printf '%s/%s' "$current_org" "$stripped"
        return 0
      fi
    fi
  fi
  return 0
}

# Resolve a same-org dependency repo.
# Outputs tab-delimited: resolved\tarchetype\tdescription
# Strategy: gh api (primary when available) + sibling directory for local context.
dev_kit_dep_resolve() {
  local dep_repo="$1" repo_root="$2" gh_auth="$3" force="$4"
  local dep_name="${dep_repo##*/}"
  local resolved="false" archetype="" description=""

  # Strategy 1: gh api for metadata (description)
  if [ "$gh_auth" = "available" ]; then
    local api_json
    api_json="$(gh api "repos/${dep_repo}" 2>/dev/null || true)"
    if [ -n "$api_json" ] && printf '%s' "$api_json" | jq -e '.id' >/dev/null 2>&1; then
      resolved="true"
      # Sanitize description: strip newlines/tabs/backslashes for safe YAML embedding
      description="$(printf '%s' "$api_json" | jq -r '(.description // empty) | gsub("[\\n\\r\\t]"; " ") | gsub("\\\\"; "") | gsub("\""; "")' 2>/dev/null)"
    fi
  fi

  # Strategy 2: sibling directory for local context
  local sibling_dir
  sibling_dir="$(dirname "$repo_root")/${dep_name}"
  if [ -d "$sibling_dir" ] && [ -d "${sibling_dir}/.git" ]; then
    resolved="true"
    local dep_context="${sibling_dir}/.rabbit/context.yaml"
    if [ -f "$dep_context" ] && [ "$force" != "1" ]; then
      [ -z "$archetype" ] && archetype="$(awk '/^repo:/{f=1} f && /^  archetype:/{sub(/.*archetype:[[:space:]]*/,""); print; exit}' "$dep_context")"
    fi
    # Live detection fallback
    [ -z "$archetype" ] && archetype="$(dev_kit_repo_primary_archetype "$sibling_dir" 2>/dev/null || true)"
  fi

  printf '%s\t%s\t%s' "$resolved" "$archetype" "$description"
}

# Read structured dependencies from context.yaml and emit JSON array.
# Used by repo.json and agent.json template rendering.
dev_kit_deps_json() {
  local repo_dir="$1"
  local context_yaml="${repo_dir}/.rabbit/context.yaml"
  [ -f "$context_yaml" ] || { printf '[]'; return; }

  awk '
    function json_esc(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); gsub(/\t/, " ", s); return s }
    function flush_ub() {
      if (ub_count > 0) {
        printf ", \"used_by\": ["
        for (i = 1; i <= ub_count; i++) {
          if (i > 1) printf ", "
          printf "\"%s\"", json_esc(ub[i])
        }
        printf "]"
      }
    }
    BEGIN { printf "["; open = 0; ub_count = 0; in_ub = 0 }
    /^dependencies:/ { in_d=1; next }
    in_d && /^[a-zA-Z#]/ { if (open) { flush_ub(); printf "}"; open = 0 }; in_d=0 }
    !in_d { next }
    /^  - repo:/ {
      if (open) { flush_ub(); printf "}," }
      sub(/.*repo:[[:space:]]*/, "")
      printf "\n    {\"repo\": \"%s\"", json_esc($0)
      open = 1; ub_count = 0; in_ub = 0
      next
    }
    /^    kind:/        { sub(/.*kind:[[:space:]]*/, "");        printf ", \"kind\": \"%s\"", json_esc($0);        in_ub=0; next }
    /^    resolved:/    { sub(/.*resolved:[[:space:]]*/, "");    printf ", \"resolved\": %s", $0;                  in_ub=0; next }
    /^    archetype:/   { sub(/.*archetype:[[:space:]]*/, "");   printf ", \"archetype\": \"%s\"", json_esc($0);   in_ub=0; next }
    /^    declared_as:/ { sub(/.*declared_as:[[:space:]]*/, ""); printf ", \"declared_as\": \"%s\"", json_esc($0); in_ub=0; next }
    /^    source_repo:/ { sub(/.*source_repo:[[:space:]]*/, ""); printf ", \"source_repo\": \"%s\"", json_esc($0); in_ub=0; next }
    /^    description:/ { sub(/.*description:[[:space:]]*/, ""); printf ", \"description\": \"%s\"", json_esc($0); in_ub=0; next }
    /^    used_by:/     { in_ub = 1; next }
    in_ub && /^      - / { ub_count++; sub(/^[[:space:]]*- /, ""); ub[ub_count] = $0; next }
    in_ub && !/^      /  { in_ub = 0 }
    END { if (open) { flush_ub(); printf "}" }; printf "\n  ]" }
  ' "$context_yaml"
}

# Write .rabbit/context.yaml — single canonical artifact for repo + agent context.
# Computes everything directly from analysis functions; no intermediate JSON file.
# force: when "1", re-resolve dependency repos even if their context.yaml exists.
dev_kit_context_yaml_write() {
  local repo_root="$1"
  local force="${2:-0}"
  local context_path="${repo_root}/.rabbit/context.yaml"
  mkdir -p "${repo_root}/.rabbit" 2>/dev/null || true

  local _repo _arch _arch_desc
  _repo="$(dev_kit_repo_name "$repo_root")"
  _arch="$(dev_kit_repo_primary_archetype "$repo_root")"
  _arch_desc="$(dev_kit_archetype_description "$_arch")"

  {
    printf '# Generated by dev.kit repo — do not edit manually.\n'
    printf '# Run `dev.kit repo` to refresh.\n'
    printf 'kind: repoContext\n'
    printf 'version: %s\n' "$(dev_kit_version_uri)"
    printf 'generated: %s\n\n' "$(date +%Y-%m-%d)"

    printf 'repo:\n'
    printf '  name: %s\n'      "$_repo"
    printf '  archetype: %s\n' "$_arch"
    printf '\n'

    local _refs
    _refs="$(dev_kit_repo_priority_refs "$repo_root")"
    if [ -n "$_refs" ]; then
      dev_kit_context_section_comment_block "refs"
      printf 'refs:\n'
      printf '%s\n' "$_refs" | while IFS= read -r ref; do
        [ -n "$ref" ] || continue
        printf '  - %s\n' "$ref"
      done
      printf '\n'
    fi

    local _ep_json _verify _build _run _verify_source _build_source _run_source _command_kind
    _ep_json="$(dev_kit_repo_entrypoints_json "$repo_root")"
    _verify="$(printf '%s' "$_ep_json" | jq -r '.verify // empty' 2>/dev/null)"
    _build="$(printf '%s' "$_ep_json" | jq -r '.build  // empty' 2>/dev/null)"
    _run="$(printf '%s' "$_ep_json"   | jq -r '.run    // empty' 2>/dev/null)"
    _verify_source="$(dev_kit_repo_entrypoint_source "$repo_root" "verification" 2>/dev/null || true)"
    _build_source="$(dev_kit_repo_entrypoint_source "$repo_root" "build_release_run" 2>/dev/null || true)"
    _run_source="$(dev_kit_repo_entrypoint_source "$repo_root" "runtime" 2>/dev/null || true)"
    if [ -n "$_verify" ] || [ -n "$_build" ] || [ -n "$_run" ]; then
      dev_kit_context_section_comment_block "commands"
      printf 'commands:\n'
      while IFS= read -r _command_kind; do
        [ -n "$_command_kind" ] || continue
        case "$_command_kind" in
          verify)
            if [ -n "$_verify" ]; then
              printf '  verify:\n'
              printf '    run: %s\n' "$_verify"
              [ -n "$_verify_source" ] && printf '    source: %s\n' "$_verify_source"
            fi
            ;;
          build)
            if [ -n "$_build" ]; then
              printf '  build:\n'
              printf '    run: %s\n' "$_build"
              [ -n "$_build_source" ] && printf '    source: %s\n' "$_build_source"
            fi
            ;;
          run)
            if [ -n "$_run" ]; then
              printf '  run:\n'
              printf '    run: %s\n' "$_run"
              [ -n "$_run_source" ] && printf '    source: %s\n' "$_run_source"
            fi
            ;;
        esac
      done <<EOF
$(dev_kit_context_section_list "commands" "command_kinds")
EOF
      printf '\n'
    fi

    local _gaps_yaml
    _gaps_yaml="$(dev_kit_repo_factor_summary_json "$repo_root" | jq -r '
      to_entries[] |
      select(.value.status == "missing" or .value.status == "partial") |
      [
        "  - factor: " + .key,
        "    status: " + .value.status,
        (if (.value.message // "") != "" then "    message: " + .value.message else empty end),
        (if ((.value.evidence // []) | length) > 0 then "    evidence:" else empty end),
        ((.value.evidence // [])[]? | "      - " + .)
      ] | .[]
    ' 2>/dev/null)"
    if [ -n "$_gaps_yaml" ]; then
      dev_kit_context_section_comment_block "gaps"
      printf 'gaps:\n'
      printf '%s\n\n' "$_gaps_yaml"
    fi

    local _current_org=""
    if dev_kit_sync_has_git_repo "$repo_root"; then
      _current_org="$(dev_kit_repo_org_from_remote "$repo_root")"
    fi
    local _gh_auth_state=""
    _gh_auth_state="$(dev_kit_sync_gh_auth_state 2>/dev/null || printf 'missing')"

    local _dep_triples_file
    _dep_triples_file="$(mktemp)" || return 1

    # Source 1: Workflow references — uses: org/repo/...@ref and uses: docker://...
    # Catches reusable workflows, direct actions, and Docker actions.
    # Also scans image: fields in workflow files for container job images.
    local _dep_dir
    while IFS= read -r _dep_dir; do
      [ -n "$_dep_dir" ] && [ -d "${repo_root}/${_dep_dir}" ] || continue
      # 1a: uses: references
      while IFS= read -r _match; do
        [ -n "$_match" ] || continue
        local _src_file="${_match%%:*}"
        local _src_rel="${_src_file#"${repo_root}/"}"
        local _content="${_match#*:}"
        case "$_content" in
          *uses:*/*/.github/workflows/*)
            # Reusable workflow: uses: org/repo/.github/workflows/file@ref
            local _dep_repo
            _dep_repo="$(printf '%s' "$_content" | awk '{
              sub(/.*uses:[[:space:]]*/, ""); gsub(/"/, ""); sub(/@.*/, "")
              n = split($0, a, "/")
              if (n >= 2 && a[1] != "" && a[2] != "") printf "%s/%s", a[1], a[2]
            }')"
            [ -n "$_dep_repo" ] && printf '%s|reusable workflow|%s\n' "$_dep_repo" "$_src_rel" >> "$_dep_triples_file"
            ;;
          *uses:*docker://*|*uses:*Docker://*)
            # Docker action: uses: docker://image
            local _dep_img
            _dep_img="$(printf '%s' "$_content" | awk '{sub(/.*uses:[[:space:]]*[Dd]ocker:\/\//, ""); gsub(/["'"'"']/, ""); sub(/@.*/, ""); print}')"
            [ -n "$_dep_img" ] && printf '%s|docker action|%s\n' "$_dep_img" "$_src_rel" >> "$_dep_triples_file"
            ;;
          *uses:*/*/*@*|*uses:*./*) ;;  # skip local refs and deeply-pathed refs already caught
          *uses:*/*@*)
            # Direct action: uses: org/repo@ref (not a reusable workflow, not actions/*)
            local _dep_repo
            _dep_repo="$(printf '%s' "$_content" | awk '{
              sub(/.*uses:[[:space:]]*/, ""); gsub(/"/, ""); sub(/@.*/, "")
              if ($0 !~ /^\./ && $0 ~ /\//) print
            }')"
            [ -n "$_dep_repo" ] && printf '%s|github action|%s\n' "$_dep_repo" "$_src_rel" >> "$_dep_triples_file"
            ;;
        esac
      done <<EOF
$(grep -r 'uses:' "${repo_root}/${_dep_dir}/" 2>/dev/null || true)
EOF
      # 1b: image: fields in workflow files (container job images)
      while IFS= read -r _wf; do
        [ -f "$_wf" ] || continue
        local _wf_rel="${_wf#"${repo_root}/"}"
        awk -v src="$_wf_rel" '
          /^[[:space:]]*image:[[:space:]]/{
            img=$2; gsub(/["'"'"']/, "", img)
            if (img != "" && img !~ /\$/ && img !~ /\{/)
              printf "%s|workflow image|%s\n", img, src
          }
        ' "$_wf" >> "$_dep_triples_file"
      done <<EOF
$(find "${repo_root}/${_dep_dir}" -maxdepth 1 \( -name '*.yml' -o -name '*.yaml' \) 2>/dev/null)
EOF
    done <<EOF
$(dev_kit_context_section_detection_list_values "dependencies" "workflow_dirs")
EOF

    # Source 2: Docker base images — FROM in Dockerfiles
    local _dep_file
    while IFS= read -r _dep_file; do
      [ -n "$_dep_file" ] && [ -f "${repo_root}/${_dep_file}" ] || continue
      awk -v src="$_dep_file" '
        /^FROM[[:space:]]/{
          img=$2; sub(/ [Aa][Ss] .*/, "", img)
          if (img !~ /^\$/ && img != "scratch")
            printf "%s|base image|%s\n", img, src
        }
      ' "${repo_root}/${_dep_file}" >> "$_dep_triples_file"
    done <<EOF
$(dev_kit_context_section_detection_list_values "dependencies" "container_files")
EOF

    # Source 3: Docker Compose images — image: fields
    while IFS= read -r _dep_file; do
      [ -n "$_dep_file" ] && [ -f "${repo_root}/${_dep_file}" ] || continue
      awk -v src="$_dep_file" '
        /^[[:space:]]*image:[[:space:]]/{
          img=$2; gsub(/["'"'"']/, "", img)
          if (img != "" && img !~ /^\$/)
            printf "%s|compose image|%s\n", img, src
        }
      ' "${repo_root}/${_dep_file}" >> "$_dep_triples_file"
    done <<EOF
$(dev_kit_context_section_detection_list_values "dependencies" "compose_files")
EOF

    # Source 4: Versioned YAML configs — version: domain/repo/module/v1
    while IFS= read -r _dep_dir; do
      [ -n "$_dep_dir" ] && [ -d "${repo_root}/${_dep_dir}" ] || continue
      while IFS= read -r _vf; do
        [ -f "$_vf" ] || continue
        case "$_vf" in */context.yaml) continue ;; esac
        local _vf_rel="${_vf#"${repo_root}/"}"
        awk -v src="$_vf_rel" '
          /^version:/{
            v=$2; n=split(v, p, "/")
            if (n >= 3 && p[1] ~ /\./) {
              repo=p[2]
              module=(n >= 4 ? p[3] : "")
              if (module != "") printf "%s|versioned config (%s)|%s\n", $2, module, src
              else printf "%s|versioned config|%s\n", $2, src
            }
            exit
          }
        ' "$_vf" >> "$_dep_triples_file"
      done <<EOF
$(find "${repo_root}/${_dep_dir}" -type f \( -name '*.yaml' -o -name '*.yml' \) 2>/dev/null)
EOF
    done <<EOF
$(dev_kit_context_section_detection_list_values "dependencies" "versioned_dirs")
EOF

    # Source 5: GitHub URLs — github.com/org/repo in config/manifest files
    local _url_glob
    while IFS= read -r _url_glob; do
      [ -n "$_url_glob" ] || continue
      while IFS= read -r _uf; do
        [ -f "$_uf" ] || continue
        local _uf_rel="${_uf#"${repo_root}/"}"
        grep -oE 'github\.com[:/][A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' "$_uf" 2>/dev/null | \
          awk -v src="$_uf_rel" -v self_repo="$_repo" '{
            sub(/github\.com[\/:]+/, "")
            sub(/\.git$/, "")
            # Skip self-references and file-path-like matches
            if ($0 == self_repo || $0 ~ /\.(md|yml|yaml|json|sh|txt)$/) next
            printf "%s|github reference|%s\n", $0, src
          }' >> "$_dep_triples_file"
      done <<EOF
$(find "$repo_root" -maxdepth 1 -name "$_url_glob" -not -name 'AGENTS.md' 2>/dev/null)
EOF
    done <<EOF
$(dev_kit_context_section_detection_list_values "dependencies" "url_globs")
EOF

    # Source 6: npm packages from package.json
    if [ -f "${repo_root}/package.json" ]; then
      jq -r '
        (.dependencies // {}) + (.devDependencies // {}) |
        to_entries[] | "\(.key)|npm package|package.json"
      ' "${repo_root}/package.json" 2>/dev/null >> "$_dep_triples_file" || true
    fi

    # ── Group triples by dep, resolve same-org, emit structured YAML ─────
    if [ -s "$_dep_triples_file" ]; then
      dev_kit_context_section_comment_block "dependencies"
      printf 'dependencies:\n'

      # Get unique dep identifiers in discovery order
      awk -F'|' '!seen[$1]++ {print $1}' "$_dep_triples_file" | while IFS= read -r _udep; do
        [ -n "$_udep" ] || continue

        # Primary type (first seen)
        local _dep_type
        _dep_type="$(awk -F'|' -v k="$_udep" '$1 == k {print $2; exit}' "$_dep_triples_file")"

        # Unique used_by files
        local _used_by
        _used_by="$(awk -F'|' -v k="$_udep" '$1 == k {print $3}' "$_dep_triples_file" | sort -u)"

        local _display_repo="$_udep"
        local _normalized_repo=""
        case "$_dep_type" in
          versioned\ config*)
            _normalized_repo="$(dev_kit_dep_version_repo_slug "$_udep" 2>/dev/null || true)"
            [ -n "$_normalized_repo" ] && _display_repo="$_normalized_repo"
            ;;
        esac

        printf '  - repo: %s\n' "$_display_repo"
        printf '    kind: %s\n' "$_dep_type"

        # Resolve same-org dependencies
        local _resolve_target=""
        if dev_kit_dep_is_same_org "$_display_repo" "$_current_org"; then
          _resolve_target="$_display_repo"
        else
          # For Docker images: try matching image name to a same-org repo
          case "$_dep_type" in
            *image*|*docker*)
              _resolve_target="$(dev_kit_dep_match_image_to_org "$_display_repo" "$_current_org" "$repo_root" "$_gh_auth_state")"
              ;;
          esac
        fi

        if [ -n "$_resolve_target" ]; then
          local _resolve_out _r_resolved _r_arch _r_desc
          _resolve_out="$(dev_kit_dep_resolve "$_resolve_target" "$repo_root" "$_gh_auth_state" "$force")"
          IFS=$'\t' read -r _r_resolved _r_arch _r_desc <<< "$_resolve_out"
          printf '    resolved: %s\n' "$_r_resolved"
          [ -n "$_normalized_repo" ] && [ "$_normalized_repo" != "$_udep" ] && printf '    declared_as: %s\n' "$_udep"
          [ -n "$_resolve_target" ] && [ "$_resolve_target" != "$_display_repo" ] && printf '    source_repo: %s\n' "$_resolve_target"
          [ -n "$_r_arch" ]    && printf '    archetype: %s\n' "$_r_arch"
          [ -n "$_r_desc" ]    && printf '    description: %s\n' "$_r_desc"
        else
          printf '    resolved: false\n'
          [ -n "$_normalized_repo" ] && [ "$_normalized_repo" != "$_udep" ] && printf '    declared_as: %s\n' "$_udep"
        fi

        # Emit used_by
        if [ -n "$_used_by" ]; then
          printf '    used_by:\n'
          printf '%s\n' "$_used_by" | while IFS= read -r _ub; do
            [ -n "$_ub" ] || continue
            printf '      - %s\n' "$_ub"
          done
        fi
      done
      printf '\n'
    fi

    rm -f "$_dep_triples_file"

    local _manifests_yaml=""
    local _yaml_file _yaml_rel _yaml_kind _yaml_desc _manifest_meta _manifest_dir
    while IFS= read -r _manifest_dir; do
      [ -n "$_manifest_dir" ] && [ -d "${repo_root}/${_manifest_dir}" ] || continue
      while IFS= read -r _yaml_file; do
        [ -n "$_yaml_file" ] && [ -f "$_yaml_file" ] || continue
        _yaml_rel="${_yaml_file#"${repo_root}/"}"
        _manifests_yaml="${_manifests_yaml}$(dev_kit_manifest_yaml_item "$repo_root" "$_yaml_rel")\n"
      done <<EOF
$(find "${repo_root}/${_manifest_dir}" -maxdepth 1 \( -name '*.yaml' -o -name '*.yml' \) -print 2>/dev/null | sort)
EOF
    done <<EOF
$(dev_kit_context_section_detection_list_values "manifests" "config_dirs")
EOF
    # Workflow dirs from config (e.g. .github/workflows)
    while IFS= read -r _dep_dir; do
      [ -n "$_dep_dir" ] && [ -d "${repo_root}/${_dep_dir}" ] || continue
      while IFS= read -r _yaml_file; do
        [ -n "$_yaml_file" ] && [ -f "$_yaml_file" ] || continue
        _yaml_rel="${_yaml_file#"${repo_root}/"}"
        _manifests_yaml="${_manifests_yaml}$(dev_kit_manifest_yaml_item "$repo_root" "$_yaml_rel" "githubWorkflow")\n"
      done <<EOF
$(find "${repo_root}/${_dep_dir}" -maxdepth 1 \( -name '*.yaml' -o -name '*.yml' \) 2>/dev/null | sort)
EOF
    done <<EOF
$(dev_kit_context_section_detection_list_values "manifests" "workflow_dirs")
EOF
    # Standalone manifest files from config (deploy.yml, docker-compose.yml, etc.)
    while IFS= read -r _yaml_rel; do
      [ -n "$_yaml_rel" ] && [ -f "${repo_root}/${_yaml_rel}" ] || continue
      _manifests_yaml="${_manifests_yaml}$(dev_kit_manifest_yaml_item "$repo_root" "$_yaml_rel")\n"
    done <<EOF
$(dev_kit_context_section_detection_list_values "manifests" "root_files")
EOF
    if [ -n "$_manifests_yaml" ]; then
      dev_kit_context_section_comment_block "manifests"
      printf 'manifests:\n'
      printf '%b\n' "$_manifests_yaml"
    fi

  } > "$context_path"

  printf "%s" "$context_path"
}
