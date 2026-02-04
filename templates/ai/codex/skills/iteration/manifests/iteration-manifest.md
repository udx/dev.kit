# Iteration Manifest

output_type: prompt
bounded_work:
  max_steps_per_iteration: 6
  max_files_per_step: 8
  max_new_files_per_iteration: 3
  max_move_operations_per_step: 0
  extract_child_workflow_if_any_exceeded: true
stages:
  - parse
  - validate
  - execute
  - process
  - test
  - respond
done: false
