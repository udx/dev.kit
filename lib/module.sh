#!/bin/bash

module_manifest_path() {
  local module="$1"
  if [ -z "$module" ]; then
    return 1
  fi
  echo "$REPO_DIR/public/modules/$module.json"
}

module_manifest_exists() {
  local module="$1"
  local path
  path="$(module_manifest_path "$module")" || return 1
  [ -f "$path" ]
}

module_manifest_list() {
  local dir="$REPO_DIR/public/modules"
  if [ ! -d "$dir" ]; then
    return 0
  fi
  for path in "$dir"/*.json; do
    [ -f "$path" ] || continue
    basename "$path" .json
  done
}

module_manifest_show() {
  local module="$1"
  local path
  path="$(module_manifest_path "$module")" || return 1
  if [ ! -f "$path" ]; then
    echo "Module manifest not found: $path" >&2
    return 1
  fi
  cat "$path"
}

module_manifest_field() {
  local module="$1"
  local key="$2"
  local path
  path="$(module_manifest_path "$module")" || return 1
  if [ ! -f "$path" ]; then
    echo "Module manifest not found: $path" >&2
    return 1
  fi
  if [ -z "$key" ]; then
    echo "Missing key for module manifest lookup." >&2
    return 1
  fi
  python3 - "$path" "$key" <<'PY'
import json
import sys

path, key = sys.argv[1], sys.argv[2]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
for part in key.split("."):
    if isinstance(data, dict) and part in data:
        data = data[part]
    else:
        sys.exit(1)
if isinstance(data, (dict, list)):
    print(json.dumps(data, indent=2))
else:
    print(data)
PY
}
