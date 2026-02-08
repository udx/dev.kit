# Iteration Loop

Domain: Execution

## Purpose

Define the review → workflow → apply → validate → log iteration cycle as a
repo-native contract. This loop aligns reasoning systems and the CLI runtime
on shared artifacts without granting execution authority to agents.

## Cycle

review
→ workflow (plan)
→ apply
→ validate
→ log

## Artifacts

- Review input: `docs/_tree.txt` (generated, optional)
- Review output: `docs/_feedback.md`
- Workflow (active): `~/.udx/dev.kit/state/codex/workflows/<repo-id>/<task-id>/workflow.md`
- Workflow (reference): `src/`
- Helper scripts: `scripts/apply-task.sh`
- Subtask loop: `docs/execution/subtask-loop.md` (task-specific prompt/feedback)
- Skill contract: `src/ai/integrations/codex/skills/iteration/SKILL.md`

## See Also

- Spec kernel entrypoint: `docs/index.md`
- Repo overview: `README.md`
- Iteration skill contract: `src/ai/integrations/codex/skills/iteration/SKILL.md`

## Boundaries

- Reasoning systems and adapters produce artifacts only.
- The CLI runtime is the execution boundary.
- Workflows describe intended changes; they do not apply them.
- Validation is explicit and recorded in the workflow or feedback log.

## Resolution Rules

- A review task is resolved when workflow steps are complete and the resolution log
  in `docs/_feedback.md` is updated.
- A subtask is resolved when `tasks/<task-id>/feedback.md` is marked complete.
- Resolution entries must include task ID, affected file paths, and a summary.

## Guardrails

- No hidden side effects. All changes must be declared in artifacts.
- No implicit execution. Apply steps require explicit instruction.
