# Workflow: dev.kit.ai

workflow:
  id: dev.kit.ai
  title: dev.kit AI Middleware Workflow
  output_type: prompt
  bounded_work:
    max_steps_per_iteration: 7
    max_files_per_step: 5
    max_new_files_per_iteration: 4
    max_move_operations_per_step: 10
    extract_child_workflow_if_any_exceeded: true
  steps:
    - id: dev.kit.ai.context
      title: Load AI middleware context
      inputs:
        - docs/index.md
        - docs/execution/prompt-as-workflow.md
        - docs/execution/iteration-loop.md
        - docs/cde/output-contracts.md
        - docs/execution/workflow-io-schema.md
        - src/prompts/dev.kit.ai.md
      actions:
        - Read the listed docs and prompt to align output type and bounds.
      outputs:
        - Confirmed middleware constraints and required artifacts.
      status: planned
    - id: dev.kit.ai.plan
      title: Decide on workflow vs direct prompt
      inputs:
        - User request
      actions:
        - If multi-step or cross-file, emit a workflow artifact.
        - Otherwise, emit a single bounded prompt response.
      outputs:
        - Prompt-as-workflow or bounded prompt response.
      status: planned
