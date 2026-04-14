#!/usr/bin/env bash

# Scaffold module — all write operations for dev.kit repo.
# Analysis (what's missing) stays in repo_factors.sh and repo_signals.sh.
# This module only handles creating or updating files and dirs.

# Map config manifest kind to a one-line description.
# Agents use this to know WHAT each YAML controls before reading it.
dev_kit_manifest_kind_description() {
  case "$1" in
    archetypeRules)       printf 'archetype definitions and matching rules' ;;
    archetypeSignals)     printf 'file/dir signals for framework and platform detection' ;;
    auditRules)           printf 'factor gap messages and improvement guidance' ;;
    contextConfig)        printf 'repo root markers and priority paths' ;;
    detectionPatterns)    printf 'regex patterns for build/verify/run command detection' ;;
    detectionSignals)     printf 'file/dir/glob patterns for factor analysis' ;;
    developmentPractices) printf 'engineering principles inlined into repo context' ;;
    developmentWorkflows) printf 'git workflow steps, PR process, and operational notes' ;;
    githubIssues)         printf 'issue templates, labels, and agent issue workflow' ;;
    githubPullRequests)   printf 'PR templates, bot reviewers, and post-merge checklist' ;;
    knowledgeBase)        printf 'org hierarchy and preferred knowledge sources' ;;
    learningWorkflows)    printf 'agent session discovery and lesson extraction rules' ;;
    repoScaffold)         printf 'baseline dirs/files per archetype and factor' ;;
    *)                    printf '' ;;
  esac
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
  for factor in documentation architecture dependencies config verification runtime build_release_run; do
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
  done
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

# Resolve a same-org dependency repo.
# Outputs tab-delimited: resolved\tarchetype\tprofile\tdescription
# Strategy: gh api (primary when available) + sibling directory for local context.
dev_kit_dep_resolve() {
  local dep_repo="$1" repo_root="$2" gh_auth="$3" force="$4"
  local dep_name="${dep_repo##*/}"
  local resolved="false" archetype="" profile="" description=""

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
      [ -z "$profile" ]   && profile="$(awk '/^repo:/{f=1} f && /^  profile:/{sub(/.*profile:[[:space:]]*/,""); print; exit}' "$dep_context")"
    fi
    # Live detection fallback
    [ -z "$archetype" ] && archetype="$(dev_kit_repo_primary_archetype "$sibling_dir" 2>/dev/null || true)"
    [ -z "$profile" ]   && profile="$(dev_kit_repo_primary_profile "$sibling_dir" 2>/dev/null || true)"
  fi

  printf '%s\t%s\t%s\t%s' "$resolved" "$archetype" "$profile" "$description"
}

