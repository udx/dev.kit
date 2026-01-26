# Workflow — Codex Repo Skills (Repository Scope)

This workflow installs Codex skills into repo scope under `.codex/skills`.
Repo skills override user skills with the same name.
Use repo scope when skills should travel with the codebase.

Extraction Gate:
- See the Extraction Gate section in the prompt-as-workflow approach.

---

Step 0 — Locate repo root

done: false

codex exec "
Task: Identify the repository root for repo-scoped skills.
Input:
- Current working directory
Logic/Tooling:
- Try `git rev-parse --show-toplevel`; if it fails, notify the user and ask them to confirm the intended project root
  - Example prompt: \"Git repo not detected. Please confirm the intended project root path to use for .codex/skills.\"
Expected output/result:
- Repo root path
"

---

Step 1 — Install skill to repo scope

done: false

codex exec "
Task: Install a skill into repo scope.
Input:
- Skill source dir
- Skill name
Logic/Tooling:
- Install the skill using `scripts/install-codex-skill.sh <skill-src> <skill-name> <repo-root>/.codex/skills`
- Verify SKILL.md exists
Expected output/result:
- Skill installed in repo scope
"

---

Step 2 — Restart Codex

done: false

codex exec "
Task: Restart Codex to load repo-scoped skills.
Input:
- Codex CLI session
Logic/Tooling:
- Restart Codex (quit/relaunch)
Expected output/result:
- Codex recognizes repo-scoped skills
"

---
