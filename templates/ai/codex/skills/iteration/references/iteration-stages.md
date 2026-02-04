# Iteration Stages

Default iteration stages for a single bounded execution:

1) Parse input/prompt
2) Validate intent and constraints
3) Execute bounded work (read/write/execute)
4) Process results
5) Run tests/validation (when applicable)
6) Prepare response (terse summary + next action)

Guidelines:
- Keep steps deterministic and bounded.
- Escalate to a workflow if the prompt exceeds bounds or spans distinct deliverables.
- Ask for confirmation before destructive actions.
