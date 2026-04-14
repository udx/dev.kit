#!/usr/bin/env bash

_DEV_KIT_ENV_NPM_ROOT=""

dev_kit_env_npm_root() {
  if [ -z "$_DEV_KIT_ENV_NPM_ROOT" ] && command -v npm >/dev/null 2>&1; then
    _DEV_KIT_ENV_NPM_ROOT="$(npm root -g 2>/dev/null)"
  fi
  printf '%s' "$_DEV_KIT_ENV_NPM_ROOT"
}

dev_kit_env_tool_category() {
  case "$1" in
    git|gh|npm|docker|yq|jq) printf 'required' ;;
    aws|gcloud|az)            printf 'cloud' ;;
    "@udx/"*)                 printf 'recommended' ;;
    *)                        printf 'required' ;;
  esac
}

dev_kit_env_tool_version() {
  case "$1" in
    git)    git --version 2>/dev/null | awk '{print $3}' ;;
    gh)     gh --version 2>/dev/null | awk 'NR==1{print $3}' ;;
    npm)    npm --version 2>/dev/null ;;
    docker) docker --version 2>/dev/null | awk '{print $3}' | tr -d ',' ;;
    yq)     yq --version 2>/dev/null | awk '{print $NF}' ;;
    jq)     jq --version 2>/dev/null | sed 's/jq-//' ;;
    aws)    aws --version 2>&1 | awk '{print $1}' | cut -d/ -f2 ;;
    gcloud) gcloud --version 2>/dev/null | awk 'NR==1{print $NF}' ;;
    az)     az --version 2>/dev/null | awk '/^azure-cli/{print $2; exit}' ;;
    "@udx/"*)
      local pkg="$1"
      local npm_root=""
      npm_root="$(dev_kit_env_npm_root)"
      [ -n "$npm_root" ] || return 0
      awk -F'"' '/"version"/{print $4; exit}' "${npm_root}/${pkg}/package.json" 2>/dev/null
      ;;
  esac
}

dev_kit_env_tool_state() {
  local tool="$1"
  local version=""

  case "$tool" in
    "@udx/"*)
      local npm_root=""
      npm_root="$(dev_kit_env_npm_root)"
      if [ -n "$npm_root" ] && [ -d "${npm_root}/${tool}" ]; then
        version="$(dev_kit_env_tool_version "$tool")"
        if [ -n "$version" ]; then
          printf 'available (%s)' "$version"
        else
          printf 'available'
        fi
      else
        printf 'missing'
      fi
      return 0
      ;;
  esac

  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'missing'
    return 0
  fi

  case "$tool" in
    gh)
      case "$(dev_kit_sync_gh_auth_state)" in
        available)
          version="$(dev_kit_env_tool_version "$tool")"
          printf 'available (%s, auth ok)' "${version:-installed}"
          ;;
        unauthenticated)
          version="$(dev_kit_env_tool_version "$tool")"
          printf 'available (%s, auth needed)' "${version:-installed}"
          ;;
        *)
          printf 'available'
          ;;
      esac
      ;;
    *)
      version="$(dev_kit_env_tool_version "$tool")"
      if [ -n "$version" ]; then
        printf 'available (%s)' "$version"
      else
        printf 'available'
      fi
      ;;
  esac
}

# Compute and write tool lines to cache. Called once per session on cache miss.
_dev_kit_env_compute_tool_lines() {
  local tool=""
  for tool in git gh npm docker yq jq aws gcloud az "@udx/worker-deployment" "@udx/mcurl"; do
    printf '%s|%s|%s\n' "$tool" "$(dev_kit_env_tool_category "$tool")" "$(dev_kit_env_tool_state "$tool")"
  done
}

# Returns tool lines. Format: tool|category|status
dev_kit_env_tool_lines() {
  _dev_kit_env_compute_tool_lines
}

