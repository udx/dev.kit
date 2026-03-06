---
name: dev-kit-experience-capture
description: MANDATORY skill for distilling and packaging session engineering experience into reusable assets. Use this skill at the end of EVERY task to capture patterns, create new skills, or update agent memories. Ensures the repository "gets smarter" with every commit.
---

## Objective
Convert ephemeral developer session experience into persistent "Power" for the repository and the dev.kit ecosystem.

## CLI Usage Example
```bash
# Capture learnings from a bugfix task
dev.kit skills run "Capture experience for task FIX-123: Found race condition in sync script. Target: knowledge."

# Create a new automated skill based on a manual process
dev.kit skills run "Capture skill for task FEAT-456: New validation logic. Create 'dev-kit-validate-schema' skill."

# Update agent memories with a new project preference
dev.kit skills run "Capture memory for task CFG-789: Use tabs instead of spaces in this repo."
```

## Success-First UX Contract
- **Incremental Learning**: Automatically suggest capturing experience when a task is marked `done`.
- **Three-Tier Packaging**:
    1. **Knowledge**: Patterns/Docs (`docs/reference/foundations/knowledge.md`).
    2. **Skills**: Automated logic (`src/ai/data/skills/`).
    3. **Memory**: Agent-specific context (`src/ai/integrations/gemini/templates/GEMINI.md.tmpl`).
- **Resilient Sync**: Ensure captured experience is immediately available via `dev.kit agent gemini`.

## Input Contract
Required:
- `task_id`: The ID of the task being captured.
- `learnings`: A concise summary of the engineering patterns or fixes discovered.

Optional:
- `target`: `skill|knowledge|memory` (default: `knowledge`).

## Workflow
1. Identify the key engineering takeaway from the session.
2. Choose the appropriate packaging tier (Knowledge, Skill, or Memory).
3. Execute the corresponding steps in `src/ai/data/skill-packs/dev-kit-experience-capture/workflow.yaml`.
4. Run `dev.kit agent gemini` to hydrate the agent with the new power.

---
_UDX DevSecOps Team_
