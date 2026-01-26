# Workflow — Codex Rules (Minimal)

This workflow minimizes Codex rules into a compact, enforceable Starlark set.
It treats docs as the source of truth and keeps rules only for guardrails.

Extraction Gate:
- See the Extraction Gate section in the prompt-as-workflow approach.

---

Step 0 — Inventory current rules
done: false

codex exec "
Task: Capture current rules footprint and backup.
Input:
- ~/.codex/rules/default.rules
Logic/Tooling:
- wc -l, head, and a copy to a timestamped backup file
Expected output/result:
- Snapshot of rules size and a backup file path
"

---

Step 1 — Split keep vs. move
done: false

codex exec "
Task: Separate enforceable guardrails from narrative guidance.
Input:
- ~/.codex/rules/default.rules
- dev.kit AI principles (no recursion, plan-first, confirmations)
Logic/Tooling:
- Identify prefix_rule / exact rule entries that enforce behavior
- Mark long guidance blocks for migration to docs
- Ensure workflow generation guidance is moved to the workflow-generator skill
Expected output/result:
- Two lists: keep-as-rules, move-to-docs
"

---

Step 2 — Draft minimal rules
done: false

codex exec "
Task: Draft a compact Starlark rules template.
Input:
- Keep-as-rules list
- Codex rules format docs
Logic/Tooling:
- Keep only executable rules + minimal comments
- Avoid embedding large doc excerpts
- Add a short rule comment that workflow generation must follow the workflow-generator skill
Expected output/result:
- Minimal rules template ready for build/apply
"

---

Step 3 — Build and validate
done: false

codex exec "
Task: Validate the minimal rules.
Input:
- Minimal rules template
Logic/Tooling:
- codex execpolicy check <rules-file>
Expected output/result:
- Confirmation that rules pass execpolicy validation
"

---

Step 4 — Apply or rollback
done: false

codex exec "
Task: Apply the minimal rules or rollback if validation fails.
Input:
- Validated rules template
- Backup from Step 0
Logic/Tooling:
- Copy minimal rules into ~/.codex/rules/default.rules
- If errors arise, restore from backup
  - Example prompt: "Ready to apply minimal rules. Proceed? (yes/no)"
Expected output/result:
- Rules applied or safely rolled back
"

---
