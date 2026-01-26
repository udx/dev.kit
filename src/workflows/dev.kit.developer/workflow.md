# Workflow: dev.kit.developer

workflow:
  id: dev.kit.developer
  title: dev.kit Developer Workflow
  output_type: markdown
  bounded_work:
    max_steps_per_iteration: 7
    max_files_per_step: 5
    max_new_files_per_iteration: 4
    max_move_operations_per_step: 10
    extract_child_workflow_if_any_exceeded: true
  steps:
    - id: dev.kit.developer.context
      title: Load developer context and constraints
      inputs:
        - docs/index.md
        - docs/execution/iteration-loop.md
        - docs/execution/prompt-as-workflow.md
        - docs/cde/output-contracts.md
        - docs/execution/workflow-io-schema.md
        - src/prompts/dev.kit.developer.md
      actions:
        - Read the listed docs and prompt to establish scope and guardrails.
      outputs:
        - Confirmed scope, constraints, and role alignment for dev.kit work.
      status: planned
    - id: dev.kit.developer.plan
      title: Produce a bounded plan or workflow
      inputs:
        - User request
        - Repo files referenced in context
      actions:
        - Decide whether a workflow is required based on scope.
        - If required, emit a prompt-as-workflow artifact.
      outputs:
        - Short plan or workflow artifact aligned to DOC-002/DOC-003.
      status: planned
