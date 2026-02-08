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
- `knowledge.legacy_learn_dir` (default: `src/learn/<repo>/` if required)

## Logic

1) Analyze
- Confirm repo root and scan evidence sources (README, docs/, workflows, configs).
- Build an evidence map (file list + what they show).

2) Plan
- Draft a short outline for each output.
- If the user requests review, present the plan before writing files.

3) Apply
- Snapshot mode: overwrite `best_practices/*.md` using assets.
- Session mode: append a dated section to `docs/knowledge.md`.
- Legacy fallback: append to `src/learn/<repo>/` only when required.

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
- `src/learn/<repo>/...` (legacy fallback, append dated section)

Format:
- Markdown
- Dated section headers: `## YYYY-MM-DD`

## Docs

Assets:
- `templates/ai/codex/skills/best-practices-consumer/docs/assets/*`
- `templates/ai/codex/skills/dev-learn-summary/docs/assets/*`
