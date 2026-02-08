#!/usr/bin/env bash
set -euo pipefail

# prompt.sh
# Generates a prompt artifact from templates/prompts.
#
# Usage:
#   dev.kit prompt --request "Update docs" --template ai.codex --out prompt.md
#
# Defaults:
# - template: base
# - if request is empty -> default request: "Do you need help with anything?"
#
# Config via env:
#   PROMPT_TEMPLATE (fallback: PROMPT_DEFAULT_TEMPLATE)
#   PROMPT_OUT (fallback: PROMPT_DEFAULT_OUT)

DEFAULT_TEMPLATE="${PROMPT_TEMPLATE:-${PROMPT_DEFAULT_TEMPLATE:-base}}"
DEFAULT_OUT="${PROMPT_OUT:-${PROMPT_DEFAULT_OUT:-}}"

TEMPLATE_ROOT="${REPO_DIR}/templates/prompts"

dev_kit_prompt_list_templates() {
  while IFS= read -r name; do
    printf "%s\n" "$name"
  done < <(find "$TEMPLATE_ROOT" -type f -name 'index.md' -print \
    | sed "s#^${TEMPLATE_ROOT}/##" \
    | sed 's#/index\.md$##' \
    | sed 's#^index\.md$#base#' \
    | sed 's#^$#base#' \
    | sed 's#/#.#g' \
    | sort)
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

normalize_template() {
  local value="$1"
  value="${value//\//.}"
  printf "%s" "$value"
}

resolve_template_files() {
  local selection="$1"
  local normalized=""
  local base="${TEMPLATE_ROOT}/index.md"
  local dotted=""

  if [ -z "$selection" ]; then
    selection="$DEFAULT_TEMPLATE"
  fi

  if [ -d "$selection" ]; then
    if [ -f "$selection/index.md" ]; then
      printf "%s\n" "$selection/index.md"
      return 0
    fi
  fi

  if [ -f "$selection" ]; then
    printf "%s\n" "$selection"
    return 0
  fi

  if [ -f "${TEMPLATE_ROOT}/${selection}" ]; then
    printf "%s\n" "${TEMPLATE_ROOT}/${selection}"
    return 0
  fi

  normalized="$(normalize_template "$selection")"
  if [ "$normalized" = "base" ]; then
    printf "%s\n" "$base"
    return 0
  fi

  dotted="${normalized//./\/}"
  if [ -f "${TEMPLATE_ROOT}/${dotted}/index.md" ]; then
    printf "%s\n" "${TEMPLATE_ROOT}/${dotted}/index.md"
    return 0
  fi
  if [ -f "${TEMPLATE_ROOT}/${dotted}" ]; then
    printf "%s\n" "${TEMPLATE_ROOT}/${dotted}"
    return 0
  fi

  echo "Unknown template: ${selection}" >&2
  echo "Run --list to see available templates." >&2
  exit 1
}

set_remove() {
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

resolve_inherit_path() {
  local item="$1"
  local from_file="$2"
  local from_dir
  from_dir="$(dirname "$from_file")"
  local candidate=""

  if [[ "$item" == /* ]]; then
    if [ -f "$item" ]; then
      printf "%s\n" "$item"
      return 0
    fi
    if [ -d "$item" ] && [ -f "$item/index.md" ]; then
      printf "%s\n" "$item/index.md"
      return 0
    fi
  fi

  candidate="${from_dir}/${item}"
  if [ -f "$candidate" ]; then
    printf "%s\n" "$candidate"
    return 0
  fi
  if [ -d "$candidate" ] && [ -f "$candidate/index.md" ]; then
    printf "%s\n" "$candidate/index.md"
    return 0
  fi

  if [ -f "$item" ]; then
    printf "%s\n" "$item"
    return 0
  fi
  if [ -d "$item" ] && [ -f "$item/index.md" ]; then
    printf "%s\n" "$item/index.md"
    return 0
  fi

  if [ -f "${TEMPLATE_ROOT}/${item}" ]; then
    printf "%s\n" "${TEMPLATE_ROOT}/${item}"
    return 0
  fi
  if [ -d "${TEMPLATE_ROOT}/${item}" ] && [ -f "${TEMPLATE_ROOT}/${item}/index.md" ]; then
    printf "%s\n" "${TEMPLATE_ROOT}/${item}/index.md"
    return 0
  fi

  if [ "$item" = "base" ]; then
    printf "%s\n" "${TEMPLATE_ROOT}/index.md"
    return 0
  fi

  local dotted="${item//./\/}"
  if [ -f "${TEMPLATE_ROOT}/${dotted}/index.md" ]; then
    printf "%s\n" "${TEMPLATE_ROOT}/${dotted}/index.md"
    return 0
  fi
  if [ -f "${TEMPLATE_ROOT}/${dotted}" ]; then
    printf "%s\n" "${TEMPLATE_ROOT}/${dotted}"
    return 0
  fi

  echo "Unknown inherited template: ${item} (from ${from_file})" >&2
  exit 1
}

parse_inherits() {
  local file="$1"
  local line=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*Inherits:[[:space:]]*(.*)$ ]]; then
      local inherits="${BASH_REMATCH[1]}"
      inherits="${inherits//\`/}"
      printf "%s\n" "$inherits" | tr ',' '\n' | while IFS= read -r raw; do
        local item=""
        item="$(printf "%s" "$raw" | xargs)"
        [ -z "$item" ] && continue
        resolve_inherit_path "$item" "$file"
      done
      return 0
    fi
  done < "$file"
}

TEMPLATE_FILES=()
TEMPLATE_FILES_SET=$'\n'
TEMPLATE_FILES_VISITING=$'\n'

add_template_file() {
  local file="$1"
  if [[ "$TEMPLATE_FILES_SET" == *$'\n'"$file"$'\n'* ]]; then
    return 0
  fi
  TEMPLATE_FILES+=("$file")
  TEMPLATE_FILES_SET+="$file"$'\n'
}

add_with_inherits() {
  local file="$1"
  if [[ "$TEMPLATE_FILES_SET" == *$'\n'"$file"$'\n'* ]]; then
    return 0
  fi
  if [[ "$TEMPLATE_FILES_VISITING" == *$'\n'"$file"$'\n'* ]]; then
    echo "Cyclic template inheritance detected at: ${file}" >&2
    exit 1
  fi
  TEMPLATE_FILES_VISITING+="$file"$'\n'
  while IFS= read -r inherit; do
    [ -z "$inherit" ] && continue
    add_with_inherits "$inherit"
  done < <(parse_inherits "$file")
  set_remove TEMPLATE_FILES_VISITING "$file"
  add_template_file "$file"
}

collect_template_files() {
  local selection="$1"
  local initial=""
  initial="$(resolve_template_files "$selection")"

  TEMPLATE_FILES=()
  TEMPLATE_FILES_SET=$'\n'
  TEMPLATE_FILES_VISITING=$'\n'

  local file=""
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    add_with_inherits "$file"
  done <<< "$initial"
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

  collect_template_files "$template"

  local prompt=""
  local file=""
  for file in "${TEMPLATE_FILES[@]}"; do
    if [ ! -f "$file" ]; then
      echo "Template not found: $file" >&2
      exit 1
    fi
    if [ -n "$prompt" ]; then
      prompt+=$'\n\n---\n\n'
    fi
    prompt+=$(cat "$file")
  done

  prompt+=$'\n\n## User Request\n'"${request}"

  DEV_KIT_PROMPT_BODY="$prompt"
  DEV_KIT_PROMPT_PATHS=("${TEMPLATE_FILES[@]}")
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
