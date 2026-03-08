#!/usr/bin/env bash

# @description: Provides high-fidelity integration with GitHub CLI (gh) for remote context.
# @intent: github, pr, issue, remote, discovery
# @objective: Empower agents and humans to interact with the broader engineering ecosystem via authenticated remote discovery and collaboration.

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

# Check if a Pull Request exists for a specific branch
# Returns the PR number if it exists, empty otherwise
dev_kit_github_pr_exists() {
  local head="${1:-$(git branch --show-current)}"
  gh pr list --head "$head" --json number --jq '.[0].number' 2>/dev/null
}

# Create or Update a Pull Request
# Usage: dev_kit_github_pr_create <title> <body> [base_branch] [head_branch] [draft_flag]
dev_kit_github_pr_create() {
  local title="$1"
  local body="$2"
  local base="${3:-main}"
  local head="${4:-$(git branch --show-current)}"
  local draft="${5:-false}"

  dev_kit_github_health || return $?

  local pr_number
  pr_number=$(dev_kit_github_pr_exists "$head")

  if [ -n "$pr_number" ]; then
    echo "✔ Found existing Pull Request #$pr_number. Updating..."
    gh pr edit "$pr_number" --title "$title" --body "$body"
  else
    local args=(pr create --title "$title" --body "$body" --base "$base" --head "$head")
    [[ "$draft" == "true" ]] && args+=(--draft)
    gh "${args[@]}"
  fi
}