# Read structured dependencies from context.yaml and emit JSON array.
# Used by repo.json and agent.json template rendering.
dev_kit_deps_json() {
  local repo_dir="$1"
  local context_yaml="${repo_dir}/.rabbit/context.yaml"
  [ -f "$context_yaml" ] || { printf '[]'; return; }

  awk '
    function json_esc(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); gsub(/\t/, " ", s); return s }
    BEGIN { printf "["; open = 0 }
    /^dependencies:/ { in_d=1; next }
    in_d && /^[a-zA-Z#]/ { if (open) { printf "}"; open = 0 }; in_d=0 }
    !in_d { next }
    /^  - repo:/ {
      if (open) printf "},"
      sub(/.*repo:[[:space:]]*/, "")
      printf "\n    {\"repo\": \"%s\"", json_esc($0)
      open = 1
      next
    }
    /^    type:/ {
      sub(/.*type:[[:space:]]*/, "")
      printf ", \"type\": \"%s\"", json_esc($0)
      next
    }
    /^    resolved:/ {
      sub(/.*resolved:[[:space:]]*/, "")
      printf ", \"resolved\": %s", $0
      next
    }
    /^    archetype:/ {
      sub(/.*archetype:[[:space:]]*/, "")
      printf ", \"archetype\": \"%s\"", json_esc($0)
      next
    }
    /^    profile:/ {
      sub(/.*profile:[[:space:]]*/, "")
      printf ", \"profile\": \"%s\"", json_esc($0)
      next
    }
    /^    description:/ {
      sub(/.*description:[[:space:]]*/, "")
      printf ", \"description\": \"%s\"", json_esc($0)
      next
    }
    END { if (open) printf "}"; printf "\n  ]" }
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

  local _repo _arch _arch_desc _profile
  _repo="$(dev_kit_repo_name "$repo_root")"
  _arch="$(dev_kit_repo_primary_archetype "$repo_root")"
  _arch_desc="$(dev_kit_archetype_description "$_arch")"
  _profile="$(dev_kit_repo_primary_profile "$repo_root")"

  {
    printf '# Generated by dev.kit repo — do not edit manually.\n'
    printf '# Run `dev.kit repo` to refresh.\n'
    printf 'kind: repoContext\n'
    printf 'version: udx.io/dev.kit/v1\n'
    printf 'generated: %s\n\n' "$(date +%Y-%m-%d)"

    printf 'repo:\n'
    printf '  name: %s\n'      "$_repo"
    printf '  archetype: %s\n' "$_arch"
    printf '  profile: %s\n'   "$_profile"
    printf '\n'

    # Refs — only files/dirs that must be read directly; metadata is inlined below
    local _refs
    _refs="$(dev_kit_repo_priority_refs "$repo_root")"
    if [ -n "$_refs" ]; then
      printf 'refs:\n'
      printf '%s\n' "$_refs" | while IFS= read -r ref; do
        [ -n "$ref" ] || continue
        printf '  - %s\n' "$ref"
      done
      printf '\n'
    fi

    # Commands
    local _ep_json _verify _build _run
    _ep_json="$(dev_kit_repo_entrypoints_json "$repo_root")"
    _verify="$(printf '%s' "$_ep_json" | jq -r '.verify // empty' 2>/dev/null)"
    _build="$(printf '%s' "$_ep_json" | jq -r '.build  // empty' 2>/dev/null)"
    _run="$(printf '%s' "$_ep_json"   | jq -r '.run    // empty' 2>/dev/null)"
    if [ -n "$_verify" ] || [ -n "$_build" ] || [ -n "$_run" ]; then
      printf 'commands:\n'
      [ -n "$_verify" ] && printf '  verify: %s\n' "$_verify"
      [ -n "$_build"  ] && printf '  build: %s\n'  "$_build"
      [ -n "$_run"    ] && printf '  run: %s\n'    "$_run"
      printf '\n'
    fi

    # GitHub context — development signals from the repo's GitHub history.
    # Only collected when gh CLI is available and remote is github.com.
    # All gh calls are guarded (|| true) since repos may have issues disabled,
    # no PRs, or restricted API access. Titles are sanitized to prevent
    # YAML injection from untrusted PR/issue names.
    if command -v gh >/dev/null 2>&1 && dev_kit_sync_has_git_repo "$repo_root"; then
      local _gh_origin_url _gh_owner_repo=""
      _gh_origin_url="$(git -C "$repo_root" remote get-url origin 2>/dev/null || true)"
      if [[ "$_gh_origin_url" =~ github\.com[:/]([^/]+/[^/]+)(\.git)?$ ]]; then
        _gh_owner_repo="${BASH_REMATCH[1]}"
        _gh_owner_repo="${_gh_owner_repo%.git}"
      fi
      if [ -n "$_gh_owner_repo" ]; then
        # jq yaml_safe: escape backslashes, strip CR/LF/tabs, escape inner quotes
        local _jq_safe='def yaml_safe: gsub("\\\\"; "\\\\\\\\") | gsub("\\r"; " ") | gsub("\\n"; " ") | gsub("\\t"; " ") | gsub("\""; "\\\"");'

        # Open issues (up to 10, most recent)
        local _gh_issues
        _gh_issues="$(gh api "repos/${_gh_owner_repo}/issues?state=open&per_page=10&sort=updated&direction=desc" 2>/dev/null | jq -r "${_jq_safe}"'
          .[]? | select(.pull_request == null) |
          "    - \"#\(.number) \(.title | yaml_safe)\(if (.labels | length) > 0 then " [" + ([.labels[].name | yaml_safe] | join(", ")) + "]" else "" end)\""
        ' 2>/dev/null || true)"

        # Recent merged PRs (last 5)
        local _gh_prs
        _gh_prs="$(gh api "repos/${_gh_owner_repo}/pulls?state=closed&sort=updated&direction=desc&per_page=10" 2>/dev/null | jq -r "${_jq_safe}"'
          [.[]? | select(.merged_at != null)] | sort_by(.merged_at) | reverse | .[:5][] |
          "    - \"#\(.number) \(.title | yaml_safe)\""
        ' 2>/dev/null || true)"

        # Open PRs
        local _gh_open_prs
        _gh_open_prs="$(gh api "repos/${_gh_owner_repo}/pulls?state=open&per_page=5&sort=updated&direction=desc" 2>/dev/null | jq -r "${_jq_safe}"'
          .[]? | "    - \"#\(.number) \(.title | yaml_safe)\(if .draft then " (draft)" else "" end)\""
        ' 2>/dev/null || true)"

        # Security alerts (Dependabot)
        local _gh_alerts
        _gh_alerts="$(gh api "repos/${_gh_owner_repo}/dependabot/alerts?state=open&per_page=5" 2>/dev/null | jq -r "${_jq_safe}"'
          .[]? | "    - \"\(.security_advisory.severity | yaml_safe): \((.security_advisory.summary // .dependency.package.name) | yaml_safe)\""
        ' 2>/dev/null || true)"

        if [ -n "$_gh_issues" ] || [ -n "$_gh_prs" ] || [ -n "$_gh_open_prs" ] || [ -n "$_gh_alerts" ]; then
          printf '# GitHub context — development signals from repo history\n'
          printf 'github:\n'
          printf '  repo: %s\n' "$_gh_owner_repo"
          [ -n "$_gh_issues" ]   && printf '  open_issues:\n%s\n' "$_gh_issues"
          [ -n "$_gh_prs" ]      && printf '  recent_prs:\n%s\n' "$_gh_prs"
          [ -n "$_gh_open_prs" ] && printf '  open_prs:\n%s\n' "$_gh_open_prs"
          [ -n "$_gh_alerts" ]   && printf '  security_alerts:\n%s\n' "$_gh_alerts"
          printf '\n'
        fi
      fi
    fi

    # Factor gaps
    local _gaps_yaml
    _gaps_yaml="$(dev_kit_repo_factor_summary_json "$repo_root" | jq -r '
      to_entries[] |
      select(.value.status == "missing" or .value.status == "partial") |
      "  - " + .key + " (" + .value.status + ")"
    ' 2>/dev/null)"
    if [ -n "$_gaps_yaml" ]; then
      printf '# Gaps — factors that are missing or partial\n'
      printf 'gaps:\n'
      printf '%s\n\n' "$_gaps_yaml"
    fi

    # Practices — inlined from dev.kit development-practices.yaml
    local _practices_file _practices_yaml
    _practices_file="$(dev_kit_config_path "$DEV_KIT_PRACTICES_CONFIG_FILE")"
    if [ -f "$_practices_file" ]; then
      _practices_yaml="$(awk '
        /^  practices:/ { in_p=1; next }
        in_p && /^  [a-zA-Z]/ { in_p=0 }
        in_p && /^      message:/ {
          sub(/^[[:space:]]*message:[[:space:]]*/, "", $0)
          gsub(/"/, "\\\"", $0)
          printf "  - \"%s\"\n", $0
        }
      ' "$_practices_file")"
      if [ -n "$_practices_yaml" ]; then
        printf '# Engineering practices\n'
        printf 'practices:\n'
        printf '%s\n\n' "$_practices_yaml"
      fi
    fi

    # Workflow — inlined from dev.kit development-workflows.yaml with operational notes
    local _workflow_file _workflow_yaml
    _workflow_file="$(dev_kit_config_path "$DEV_KIT_WORKFLOW_CONFIG_FILE")"
    if [ -f "$_workflow_file" ]; then
      _workflow_yaml="$(awk '
        /^        - id:/ { flush(); label=""; note=""; in_note=0 }
        /^          label:/ { sub(/^[[:space:]]*label:[[:space:]]*/, "", $0); label=$0 }
        /^          note:[[:space:]]*>/ { in_note=1; next }
        in_note && /^            / {
          sub(/^[[:space:]]+/, "", $0)
          note = (note == "") ? $0 : note " " $0
          next
        }
        in_note { flush(); in_note=0 }
        function flush() {
          if (label != "") {
            gsub(/"/, "\\\"", label)
            gsub(/"/, "\\\"", note)
            if (note != "") printf "  - \"%s: %s\"\n", label, note
            else            printf "  - \"%s\"\n", label
          }
        }
        END { flush() }
      ' "$_workflow_file")"
      if [ -n "$_workflow_yaml" ]; then
        printf '# Canonical agent workflow\n'
        printf 'workflow:\n'
        printf '%s\n\n' "$_workflow_yaml"
      fi
    else
      # Fallback to repo-derived steps when dev.kit workflow config is absent
      local _fallback_yaml
      _fallback_yaml="$(dev_kit_repo_workflow_json "$repo_root" | jq -r '.[]? | "  - " + .label' 2>/dev/null)"
      if [ -n "$_fallback_yaml" ]; then
        printf 'workflow:\n'
        printf '%s\n\n' "$_fallback_yaml"
      fi
    fi

    # ── External dependencies — structured cross-repo tracing ──────────────
    # Collect (dep_id|type|source_file) triples from multiple sources,
    # then group by dep and resolve same-org repos for rich metadata.
    # All scan locations are config-driven from detection-signals.yaml.
    local _current_org=""
    if dev_kit_sync_has_git_repo "$repo_root"; then
      _current_org="$(dev_kit_repo_org_from_remote "$repo_root")"
    fi
    local _gh_auth_state=""
    _gh_auth_state="$(dev_kit_sync_gh_auth_state 2>/dev/null || printf 'missing')"

    local _dep_triples_file
    _dep_triples_file="$(mktemp)" || return 1

    # Source 1: Reusable workflows — uses: org/repo/.github/workflows/...@ref
    local _dep_dir
    while IFS= read -r _dep_dir; do
      [ -n "$_dep_dir" ] && [ -d "${repo_root}/${_dep_dir}" ] || continue
      while IFS= read -r _match; do
        [ -n "$_match" ] || continue
        local _src_file="${_match%%:*}"
        local _src_rel="${_src_file#"${repo_root}/"}"
        local _content="${_match#*:}"
        case "$_content" in
          *uses:*/*/.github/workflows/*)
            local _dep_repo
            _dep_repo="$(printf '%s' "$_content" | awk '{
              sub(/.*uses:[[:space:]]*/, ""); sub(/@.*/, "")
              n = split($0, a, "/")
              if (n >= 2 && a[1] != "" && a[2] != "") printf "%s/%s", a[1], a[2]
            }')"
            [ -n "$_dep_repo" ] && printf '%s|reusable workflow|%s\n' "$_dep_repo" "$_src_rel" >> "$_dep_triples_file"
            ;;
        esac
      done <<EOF
