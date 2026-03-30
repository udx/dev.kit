#!/usr/bin/env bash

dev_kit_env_tool_version() {
  case "$1" in
    git)
      git --version 2>/dev/null | awk '{print $3}'
      ;;
    gh)
      gh --version 2>/dev/null | awk 'NR == 1 {print $3}'
      ;;
    npm)
      npm --version 2>/dev/null
      ;;
    docker)
      docker --version 2>/dev/null | awk '{print $3}' | tr -d ','
      ;;
  esac
}

dev_kit_env_tool_state() {
  local tool="$1"
  local version=""

  if ! command -v "$tool" >/dev/null 2>&1; then
    printf '%s' "missing"
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
          printf '%s' "available"
          ;;
      esac
      ;;
    docker)
      version="$(dev_kit_env_tool_version "$tool")"
      if docker info >/dev/null 2>&1; then
        printf 'available (%s, daemon running)' "${version:-installed}"
      else
        printf 'available (%s, daemon unavailable)' "${version:-installed}"
      fi
      ;;
    *)
      version="$(dev_kit_env_tool_version "$tool")"
      if [ -n "$version" ]; then
        printf 'available (%s)' "$version"
      else
        printf '%s' "available"
      fi
      ;;
  esac
}

dev_kit_env_tool_lines() {
  local tool=""

  for tool in git gh npm docker; do
    printf '%s|%s\n' "$tool" "$(dev_kit_env_tool_state "$tool")"
  done
}

dev_kit_env_tools_json() {
  local first=1
  local line=""
  local tool=""
  local state=""

  printf '['
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    tool="${line%%|*}"
    state="${line#*|}"
    if [ "$first" -eq 0 ]; then
      printf ', '
    fi
    printf '{ "tool": "%s", "status": "%s" }' \
      "$(dev_kit_json_escape "$tool")" \
      "$(dev_kit_json_escape "$state")"
    first=0
  done <<EOF
$(dev_kit_env_tool_lines)
EOF
  printf ']'
}
