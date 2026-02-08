# Workflow: dev.kit.ai.codex

workflow:
  id: dev.kit.ai.codex
  title: dev.kit AI Middleware Workflow (Codex)
  output_type: prompt
  bounded_work:
    max_steps_per_iteration: 7
    max_files_per_step: 5
    max_new_files_per_iteration: 4
    max_move_operations_per_step: 10
    extract_child_workflow_if_any_exceeded: true
  steps:
    - id: dev.kit.ai.codex.context
      title: Load Codex middleware context
      inputs:
        - docs/index.md
        - docs/execution/prompt-as-workflow.md
        - docs/execution/iteration-loop.md
        - docs/cde/output-contracts.md
        - docs/execution/workflow-io-schema.md
        - templates/prompts/ai/codex/index.md
      actions:
        - Read the listed docs and prompt to align with Codex exec usage.
      outputs:
        - Confirmed Codex-specific constraints and output type.
      status: planned
    - id: dev.kit.ai.codex.emit
      title: Emit Codex-friendly workflow or prompt
      inputs:
        - User request
      actions:
        - Produce prompt-as-workflow for multi-step work.
        - Otherwise emit a concise, bounded prompt.
      outputs:
        - Codex-ready prompt artifact.
      status: planned
