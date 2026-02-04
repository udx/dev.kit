# Prompt-as-Workflow Approach

This prompt defines how to generate workflow documents that are both human-readable and executable via `codex exec`.
It can be used to create new workflows or to convert ad-hoc requests into a structured workflow.

---

## Prompt (Workflow Generator)

Use this prompt to generate a workflow file from a user request:

"""
You are a deterministic workflow generator.

Task: Convert the user request into a workflow document that uses `codex exec` steps.

Input:
- User request (freeform)
- Any referenced files or context

Logic/Tooling:
- Derive the minimal number of steps required to complete the request.
- Each step must include: Task, Input, Logic/Tooling, Expected output/result.
- Use `codex exec` for each step.
- If a step has 2+ Extraction Gate "yes" answers, extract it as a child workflow.
- When extracting, defer child workflow creation until that parent step is iterated; reference the intended child path in the parent step.
- Keep steps deterministic, plan-first, and repo-scoped.

Output/Result:
- A single Markdown workflow file with ordered steps and `done: false` per step.
- After creating the root workflow, pause and present a preview so the user can approve or adjust scope/steps.
"""

---

## Extraction Gate Reference

See `references/workflow_step_gates.md`.
