#!/usr/bin/env bash
set -euo pipefail

# prompt.sh
# Generates a prompt artifact from src/ai data.
#
# Usage:
#   dev.kit prompt --request "Update docs" --template ai.codex --out prompt.md
#
# Defaults:
# - template: ai
# - if request is empty -> default request: "Do you need help with anything?"
#
# Config via env:
#   PROMPT_TEMPLATE (fallback: PROMPT_DEFAULT_TEMPLATE)
#   PROMPT_OUT (fallback: PROMPT_DEFAULT_OUT)

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

DEFAULT_TEMPLATE="${PROMPT_TEMPLATE:-${PROMPT_DEFAULT_TEMPLATE:-ai}}"
DEFAULT_OUT="${PROMPT_OUT:-${PROMPT_DEFAULT_OUT:-}}"

PROMPT_DATA_DIR="${REPO_DIR}/src/ai/data"
PROMPT_INTEGRATION_DIR="${REPO_DIR}/src/ai/integrations/codex"
PROMPT_SCHEMA="${PROMPT_INTEGRATION_DIR}/schemas/prompts.schema.json"
PROMPT_INDEX_JSON=""
PROMPT_INDEX_LOADED="0"

dev_kit_prompt_require_jq() {
  if ! dev_kit_require_cmd "jq" "dev.kit prompt rendering"; then
    exit 1
  fi
}

dev_kit_prompt_validate_required() {
  local schema="$1"
  local data="$2"
  local req=""
  req="$(jq -r '.required[]?' "$schema")"
  local field=""
  for field in $req; do
    if ! jq -e --arg f "$field" 'has($f) and .[$f] != null' "$data" >/dev/null; then
      echo "Missing required field '$field' in $data" >&2
      exit 1
    fi
  done
}

dev_kit_prompt_data_files() {
  local files=()
  if [ -f "$PROMPT_DATA_DIR/prompts.json" ]; then
    files+=("$PROMPT_DATA_DIR/prompts.json")
  fi
  if [ -f "$PROMPT_INTEGRATION_DIR/prompts.json" ]; then
    files+=("$PROMPT_INTEGRATION_DIR/prompts.json")
  fi
  printf "%s\n" "${files[@]}"
}

dev_kit_prompt_load_index() {
  if [ "$PROMPT_INDEX_LOADED" = "1" ]; then
    return 0
  fi

  dev_kit_prompt_require_jq

  local files=()
  local file=""
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    files+=("$file")
  done < <(dev_kit_prompt_data_files)

  if [ "${#files[@]}" -eq 0 ]; then
    echo "Missing prompt data in ${PROMPT_DATA_DIR}." >&2
    exit 1
  fi

  if [ -f "$PROMPT_SCHEMA" ]; then
    for file in "${files[@]}"; do
      dev_kit_prompt_validate_required "$PROMPT_SCHEMA" "$file"
    done
  fi

  PROMPT_INDEX_JSON="$(jq -s '{prompts: [.[].prompts[]?] }' "${files[@]}")"
  PROMPT_INDEX_LOADED="1"

  local dup=""
  dup="$(printf "%s" "$PROMPT_INDEX_JSON" | jq -r '.prompts[].key' | sort | uniq -d || true)"
  if [ -n "$dup" ]; then
    echo "Duplicate prompt key(s):" >&2
    printf "%s\n" "$dup" >&2
    exit 1
  fi
}

dev_kit_prompt_list_templates() {
  dev_kit_prompt_load_index
  printf "%s" "$PROMPT_INDEX_JSON" | jq -r '.prompts[].key' | sort
}

prompt_value() {
  local label="$1"
  local default="${2:-}"
  local input=""
  if [ -n "${PROMPT_TTY:-}" ]; then
    if [ -n "$default" ]; then
      printf "%s [%s]: " "$label" "$default" > "${PROMPT_TTY}"
    else
      printf "%s: " "$label" > "${PROMPT_TTY}"
    fi
    read -r input < "${PROMPT_TTY}" || true
  elif [ -t 0 ]; then
    if [ -n "$default" ]; then
      printf "%s [%s]: " "$label" "$default"
    else
      printf "%s: " "$label"
    fi
    read -r input || true
  fi
  if [ -n "$input" ]; then
    printf "%s" "$input"
  else
    printf "%s" "$default"
  fi
}

dev_kit_prompt_entry() {
  local key="$1"
  dev_kit_prompt_load_index
  printf "%s" "$PROMPT_INDEX_JSON" | jq -c --arg key "$key" '.prompts[] | select(.key == $key)'
}

dev_kit_prompt_inherits() {
  local entry="$1"
  printf "%s" "$entry" | jq -r '.inherits[]?'
}

PROMPT_KEYS=()
PROMPT_KEYS_SET=$'\n'
PROMPT_KEYS_VISITING=$'\n'

prompt_set_remove() {
  local set_name="$1"
  local value="$2"
  local current="${!set_name}"
  local updated=""
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if [ "$line" != "$value" ]; then
      updated+="${line}"$'\n'
    fi
  done <<< "$current"
  printf -v "$set_name" "%s" "$updated"
}

prompt_add_key() {
  local key="$1"
  if [[ "$PROMPT_KEYS_SET" == *$'\n'"$key"$'\n'* ]]; then
    return 0
  fi
  PROMPT_KEYS+=("$key")
  PROMPT_KEYS_SET+="$key"$'\n'
}

