# Workflow: dev.kit.ai.claude

workflow:
  id: dev.kit.ai.claude
  title: dev.kit AI Middleware Workflow (Claude)
  output_type: prompt
  bounded_work:
    max_steps_per_iteration: 7
    max_files_per_step: 5
    max_new_files_per_iteration: 4
    max_move_operations_per_step: 10
    extract_child_workflow_if_any_exceeded: true
  steps:
    - id: dev.kit.ai.claude.context
      title: Load Claude middleware context
      inputs:
        - docs/index.md
        - docs/execution/prompt-as-workflow.md
        - docs/execution/iteration-loop.md
        - docs/cde/output-contracts.md
        - docs/execution/workflow-io-schema.md
        - src/prompts/ai/claude/index.md
      actions:
        - Read the listed docs and prompt to align with Claude output needs.
      outputs:
        - Confirmed Claude-specific constraints and output type.
      status: planned
    - id: dev.kit.ai.claude.emit
      title: Emit Claude-friendly workflow or prompt
      inputs:
        - User request
      actions:
        - Produce prompt-as-workflow for multi-step work.
        - Otherwise emit a concise, bounded prompt.
      outputs:
        - Claude-ready prompt artifact.
      status: planned