$(grep -r 'uses:' "${repo_root}/${_dep_dir}/" 2>/dev/null || true)
EOF
    done <<EOF
$(dev_kit_detection_list "dependency_trace_workflow_dirs")
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
$(dev_kit_detection_list "dependency_trace_container_files")
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
$(dev_kit_detection_list "dependency_trace_compose_files")
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
              if (n >= 4) printf "%s|versioned config (%s)|%s\n", repo, p[3], src
              else printf "%s|versioned config|%s\n", repo, src
            }
            exit
          }
        ' "$_vf" >> "$_dep_triples_file"
      done <<EOF
$(find "${repo_root}/${_dep_dir}" -type f \( -name '*.yaml' -o -name '*.yml' \) 2>/dev/null)
EOF
    done <<EOF
$(dev_kit_detection_list "dependency_trace_versioned_dirs")
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
$(dev_kit_detection_list "dependency_trace_url_globs")
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
      printf '# External dependencies — cross-repo and upstream references\n'
      printf '# Trace these to find infrastructure, deployment, and build logic outside this repo.\n'
      printf '# Same-org deps are resolved with metadata. External deps listed for agent reference.\n'
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

        printf '  - repo: %s\n' "$_udep"
        printf '    type: %s\n' "$_dep_type"

        # Resolve same-org dependencies
        if dev_kit_dep_is_same_org "$_udep" "$_current_org"; then
          local _resolve_out _r_resolved _r_arch _r_profile _r_desc
          _resolve_out="$(dev_kit_dep_resolve "$_udep" "$repo_root" "$_gh_auth_state" "$force")"
          IFS=$'\t' read -r _r_resolved _r_arch _r_profile _r_desc <<< "$_resolve_out"
          printf '    resolved: %s\n' "$_r_resolved"
          [ -n "$_r_arch" ]    && printf '    archetype: %s\n' "$_r_arch"
          [ -n "$_r_profile" ] && printf '    profile: %s\n' "$_r_profile"
          [ -n "$_r_desc" ]    && printf '    description: %s\n' "$_r_desc"
        else
          printf '    resolved: false\n'
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

    # Config manifests — traceable workflow and tooling dependencies.
    # Sources read from detection-signals.yaml: manifest_workflow_dirs, manifest_root_files.
    local _manifests_yaml=""
    local _yaml_file _yaml_rel _yaml_kind _yaml_desc
    # src/configs — dev.kit's own config catalog (only present in dev.kit repos)
    if [ -d "${repo_root}/src/configs" ]; then
      while IFS='|' read -r _yaml_rel _yaml_kind; do
        [ -n "$_yaml_rel" ] || continue
        _yaml_desc="$(dev_kit_manifest_kind_description "$_yaml_kind")"
        if [ -n "$_yaml_desc" ]; then
          _manifests_yaml="${_manifests_yaml}  - ${_yaml_rel} — ${_yaml_desc}\n"
        elif [ -n "$_yaml_kind" ]; then
          _manifests_yaml="${_manifests_yaml}  - ${_yaml_rel} (${_yaml_kind})\n"
        else
          _manifests_yaml="${_manifests_yaml}  - ${_yaml_rel}\n"
        fi
      done <<EOF
