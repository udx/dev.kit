---
name: dev-kit-experience-capture
description: MANDATORY skill for packaging development experience into reusable repository assets. Use this skill at the end of every task or iteration to capture learnings, patterns, and new skills.
---

## Objective
Convert ephemeral session experience into persistent "Power" for the repository and future projects.

## Success-First UX Contract
- **Incremental Learning**: Automatically suggest capturing experience when a task is marked `done`.
- **Three-Tier Packaging**:
    1. **Knowledge**: Patterns/Docs (`docs/reference/foundations/knowledge.md`).
    2. **Skills**: Automated logic (`src/ai/data/skills/`).
    3. **Memory**: Agent-specific context (`src/ai/integrations/gemini/templates/GEMINI.md.tmpl`).
- **Resilient Sync**: Ensure captured experience is immediately available to the agent via `dev.kit agent gemini`.

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
