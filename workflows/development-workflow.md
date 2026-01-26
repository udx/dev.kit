# dev.kit — Initial Workflow (CDE-aligned)

This workflow defines deterministic steps for initializing dev.kit,
its context layer, and Codex integration.

Each step is executable via `codex exec`.
Execution is plan-first; steps may be marked done manually or by tooling.

---

Step 0 — Codex configuration workflow
done: false

codex exec "
Task: Run the Codex configuration workflow before any other steps.
Input:
- workflows/codex-config/index.md
Logic/Tooling:
- Follow the referenced workflow steps in order.
Expected output/result:
- Minimal Codex config and rules plan ready for use in this repo.
"

---

Step 1 — Define execution contract
done: false

codex exec "
Task: Establish execution contract and guardrails for this workflow.
Input: Repository root.
Logic/Tooling:
- Identify repo root and allowed directories.
- Define allowed CLI tools (ls, rg, cat, jq/python json, git).
- Define forbidden actions (network, deletes, recursive AI calls).
Expected output/result:
- Clear understanding of scope, safety rules, and allowed operations.
"

---

Step 2 — Verify repository context
done: false

codex exec "
Task: Verify repository structure and context sources.
Input:
- README.md
- src/
- docs/ (if exists)
- public/ (if exists)
Logic/Tooling:
- Use ls and rg to inspect existing structure.
- Identify files that describe intent, rules, or schemas.
Expected output/result:
- Short list of context-relevant files and directories.
"

---

Step 3 — Define dev.kit context sources
done: false

codex exec "
Task: Define which repository assets form the dev.kit context layer.
Input:
- Markdown docs (guides, rules, README).
- Existing JSON/YAML schemas (if any).
Logic/Tooling:
- Map Markdown -> intent/rules.
- Map JSON/YAML -> schemas/config.
Expected output/result:
- A clear list of files that constitute the Active Context Layer.
"

---

Step 4 — Generate initial context schemas
done: false

codex exec "
Task: Generate initial context schemas from Markdown sources.
Input:
- Identified context Markdown files.
Logic/Tooling:
- Deterministic Markdown-to-JSON conversion.
- Follow embedded rules; do not invent fields.
Expected output/result:
- One or more JSON context/schema files reflecting repository intent.
"

---

Step 5 — Validate generated context
done: false

codex exec "
Task: Validate generated context JSON files.
Input:
- Generated JSON schema/context files.
Logic/Tooling:
- Run JSON parse validation.
- Check for missing or extra fields.
Expected output/result:
- Confirmation that all context files are valid and consistent.
"

---

Step 6 — Define dev.kit commands and responsibilities
done: false

codex exec "
Task: Define initial dev.kit command surface.
Input:
- dev.kit concept and goals.
Logic/Tooling:
- Identify core commands (doctor, config, prompt).
- Identify workflow commands (repo init, capture, parse/fetch).
Expected output/result:
- List of dev.kit commands with clear responsibilities.
"

---

Step 7 — Define Codex integration rules
done: false

codex exec "
Task: Define Codex usage rules for dev.kit.
Input:
- dev.kit prompt concept.
Logic/Tooling:
- Define how prompts are enriched with context.
- Define hard rules (no recursive dev.kit calls, plan-first).
Expected output/result:
- Clear Codex rules/constraints aligned with CDE.
"

---

Step 8 — Define Codex skills / agents (minimal)
done: false

codex exec "
Task: Define initial Codex skills or agent roles.
Input:
- dev.kit workflows.
Logic/Tooling:
- Identify repeatable skills (planning, validation, refactoring).
- Keep skills minimal and deterministic.
Expected output/result:
- Initial list of Codex skills/agents and their scope.
"

---

Step 9 — Cross-check workflow consistency
done: false

codex exec "
Task: Cross-check workflow steps against CDE principles.
Input:
- All previous steps and generated artifacts.
Logic/Tooling:
- Ensure layering: build -> 12-factor repo -> CDE.
- Ensure dev.kit remains executor, AI remains planner.
Expected output/result:
- Confirmation that workflow aligns with Context-Driven Engineering.
"

---

Step 10 — Summarize next implementation actions
done: false

codex exec "
Task: Summarize concrete next steps for implementation.
Input:
- Workflow results.
Logic/Tooling:
- Produce short actionable list (files to create, commands to implement).
Expected output/result:
- Clear implementation checklist for dev.kit CLI.
"

---
