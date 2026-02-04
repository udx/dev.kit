# Global Codex Instructions

## Efficiency defaults
  - Prefer shell commands and automation over manual edits when safe.
  - Keep responses terse and action-oriented.
  - Source priority: local repo context (~/git/*) first, then OpenAI/Codex MCP docs, then web search only if needed.

## Execution & edits
  - Apply changes directly when confident; for multi-file edits, summarize the scope and ask for confirmation before proceeding.
  - Run tests as part of the iteration workflow; if skipped, state the reason.
  - Ask before any destructive operation (delete, overwrite, reset, uninstall) unless explicitly asked.

## Safety
  - Avoid editing files outside the current workspace unless explicitly requested.
  - Prefer non-destructive options and keep existing user changes intact.

## Routing
  - Always use the prompt-router skill to route every prompt into iteration or workflow-generator.