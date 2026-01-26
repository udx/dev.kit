# Workflow — Iteration Loop (Deepest Step)

This workflow defines a standard iteration loop for development tasks.
Each step is executable via `codex exec` and is plan-first.

Extraction Gate:
- See the Extraction Gate section in the prompt-as-workflow approach.

---

Step 0 — Show current state
done: false

codex exec "
Task: Capture current state before changes.
Input:
- Repo root
Logic/Tooling:
- ls, git status, and any relevant context summaries
Expected output/result:
- Short snapshot of current state
"

---

Step 1 — Ensure config/context/manifests
done: false

codex exec "
Task: Ensure required config, context, and manifest files are present.
Input:
- Target workflow scope
Logic/Tooling:
- Verify required files exist (context docs, configs, schemas)
- Note any missing inputs
Expected output/result:
- Confirmed prerequisites or a list of missing items
"

---

Step 2 — Plan
done: false

codex exec "
Task: Produce a minimal plan for the change.
Input:
- Task request
- Current state snapshot
Logic/Tooling:
- Break work into smallest logical steps
Expected output/result:
- Plan with ordered steps
"

---

Step 3 — Gate
done: false

codex exec "
Task: Apply gates before execution.
Input:
- Plan
- Applicable policies or guardrails
Logic/Tooling:
- Check for destructive or risky steps
- Require confirmation if needed
  - Example prompt: "This step is gated (risk/destructive). Do you want me to proceed? (yes/no)"
Expected output/result:
- Approval to proceed or a stop/confirm requirement
"

---

Step 4 — Confirm (optional)
done: false

codex exec "
Task: Ask for confirmation before executing gated steps.
Input:
- Gate outcome
Logic/Tooling:
- Ask user to confirm or adjust scope
  - Example prompt: "Please confirm to proceed with the gated steps, or describe changes you want."
Expected output/result:
- Explicit confirmation or revised plan
"

---

Step 5 — Execute
done: false

codex exec "
Task: Execute the approved steps.
Input:
- Approved plan
Logic/Tooling:
- Apply changes carefully and incrementally
Expected output/result:
- Changes applied
"

---

Step 6 — Post-execution verify/tests
done: false

codex exec "
Task: Verify outcomes and run tests if applicable.
Input:
- Changed files or executed commands
Logic/Tooling:
- Run relevant checks/tests
- Capture outputs
Expected output/result:
- Verification results
"

---

Step 7 — Notify
done: false

codex exec "
Task: Summarize results and notify the user.
Input:
- Verification results
Logic/Tooling:
- Provide concise outcome summary
Expected output/result:
- User informed of results and next steps
"

---

Step 8 — Review
done: false

codex exec "
Task: Review the work for gaps or follow-ups.
Input:
- Summary and verification results
Logic/Tooling:
- Identify missing tests, risks, or cleanup tasks
Expected output/result:
- Follow-up checklist
"

---