$(find "${repo_root}/src/configs" -maxdepth 1 \( -name '*.yaml' -o -name '*.yml' \) -print 2>/dev/null | sort | while IFS= read -r f; do
  [ -f "$f" ] || continue
  rel="${f#"${repo_root}/"}"
  kind="$(awk '/^kind:/ { sub(/^kind:[[:space:]]*/, ""); print; exit }' "$f")"
  printf '%s|%s\n' "$rel" "$kind"
done)
EOF
    fi
    # Workflow dirs from config (e.g. .github/workflows)
    while IFS= read -r _dep_dir; do
      [ -n "$_dep_dir" ] && [ -d "${repo_root}/${_dep_dir}" ] || continue
      while IFS= read -r _yaml_file; do
        [ -n "$_yaml_file" ] && [ -f "$_yaml_file" ] || continue
        _yaml_rel="${_yaml_file#"${repo_root}/"}"
        _manifests_yaml="${_manifests_yaml}  - ${_yaml_rel}\n"
      done <<EOF
$(find "${repo_root}/${_dep_dir}" -maxdepth 1 \( -name '*.yaml' -o -name '*.yml' \) 2>/dev/null | sort)
EOF
    done <<EOF
$(dev_kit_detection_list "manifest_workflow_dirs")
EOF
    # Standalone manifest files from config (deploy.yml, docker-compose.yml, etc.)
    while IFS= read -r _yaml_rel; do
      [ -n "$_yaml_rel" ] && [ -f "${repo_root}/${_yaml_rel}" ] || continue
      _manifests_yaml="${_manifests_yaml}  - ${_yaml_rel}\n"
    done <<EOF
$(dev_kit_detection_list "manifest_root_files")
EOF
    if [ -n "$_manifests_yaml" ]; then
      printf '# Config manifests — traceable workflow and tooling dependencies\n'
      printf '# Read these to understand what controls repo behavior before reading shell code.\n'
      printf 'manifests:\n'
      printf '%b\n' "$_manifests_yaml"
    fi

    # Lessons from .rabbit/dev.kit/
    local lessons_dir="${repo_root}/.rabbit/dev.kit"
    if [ -d "$lessons_dir" ]; then
      local first_lesson=1
      while IFS= read -r lesson_path; do
        [ -n "$lesson_path" ] || continue
        [ -f "$lesson_path" ] || continue
        if [ "$first_lesson" -eq 1 ]; then
          printf '# Lessons from agent sessions\n'
          printf 'lessons:\n'
          first_lesson=0
        fi
        printf '  - .rabbit/dev.kit/%s\n' "$(basename "$lesson_path")"
      done <<EOF
$(find "$lessons_dir" -maxdepth 1 -type f -name 'lessons-*.md' 2>/dev/null | sort -r | head -3)
EOF
      [ "$first_lesson" -eq 0 ] && printf '\n'
    fi

  } > "$context_path"

  printf "%s" "$context_path"
}
