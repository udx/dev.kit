# Workflow — Codex Configuration (Minimal)

This workflow defines a minimal, stable Codex CLI configuration for dev.kit usage.
Each step is executable via `codex exec` and is plan-first.

Extraction Gate:
- See the Extraction Gate section in the prompt-as-workflow approach.

---

Step 0 — Inventory current Codex state
done: false

codex exec "
Task: Capture the current Codex config, rules, and skills.
Input:
- ~/.codex/config.toml
- ~/.codex/rules/default.rules
- ~/.codex/skills/
Logic/Tooling:
- ls, cat/head, wc -l
- Codex CLI does not support `--list-skills`; verify skills by filesystem inventory
- Optional: use `codex app-server` + `skills/list` only if app-server is running
- Do not edit; read-only inventory
Expected output/result:
- Minimal snapshot of config entries, rules size, and installed skills
"

---

Step 1 — Define minimal config surface
done: false

codex exec "
Task: Propose minimal config entries for dev.kit usage.
Input:
- Current ~/.codex/config.toml
- Required MCP servers (Context7, openaiDeveloperDocs)
Logic/Tooling:
- Keep only project_root_markers + trusted roots + required MCP servers
- Remove unused or redundant entries
Expected output/result:
- Minimal config snippet with short rationale per entry
"

---

Step 2 — Apply minimal config safely
done: false

codex exec "
Task: Apply the minimal config with a backup-first approach.
Input:
- Proposed config snippet
- ~/.codex/config.toml
Logic/Tooling:
- Create a timestamped backup of config.toml
- Replace config.toml with the minimal snippet
  - Example prompt: "Apply the minimal Codex config now? (yes/no)"
Expected output/result:
- Updated config.toml and a backup file path
"

---

Step 3 — Install workflow-generator skill
done: false

codex exec "
Task: Install the workflow-generator skill for consistent workflow outputs.
Input:
- skills/workflow-generator/
- ~/.codex/skills/
Logic/Tooling:
- If ~/.codex/skills is missing, create it; otherwise log it exists
- Install the skill using `scripts/install-codex-skill.sh skills/workflow-generator workflow-generator \"$HOME/.codex/skills\"`
- Verify SKILL.md frontmatter and references exist
- If the install must run outside sandbox, paste the full output into `assets/fixtures/logs.txt`
Expected output/result:
- Skill installed and ready for use
"

---

Step 3a — Restart Codex (required for new skills)
done: false

codex exec "
Task: Restart Codex to load newly installed skills.
Input:
- Codex CLI session
Logic/Tooling:
- Restart Codex (quit/relaunch) after skill install
- If performed outside sandbox, paste the full output or confirmation into `assets/fixtures/logs.txt`
Expected output/result:
- Codex recognizes the new skill
"

---

Step 4 — Codex rules workflow
done: false

codex exec "
Task: Run the Codex rules minimization workflow.
Input:
- workflows/codex-config/codex-rules-minimal/index.md
Logic/Tooling:
- Follow the referenced workflow steps in order
Expected output/result:
- Minimal rules plan and validated rules file
"

---

Step 5 — Validation plan
done: false

codex exec "
Task: Define overall validation steps and rollback path.
Input:
- Updated config.toml
- Minimal rules plan (from workflow)
Logic/Tooling:
- Use codex execpolicy check for rules
- Define config and rules backup/restore steps
Expected output/result:
- Validation checklist and safe rollback instructions
"

---

Step 6 — Repo-scoped skills workflow
done: false

codex exec "
Task: Run the repo-scoped skills workflow to support per-repo skills.
Input:
- workflows/codex-config/repo-skills/index.md
Logic/Tooling:
- Follow the referenced workflow steps in order
Expected output/result:
- Repo-scoped skills enabled and ready
"

---
