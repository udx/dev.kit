# Workflow: dev.kit

workflow:
  id: dev.kit
  title: dev.kit Non-AI Workflow
  output_type: markdown
  bounded_work:
    max_steps_per_iteration: 7
    max_files_per_step: 5
    max_new_files_per_iteration: 4
    max_move_operations_per_step: 10
    extract_child_workflow_if_any_exceeded: true
  steps:
    - id: dev.kit.context
      title: Load repo context for local guidance
      inputs:
        - docs/index.md
        - docs/execution/iteration-loop.md
        - docs/execution/cli-primitives.md
        - src/prompts/dev.kit.md
      actions:
        - Read the listed docs and prompt to align local-only guidance.
      outputs:
        - Clear local command or doc references for the request.
      status: planned
    - id: dev.kit.response
      title: Respond with deterministic guidance
      inputs:
        - User request
        - Repo docs or scripts
      actions:
        - Provide the exact command or doc path needed.
        - Ask one clarifying question if required.
      outputs:
        - Short, actionable guidance without AI execution.
      status: planned
