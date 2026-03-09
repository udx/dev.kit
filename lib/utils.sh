#!/usr/bin/env bash

dev_kit_warn() {
  echo "$*" >&2
}

dev_kit_require_cmd() {
  local cmd="${1:-}"
  local context="${2:-}"
  if [ -z "$cmd" ]; then
    dev_kit_warn "Missing required command name."
    return 1
  fi
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi
  if [ -n "$context" ]; then
    dev_kit_warn "$cmd is required for $context."
  else
    dev_kit_warn "$cmd is required."
  fi
  dev_kit_warn "Install $cmd locally or run the task in the worker container (see udx/worker-deployment)."
  return 1
}

dev_kit_yaml_value() {
  local file="$1"
  local key_path="$2"
  local default="${3:-}"
  [ -f "$file" ] || { echo "$default"; return; }

  # Simple awk parser for nested keys (e.g. system.quiet)
  local awk_script='
    BEGIN { FS=":[[:space:]]*"; key_idx=1; split(target_path, keys, "."); target_depth=length(keys); }
    {
      # Count leading spaces to determine depth
      match($0, /^[[:space:]]*/);
      depth = RLENGTH / 2 + 1;
      line_key = $1;
      sub(/^[[:space:]]*/, "", line_key);

      # If depth matches and key matches, move to next key in path
      if (depth == key_idx && line_key == keys[key_idx]) {
        if (key_idx == target_depth) {
          # Found it! Extract value
          val = $0;
          sub(/^[^:]*:[[:space:]]*/, "", val);
          # Strip trailing comments
          sub(/[[:space:]]*#.*$/, "", val);
          # Trim quotes
          gsub(/^["\047]|["\047]$/, "", val);
          print val;
          found=1;
          exit;
        }
        key_idx++;
      }
 else if (depth <= key_idx - 1 && line_key != "") {
        # Reset if we move back up or across at same level
        # This is a naive reset but works for many simple YAML structures
        # key_idx = depth; # (simplified)
      }
    }
    END { if (!found) print default_val; }
  '
  awk -v target_path="$key_path" -v default_val="$default" "$awk_script" "$file"
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

confirm_action() {
  local msg="$1"
  if [ ! -t 0 ]; then
    return 1
  fi
  printf "%s [y/N] " "$msg"
  read -r answer || true
  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

dev_kit_validate_json_required() {
  local schema="$1"
  local data="$2"
  local req=""
  if ! command -v jq >/dev/null 2>&1; then
    return 0
  fi
  req="$(jq -r '.required[]?' "$schema")"
  local field=""
  for field in $req; do
    if ! jq -e --arg f "$field" 'has($f) and .[$f] != null' "$data" >/dev/null; then
      echo "Missing required field '$field' in $data" >&2
      exit 1
    fi
  done
}

get_repo_state_dir() {
  local root; root="$(get_repo_root || true)"
  if [ -n "$root" ]; then
    echo "$root/.udx/dev.kit"
  else
    echo "$PWD/.udx/dev.kit"
  fi
}

get_tasks_dir() {
  echo "$(get_repo_state_dir)/tasks"
}
