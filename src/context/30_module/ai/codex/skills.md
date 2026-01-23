# Codex Skills

Purpose
- Define Codex skill selection and formatting rules for dev.kit.

Format
- Codex skill files must follow the SKILL.md format:

```md
---
name: <skill-name>
description: <what it does and when to use it>
---

<instructions, references, or examples>
```

Sources
- Common skills: `src/context/30_module/ai/skills/`
- Codex selection and packaging: this file

Output
- `public/modules/ai/codex/skills.md`

Example
```md
---
name: devkit-install-cleanup
description: Install, configure, validate, uninstall, and clean up dev.kit on the host.
---

# dev.kit Install & Cleanup

Use this skill when you need to install dev.kit, perform initial configuration, validate the setup, or uninstall and clean up a host environment.
```