dev_kit_env_tools_json() {
  local first=1
  local line=""
  local tool=""
  local rest=""
  local category=""
  local state=""

  printf '['
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    tool="${line%%|*}"
    rest="${line#*|}"
    category="${rest%%|*}"
    state="${rest#*|}"
    if [ "$first" -eq 0 ]; then
      printf ', '
    fi
    printf '{ "tool": "%s", "category": "%s", "status": "%s" }' \
      "$(dev_kit_json_escape "$tool")" \
      "$(dev_kit_json_escape "$category")" \
      "$(dev_kit_json_escape "$state")"
    first=0
  done <<EOF
$(dev_kit_env_tool_lines)
EOF
  printf ']'
}

# Derive capabilities from cached tool lines — no extra subprocess spawns.
dev_kit_global_context_capabilities_json() {
  local yaml_parsing=false
  local json_parsing=false
  local github_enrichment=false
  local cloud_aws=false
  local cloud_gcp=false
  local cloud_azure=false
  local line=""
  local tool=""
  local status=""

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    tool="${line%%|*}"
    status="${line##*|}"
    case "$tool" in
      yq)     case "$status" in available*) yaml_parsing=true ;; esac ;;
      jq)     case "$status" in available*) json_parsing=true ;; esac ;;
      gh)     case "$status" in *"auth ok"*) github_enrichment=true ;; esac ;;
      aws)    case "$status" in available*) cloud_aws=true ;; esac ;;
      gcloud) case "$status" in available*) cloud_gcp=true ;; esac ;;
      az)     case "$status" in available*) cloud_azure=true ;; esac ;;
    esac
  done <<EOF
$(dev_kit_env_tool_lines)
EOF

  printf '{ "yaml_parsing": %s, "json_parsing": %s, "github_enrichment": %s, "cloud_aws": %s, "cloud_gcp": %s, "cloud_azure": %s }' \
    "$yaml_parsing" "$json_parsing" "$github_enrichment" \
    "$cloud_aws" "$cloud_gcp" "$cloud_azure"
}

# Human-readable description of what a tool enables for dev.kit context.
dev_kit_env_tool_enables() {
  case "$1" in
    git)    printf 'version control, branch analysis' ;;
    gh)     printf 'GitHub issues, PRs, and enrichment' ;;
    npm)    printf 'package management, global installs' ;;
    docker) printf 'container builds and runtime' ;;
    yq)     printf 'YAML parsing in context generation' ;;
    jq)     printf 'JSON processing for config and API data' ;;
    aws)    printf 'AWS cloud operations' ;;
    gcloud) printf 'Google Cloud operations' ;;
    az)     printf 'Azure cloud operations' ;;
    "@udx/worker-deployment") printf 'UDX deployment workflows' ;;
    "@udx/mcurl")             printf 'web fetches for agents' ;;
    *)      printf 'general tooling' ;;
  esac
}

# Print tool status lines grouped by category for text output.
# Each line: tool (status) — enables description
dev_kit_env_tools_text() {
  local line="" tool="" rest="" category="" status="" enables=""
  local cur_cat=""

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    tool="${line%%|*}"
    rest="${line#*|}"
    category="${rest%%|*}"
    status="${rest#*|}"
    enables="$(dev_kit_env_tool_enables "$tool")"

    if [ "$category" != "$cur_cat" ]; then
      cur_cat="$category"
    fi

    case "$status" in
      missing)
        printf '%s|✗ %s — %s\n' "$category" "$tool" "$enables"
        ;;
      *)
        printf '%s|✓ %s — %s\n' "$category" "$tool" "$enables"
        ;;
    esac
  done <<EOF
$(dev_kit_env_tool_lines)
EOF
}

# Returns space-separated list of missing base tools. Derived from cached lines.
dev_kit_env_missing_base_tools() {
  local line=""
  local tool=""
  local rest=""
  local category=""
  local status=""
  local missing=""

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    tool="${line%%|*}"
    rest="${line#*|}"
    category="${rest%%|*}"
    status="${rest#*|}"
    [ "$category" = "required" ] || continue
    case "$status" in
      missing) missing="${missing:+$missing }$tool" ;;
    esac
  done <<EOF
$(dev_kit_env_tool_lines)
EOF

  printf '%s' "$missing"
}
