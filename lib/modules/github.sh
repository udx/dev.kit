#!/usr/bin/env bash

# dev.kit GitHub Module
# Provides high-fidelity integration with GitHub CLI (gh) for remote context.

# Check if GitHub CLI is available and optionally if a token is set
dev_kit_github_health() {
  if ! command -v gh >/dev/null 2>&1; then
    return 1 # CLI missing
  fi
  
  # Check for token or active login
  if [ -z "${GITHUB_TOKEN:-}" ] && [ -z "${GH_TOKEN:-}" ]; then
    if ! gh auth status >/dev/null 2>&1; then
      return 2 # Not authenticated
    fi
  fi
  
  return 0 # Healthy
}

# Search for repositories by name/keyword within the UDX or specified organization
dev_kit_github_search_repos() {
  local query="$1"
  local owner="${2:-udx}"
  
  dev_kit_github_health || return $?
  
  # Limit results to keep context manageable
  gh repo list "$owner" --json name,description,url --limit 10 -S "$query" 2>/dev/null | \
    jq -c '.[] | {name: .name, type: "remote-repo", uri: .url, description: .description}'
}

# Search for reusable GitHub workflow templates/files
dev_kit_github_search_workflows() {
  local query="$1"
  local repo="${2:-udx/workflow-templates}"
  
  dev_kit_github_health || return $?
  
  # Search for .yml or .yaml files in the .github/workflows directory or similar
  # This is a heuristic search using gh api or search code
  gh api "search/code?q=repo:$repo+$query+path:.github/workflows+extension:yml" \
    --jq '.items[] | {name: .name, type: "workflow-template", uri: .html_url, path: .path}' 2>/dev/null
}

# List active GitHub Runners for an organization (for infrastructure context)
dev_kit_github_list_runners() {
  local org="${1:-udx}"
  
  dev_kit_github_health || return $?
  
  gh api "orgs/$org/actions/runners" --jq '.runners[] | {name: .name, status: .status, labels: [.labels[].name]}' 2>/dev/null
}
