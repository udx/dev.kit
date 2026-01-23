# Workflows

Purpose
- Define workflow steps for modules and integrations.
- Steps can be commands, prompts, or validations.

Step Types
- command: a shell command or dev.kit command to run.
- prompt: a user prompt or AI prompt to generate output.
- validate: a check or assertion that confirms results.
- note: documentation-only guidance.

CLI Smoke Test (dev.kit)
```
bin/scripts/test-cli.sh
```

Structure (Template)
```
workflow:
  id: <module>.<name>
  title: <human title>
  steps:
    - type: command
      value: <command string>
    - type: prompt
      value: <prompt string>
    - type: validate
      value: <expected outcome or check>
```

Notes
- Keep workflows minimal and composable.
- Require confirmation for destructive steps.
