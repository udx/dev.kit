#!/bin/bash

DEV_KIT_CONTEXTS_FILE="${DEV_KIT_CONTEXTS_FILE:-$HOME/.udx/dev.kit/contexts.json}"

context_repo_root() {
  if command -v git >/dev/null 2>&1; then
    git rev-parse --show-toplevel 2>/dev/null || true
  fi
}

context_path_for_module() {
  local module="$1"
  local root
  root="$(context_repo_root)"
  if [ -z "$root" ]; then
    return 1
  fi
  echo "$root/.udx/dev.kit/$module"
}

context_register() {
  local module="$1"
  local root path now
  root="$(context_repo_root)"
  if [ -z "$root" ]; then
    return 1
  fi
  path="$(context_path_for_module "$module")"
  now="$(date -Iseconds)"
  python3 - "$DEV_KIT_CONTEXTS_FILE" "$root" "$module" "$path" "$now" <<'PY'
import json,os,sys

path, repo, module, ctx_path, ts = sys.argv[1:]
data = {"repos": []}

if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError:
            data = {"repos": []}

repos = data.get("repos", [])
found = False
for entry in repos:
    if entry.get("repo") == repo and entry.get("module") == module:
        entry["path"] = ctx_path
        entry["last_seen"] = ts
        found = True
        break
if not found:
    repos.append({
        "repo": repo,
        "module": module,
        "path": ctx_path,
        "last_seen": ts
    })

data["repos"] = repos
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
PY
}