prompt_add_with_inherits() {
  local key="$1"
  if [[ "$PROMPT_KEYS_SET" == *$'\n'"$key"$'\n'* ]]; then
    return 0
  fi
  if [[ "$PROMPT_KEYS_VISITING" == *$'\n'"$key"$'\n'* ]]; then
    echo "Cyclic prompt inheritance detected at: ${key}" >&2
    exit 1
  fi
  local entry=""
  entry="$(dev_kit_prompt_entry "$key")"
  if [ -z "$entry" ]; then
    echo "Unknown prompt: ${key}" >&2
    echo "Run --list to see available templates." >&2
    exit 1
  fi
  PROMPT_KEYS_VISITING+="$key"$'\n'
  while IFS= read -r inherit; do
    [ -z "$inherit" ] && continue
    prompt_add_with_inherits "$inherit"
  done < <(dev_kit_prompt_inherits "$entry")
  prompt_set_remove PROMPT_KEYS_VISITING "$key"
  prompt_add_key "$key"
}

dev_kit_prompt_collect_keys() {
  local selection="$1"
  if [ -z "$selection" ]; then
    selection="$DEFAULT_TEMPLATE"
  fi
  PROMPT_KEYS=()
  PROMPT_KEYS_SET=$'\n'
  PROMPT_KEYS_VISITING=$'\n'
  prompt_add_with_inherits "$selection"
}

dev_kit_prompt_render_entry() {
  local entry="$1"
  local title=""
  local body=""
  title="$(printf "%s" "$entry" | jq -r '.title // ""')"
  body="$(printf "%s" "$entry" | jq -r '.body[]?')"
  if [ -n "$title" ]; then
    if [ -n "$body" ]; then
      printf "# %s\n\n%s" "$title" "$body"
    else
      printf "# %s" "$title"
    fi
  else
    printf "%s" "$body"
  fi
}

DEV_KIT_PROMPT_BODY=""
DEV_KIT_PROMPT_PATHS=()

dev_kit_prompt_build() {
  local template="${1:-}"
  local request="${2:-}"
  local request_trim=""

  request_trim="${request//[[:space:]]/}"
  if [[ -z "${request_trim}" ]]; then
    request="Do you need help with anything?"
  fi

  dev_kit_prompt_collect_keys "$template"

  local prompt=""
  local key=""
  for key in "${PROMPT_KEYS[@]}"; do
    local entry=""
    entry="$(dev_kit_prompt_entry "$key")"
    if [ -n "$prompt" ]; then
      prompt+=$'\n\n---\n\n'
    fi
    prompt+=$(dev_kit_prompt_render_entry "$entry")
  done

  local context="${DEV_KIT_PROMPT_CONTEXT:-}"
  if [ -n "$context" ]; then
    prompt+=$'\n\n## Context\n'"${context}"
  fi

  prompt+=$'\n\n## User Request\n'"${request}"

  DEV_KIT_PROMPT_BODY="$prompt"
  DEV_KIT_PROMPT_PATHS=("${PROMPT_KEYS[@]}")
}

dev_kit_cmd_prompt() {
  shift || true

  local request=""
  local template="$DEFAULT_TEMPLATE"
  local out_file="$DEFAULT_OUT"
  local request_set="0"
  local template_set="0"
  local out_set="0"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --request|--todo)
        request="${2:-}"; request_set="1"; shift 2 ;;
      --template)
        template="${2:-}"; template_set="1"; shift 2 ;;
      --out)
        out_file="${2:-}"; out_set="1"; shift 2 ;;
      --list)
        dev_kit_prompt_list_templates
        exit 0 ;;
      -h|--help)
        cat <<'USAGE'
Usage: dev.kit prompt [options]

Options:
  --request TEXT   (alias: --todo)
  --template NAME|PATH
  --list           show available template names
  --out FILE

Env defaults:
  PROMPT_TEMPLATE (fallback: PROMPT_DEFAULT_TEMPLATE)
  PROMPT_OUT (fallback: PROMPT_DEFAULT_OUT)
USAGE
        exit 0 ;;
      *)
        echo "Unknown arg: $1" >&2
        exit 1 ;;
    esac
  done

  if [ "$request_set" = "0" ] && [ ! -t 0 ]; then
    request="$(cat || true)"
    request_set="1"
  fi

  if [ -t 0 ] && [ -r /dev/tty ] && [ -w /dev/tty ]; then
    PROMPT_TTY="/dev/tty"
  fi

  if [ -t 0 ]; then
    if [ "$request_set" = "0" ]; then
      request="$(prompt_value "Request" "")"
    fi
    if [ "$template_set" = "0" ]; then
      template="$(prompt_value "Template (run --list to see options)" "$DEFAULT_TEMPLATE")"
    fi
    if [ "$out_set" = "0" ]; then
      out_file="$(prompt_value "Output file (optional)" "$DEFAULT_OUT")"
    fi
  fi

  dev_kit_prompt_build "$template" "$request"

  if [[ -n "${out_file}" ]]; then
    printf "%s\n" "${DEV_KIT_PROMPT_BODY}" > "${out_file}"
  else
    printf "%s\n" "${DEV_KIT_PROMPT_BODY}"
  fi
}
