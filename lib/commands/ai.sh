#!/bin/bash

print_ai_usage() {
  cat <<'AI_USAGE'
Usage: dev.kit ai <command>

Commands:
  skills   List available AI skills and supported AI CLIs
AI_USAGE
}

trim_value() {
  local val="$1"
  val="${val#"${val%%[![:space:]]*}"}"
  val="${val%"${val##*[![:space:]]}"}"
  val="${val#\"}"
  val="${val%\"}"
  val="${val#\'}"
  val="${val%\'}"
  printf "%s" "$val"
}

skill_frontmatter_value() {
  local file="$1"
  local key="$2"
  awk -v k="$key" '
    $0 ~ /^---[[:space:]]*$/ { fence++; next }
    fence == 1 {
      if ($1 == k ":") {
        $1=""; sub(/^[[:space:]]+/, ""); print; exit
      }
    }
  ' "$file"
}

list_skill_entries() {
  local base="$1"
  local scope="$2"
  local file dir name
  [ -d "$base" ] || return 0

  for file in "$base"/*/SKILL.md; do
    [ -f "$file" ] || continue
    dir="$(dirname "$file")"
    name="$(skill_frontmatter_value "$file" "name")"
    name="$(trim_value "$name")"
    if [ -z "$name" ]; then
      name="$(basename "$dir")"
    fi
    printf "%s\t%s\t%s\n" "$name" "$file" "$scope"
  done
}

print_skill_list() {
  local repo_root=""
  local tmp
  tmp="$(mktemp)"

  repo_root="$(get_repo_root || true)"
  if [ -n "$repo_root" ]; then
    list_skill_entries "$repo_root/.codex/skills" "repo" >>"$tmp"
  fi
  list_skill_entries "$HOME/.codex/skills" "user" >>"$tmp"

  if [ ! -s "$tmp" ]; then
    echo "Skills:"
    echo "(none found)"
    rm -f "$tmp"
    return 0
  fi

  local ai_supported=()
  if command -v codex >/dev/null 2>&1; then
    ai_supported+=("codex")
  fi
  if command -v claude >/dev/null 2>&1; then
    ai_supported+=("claude")
  fi

  echo "Skills:"

  sort -f "$tmp" | while IFS=$'\t' read -r name file scope; do
    echo "- name: $name"
    echo "  how_exec: trigger by name or description match ($scope skill)"
    echo "  inputs:"
    echo "    - $file"
    echo "  ai_supported:"
    if [ "${#ai_supported[@]}" -gt 0 ]; then
      local cli
      for cli in "${ai_supported[@]}"; do
        echo "    - $cli"
      done
    else
      echo "    - (none detected)"
    fi
    echo ""
  done

  rm -f "$tmp"
}

dev_kit_cmd_ai() {
  shift || true
  case "${1:-}" in
    skills)
      print_skill_list
      ;;
    -h|--help|help|"" )
      print_ai_usage
      ;;
    *)
      echo "Unknown ai command: ${1:-}" >&2
      print_ai_usage
      exit 1
      ;;
  esac
}
