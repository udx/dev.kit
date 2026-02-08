#!/usr/bin/env bash
set -euo pipefail

# github.sh
#
# GitHub triage helper (GH CLI only): assigned issues, my PRs, PRs to review.
# Ensures authentication before each command execution.
#
# Requirements:
#   - gh (GitHub CLI)
#
# Auth:
#   - Preferred: GH_TOKEN or GITHUB_TOKEN (non-interactive)
#   - Otherwise: interactive "gh auth login" when needed
#
# Usage:
#   dev.kit github assigned-issues [--repo OWNER/REPO] [--state open|closed|all] [--limit N] [--json]
#   dev.kit github my-prs         [--repo OWNER/REPO] [--state open|closed|merged|all] [--limit N] [--json]
#   dev.kit github review-prs     [--repo OWNER/REPO] [--state open|closed|merged|all] [--limit N] [--json] [--include-drafts]

dev_kit_cmd_github() {
  shift || true

  LIMIT=30
  STATE="open"       # issues: open|closed|all ; prs: open|closed|merged|all
  REPO=""
  JSON=0
  INCLUDE_DRAFTS=0
  COMMAND=""

  die() { echo "ERROR: $*" >&2; exit 1; }

  usage() {
    cat <<EOF
dev.kit github: GitHub triage helper (GH CLI only)

Usage:
  dev.kit github <command> [options]

Commands:
  assigned-issues    List issues assigned to you
  my-prs             List PRs authored by you
  review-prs         List PRs requesting your review

Options:
  --repo OWNER/REPO      Restrict to one repository
  --state STATE          open|closed|merged|all (default: open)
  --limit N              Max results (default: 30)
  --json                 JSON output (adds useful default fields)
  --include-drafts       (review-prs only) include draft PRs
  -h, --help             Show this help

Auth:
  - Preferred: export GH_TOKEN=... (or GITHUB_TOKEN=...)
  - Otherwise: gh auth login (interactive)

EOF
  }

  need_gh() {
    command -v gh >/dev/null 2>&1 || die "gh not found. Install GitHub CLI: https://cli.github.com/"
  }

  ensure_auth() {
    if [[ -n "${GH_TOKEN:-}" || -n "${GITHUB_TOKEN:-}" ]]; then
      return 0
    fi

    if gh auth status >/dev/null 2>&1; then
      return 0
    fi

    echo "No GH_TOKEN/GITHUB_TOKEN and gh not authenticated. Running: gh auth login" >&2
    gh auth login 1>&2
    gh auth status >/dev/null 2>&1 || die "gh authentication failed"
  }

  run_gh() {
    ensure_auth
    gh "$@"
  }

  assigned_issues() {
    case "$STATE" in open|closed|all) ;; *) die "assigned-issues: --state must be open|closed|all" ;; esac

    local args=(issue list --assignee @me --limit "$LIMIT" --state "$STATE")
    [[ -n "$REPO" ]] && args+=(--repo "$REPO")
    if [[ "$JSON" -eq 1 ]]; then
      args+=(--json number,title,url,updatedAt,createdAt,state)
    fi
    run_gh "${args[@]}"
  }

  my_prs() {
    case "$STATE" in open|closed|merged|all) ;; *) die "my-prs: --state must be open|closed|merged|all" ;; esac

    local args=(pr list --author @me --limit "$LIMIT" --state "$STATE")
    [[ -n "$REPO" ]] && args+=(--repo "$REPO")
    if [[ "$JSON" -eq 1 ]]; then
      args+=(--json number,title,url,updatedAt,createdAt,state,isDraft)
    fi
    run_gh "${args[@]}"
  }

  review_prs() {
    case "$STATE" in open|closed|merged|all) ;; *) die "review-prs: --state must be open|closed|merged|all" ;; esac

    local args=(pr list --search "review-requested:@me" --limit "$LIMIT" --state "$STATE")
    [[ -n "$REPO" ]] && args+=(--repo "$REPO")
    if [[ "$INCLUDE_DRAFTS" -eq 0 ]]; then
      args+=(--draft=false)
    fi
    if [[ "$JSON" -eq 1 ]]; then
      args+=(--json number,title,url,updatedAt,createdAt,state,isDraft)
    fi
    run_gh "${args[@]}"
  }

  while [[ $# -gt 0 ]]; do
    case "$1" in
      assigned-issues|my-prs|review-prs)
        COMMAND="$1"; shift;;
      --repo)
        REPO="${2:-}"; shift 2;;
      --state)
        STATE="${2:-}"; shift 2;;
      --limit)
        LIMIT="${2:-}"; shift 2;;
      --json)
        JSON=1; shift;;
      --include-drafts)
        INCLUDE_DRAFTS=1; shift;;
      -h|--help)
        usage; exit 0;;
      *)
        die "Unknown argument: $1 (use --help)";;
    esac
  done

  [[ -n "$COMMAND" ]] || { usage; exit 1; }

  need_gh

  case "$COMMAND" in
    assigned-issues) assigned_issues ;;
    my-prs) my_prs ;;
    review-prs) review_prs ;;
    *) die "Unknown command: $COMMAND" ;;
  esac
}
