---
name: best-practices-consumer
description: Scan a repo and normalize best practices into best_practices/*.md (snapshot-style). Use when the user asks to generate, update, or summarize best practices from a repo.
---

# Best Practices Consumer

Purpose: Scan the repo and produce normalized best-practices docs that are reusable by others.

## Required outputs (always create, even if empty)
- `best_practices/README.md`
- `best_practices/10_principles.md`
- `best_practices/20_delivery.md`
- `best_practices/30_governance.md`
- `best_practices/90_evidence.md`

## Core rules
- Confirm repo root (use provided environment context).
- Perform a full scan of the repo (key docs, configs, workflows, examples).
- Normalize to reusable best practices grouped into logical docs (not one file per aspect).
- Use snapshot mode: overwrite the current `best_practices/*.md` files each run.
- Do not invent practices; every claim must be traceable to repo evidence.

## Modular workflow
Use these lightweight stages to keep the process predictable:

1) Analyze
   - Confirm repo root and scan evidence sources (README, docs/, .github/workflows, examples/, configs).
   - Produce an evidence map (list of files + what they show).

2) Plan
   - Draft a short outline for each output doc.
   - If the user requests review, present the plan before writing files.

3) Apply
   - Create/overwrite required files using `assets/` templates.
   - Populate each doc with normalized practices + evidence pointers.

4) Report
   - Summarize what changed and list affected files.

## Assets
- `assets/readme.md`
- `assets/10_principles.md`
- `assets/20_delivery.md`
- `assets/30_governance.md`
- `assets/90_evidence.md`

## Optional reference
- `references/taxonomy.md` (use only if you need categories)
