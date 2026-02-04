---
name: dev-learn-summary
description: Manually triggered skill to generate or extend a repo-local learn/ directory with best practices, work item patterns, and templates based on the current session.
metadata:
  short-description: Generate repo learn/ context
---

# dev-learn-summary

Use this skill only when the user explicitly asks to generate or update a repo-local `src/learn/<repo>/` directory.

## Goal
Create or extend `src/learn/<repo>/` with a consistent set of files that capture what was learned in the current session.

## Required outputs (always create, even if empty)
- `src/learn/<repo>/README.md`
- `src/learn/<repo>/best-practices.md`
- `src/learn/<repo>/work-items.md`
- `src/learn/<repo>/templates.md`

If any file exists, **merge/extend** instead of overwriting.

## Merge/extend rules
- Never delete existing content.
- Append a new dated section at the end:
  - `## YYYY-MM-DD` (use local date of the user)
- Keep additions concise and scoped to the current session.
- Merge incrementally: preserve prior notes and add only new, session-specific knowledge.
- If no new content for a file, add the dated header and a single line: `No new notes.`
- Preserve file formatting and headings.

## Content guidelines
- Prefer short bullets and concrete steps.
- Only include information derived from the current work session.
- Do not add speculative or generic advice.

## Templates
Use the templates in `assets/` as initial scaffolding when files are missing.

## Execution steps
1) Confirm the repo root (use provided environment context).
2) Ensure `src/learn/<repo>/` exists (use the repo name from the root directory).
3) For each required file:
   - If missing: create from the corresponding asset template.
   - Append a dated section with session-specific notes.
4) Summarize what was added.

## Assets
- `assets/learn-readme.md`
- `assets/learn-best-practices.md`
- `assets/learn-work-items.md`
- `assets/learn-templates.md`
