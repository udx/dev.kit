---
name: knowledge-curator
description: Capture repo best practices (snapshot) and/or session learnings into a knowledgebase. Use when the user asks for best practices, learn summaries, or knowledgebase updates.
---

# Knowledge Curator

Purpose: Produce a reusable best-practices snapshot and/or capture session learnings in a knowledgebase.

## Config

Inputs are derived from the repo and environment when not provided explicitly.

- `knowledge.snapshot` (default: false)
- `knowledge.session` (default: true when user requests learnings)
- `knowledge.best_practices_dir` (default: `best_practices/`)
- `knowledge.knowledge_file` (default: `docs/knowledge.md` if present)

## Logic

1) Analyze
- Confirm repo root and scan evidence sources (README, docs/, prompts, configs).
- Build an evidence map (file list + what they show).

2) Plan
- Draft a short outline for each output.
- If the user requests review, present the plan before writing files.

3) Apply
- Snapshot mode: overwrite `best_practices/*.md` using assets.
- Session mode: append a dated section to `docs/knowledge.md`.

4) Report
- Summarize changes and list affected files.

## Schema

Inputs:
- repo root
- user request
- evidence sources

Outputs (based on mode):
- `best_practices/*.md` (snapshot, overwrite)
- `docs/knowledge.md` (append dated section)

Format:
- Markdown
- Dated section headers: `## YYYY-MM-DD`

## Docs

Assets:
- (none; use repo-local guidance when present)
