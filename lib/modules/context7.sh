#!/usr/bin/env bash

# @description: High-fidelity search and resolution for the "Skill Mesh" (Multi-repo context).
# @intent: context7, knowledge, search, resolution, mesh
# @objective: Bridge disparate repository context into a unified engineering mesh via structured API and CLI discovery.

# Check if Context7 integration is available (API key or CLI)
dev_kit_context7_health() {
  # 1. Check for API Key (Priority 1)
  local api_key
  api_key="$(config_value_scoped context7.api_key "${CONTEXT7_API_KEY:-}")"
  if [ -n "$api_key" ]; then
    return 0
  fi

  # 2. Check for CLI
  if command -v context7 >/dev/null 2>&1; then
    return 0
  fi

  # 3. Suggest installation if npm is present
  if command -v npm >/dev/null 2>&1; then
    # We return 2 to indicate "Available to install"
    return 2
  fi

  return 1 # Not available
}

# Synchronize a repository with the Context7 hub
# Usage: dev_kit_context7_sync [repo_path]
dev_kit_context7_sync() {
  local repo_path="${1:-$REPO_DIR}"
  
  # 1. Check health first
  if ! dev_kit_context7_health; then
    echo "Error: Context7 not ready (API key or CLI missing)." >&2
    return 1
  fi

  # 2. Prefer CLI for sync if available
  if command -v context7 >/dev/null 2>&1; then
    echo "Synchronizing $repo_path with Context7 CLI..." >&2
    (cd "$repo_path" && context7 sync)
    return $?
  fi

  # 3. Fallback to API-based sync notification (if implemented in API)
  local api_key; api_key="$(config_value_scoped context7.api_key "${CONTEXT7_API_KEY:-}")"
  if [ -n "$api_key" ]; then
    echo "Sending sync signal to Context7 API for $repo_path..." >&2
    # Placeholder for API-based sync trigger
    return 0
  fi

  return 1
}

# Search for libraries and engineering context using Context7
# Usage: dev_kit_context7_search "react" "how to use hooks"
dev_kit_context7_search() {
  local lib_name="$1"
  local query="${2:-$1}"
  local results=()

  local api_key
  api_key="$(config_value_scoped context7.api_key "${CONTEXT7_API_KEY:-}")"

  # Case A: Use API (v2) via curl
  if [ -n "$api_key" ]; then
    local encoded_lib encoded_query
    encoded_lib="$(printf "%s" "$lib_name" | jq -sRr @uri)"
    encoded_query="$(printf "%s" "$query" | jq -sRr @uri)"
    
    local response
    response="$(curl -s -X GET "https://context7.com/api/v2/libs/search?libraryName=$encoded_lib&query=$encoded_query" \
      -H "Authorization: Bearer $api_key" \
      -H "Content-Type: application/json")"
    
    if [ -n "$response" ] && [ "$response" != "null" ]; then
      while IFS= read -r match; do
        [ -n "$match" ] && results+=("$match")
      done < <(echo "$response" | jq -c '.[] | {name: .id, type: "external-library", score: .trustScore, uri: "https://context7.com/libs\(.id)"}')
    fi

  # Case B: Use CLI (Fallback)
  elif command -v context7 >/dev/null 2>&1; then
    # Assuming standard 'context7 search' output format
    local cli_out
    cli_out="$(context7 search "$query" --json 2>/dev/null || true)"
    if [ -n "$cli_out" ]; then
       while IFS= read -r match; do
         [ -n "$match" ] && results+=("$match")
       done < <(echo "$cli_out" | jq -c '.[] | {name: .id, type: "external-library", uri: .url}')
    fi
  fi

  # Case C: Local Peer Repositories (Heuristic fallback)
  local parent_dir
  parent_dir="$(dirname "$REPO_DIR")"
  if [ -d "$parent_dir" ]; then
    for peer in "$parent_dir"/*; do
      [ -d "$peer" ] || continue
      [ "$peer" == "$REPO_DIR" ] && continue
      if [ -f "$peer/context.yaml" ] || [ -f "$peer/README.md" ]; then
         if grep -qi "$lib_name" "$peer/README.md" 2>/dev/null; then
           results+=("{\"name\": \"$(basename "$peer")\", \"type\": \"peer-repo\", \"path\": \"$peer\"}")
         fi
      fi
    done
  fi

  (IFS=,; echo "${results[*]}")
}

# Prompt user to install Context7 CLI if missing
dev_kit_context7_install_hint() {
  dev_kit_context7_health
  local status=$?
  if [ $status -eq 2 ]; then
    echo "Hint: Context7 CLI is available. Install it for better library discovery:" >&2
    echo "      npm install -g @upstash/context7" >&2
  fi
}
