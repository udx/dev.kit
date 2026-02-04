# Prompt Routing Rules

Decision heuristics:

1) If the user says "iteration" or asks to "run iteration", route to iteration.
2) If the request implies multiple distinct deliverables or likely exceeds bounded-work limits, route to workflow generation.
3) If the request is a single, bounded task, run iteration stages.
4) If unclear, ask one clarifying question and propose the likely route.

Examples:
- "iteration" -> iteration stages
- "generate wordpress cloud native app" -> workflow generation
- "update README wording" -> iteration stages

After generating a root workflow, pause for user preview/approval before any child workflow work.
