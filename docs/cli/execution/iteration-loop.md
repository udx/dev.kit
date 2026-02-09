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
- Review output: `tasks/<task-id>/feedback.md`
- Workflow (active): `~/.udx/dev.kit/state/codex/workflows/<repo-id>/<task-id>/workflow.md`
- Workflow (reference): `src/`
- Helper scripts: `scripts/apply-task.sh`
- Subtask loop: `docs/cli/execution/subtask-loop.md` (task-specific prompt/feedback)
- Skill contract: `src/ai/data/skills/dev-kit-iteration.json`

## Session Continuity

Keep workflow state continuous across turns (interactive Codex or `codex exec`).

Required continuity signals:
- Carry forward the latest workflow file content and step `status` values.
- Include the active workflow path in each response when work continues.
- If a response pauses for user input, list the open questions explicitly.
- When resuming, restate the active step ID and update its status.

Recommended continuation packet:
- Workflow path (`~/.udx/dev.kit/state/codex/workflows/<repo-id>/<task-id>/workflow.md`)
- Current step ID + status
- Open questions or missing inputs
- Next action (requested from user or to be executed by CLI)

## See Also

- Spec kernel entrypoint: `docs/README.md`
- Repo overview: `README.md`
- Iteration skill contract: `src/ai/data/skills/dev-kit-iteration.json`

## Boundaries

- Reasoning systems and adapters produce artifacts only.
- The CLI runtime is the execution boundary.
- Workflows describe intended changes; they do not apply them.
- Validation is explicit and recorded in the workflow or feedback log.

## Resolution Rules

- A review task is resolved when workflow steps are complete and the task feedback
  in `tasks/<task-id>/feedback.md` is updated.
- A subtask is resolved when `tasks/<task-id>/feedback.md` is marked complete.
- Resolution entries must include task ID, affected file paths, and a summary.

## Guardrails

- No hidden side effects. All changes must be declared in artifacts.
- No implicit execution. Apply steps require explicit instruction.
