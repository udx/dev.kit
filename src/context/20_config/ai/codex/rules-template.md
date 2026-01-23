# ~/.codex/rules/default.rules
# Execpolicy rules for Codex CLI (Starlark).
# Docs: https://developers.openai.com/codex/rules
#
# dev.kit Rules (Codex CLI)
#
# Core behavior
# - Do not call `dev.kit -p` from Codex CLI to avoid loops.
# - If dev.kit output is already provided, use it as the source of truth.
# - Prefer dev.kit refs/docs over generic advice.
# - For known workflows, prefer dev.kit commands after user confirmation when the user is already in dev.kit.
#
# Safety
# - Require previews for apply/push/destructive steps.
# - Keep changes small and reversible.
# - Never auto-move secrets; only suggest secure storage options.
# - Do not call `dev.kit -p` from Codex CLI to prevent loops.
#
# Prompting guidance
# - Follow Codex prompting guidance for tool use and concise responses.
# - Use capture logs for iteration: ask the user to run `dev.kit capture show` and review before cleaning.
# - For AI iterations, check for doc updates with `dev.kit docs changelog --show` and inform the user if changes affect the current context.
# - If an iteration runs longer than ~10 minutes, pause and confirm direction; for long sessions, check in at least every ~10 minutes and re-confirm after each major phase (aim for at least 3 check-ins).
# - When context seems low (around half or less remaining) or quality risks rise, proactively suggest `/compact`, or propose a summary/experience doc and starting a fresh session with that context.
# - On ~10-minute cadence (or every ~10 turns), ask the user to run `/status`; if context <50%, recommend `/compact`, `/fork`, or a fresh session with a summary.
# - If dev.kit provides a wall-clock helper, prefer that signal for cadence checks.
# - When manual cleanup is needed, advise cleanup management steps or available commands; if dev.kit tooling exists, prefer those commands over ad-hoc cleanup.
# - Use `codex execpolicy check` as a lightweight validation/test step for rule changes when applicable.
# - Use the incremental experience methodology:
#   - Build iteratively while preserving learnings from every success or failure.
#   - Store experience context separately from active sources.
#   - Use experience as guidance, not as a hard dependency.
# - Use deterministic artifact generation for Markdown-to-artifact prompts:
#   - Context is authoritative; missing context yields missing output.
#   - Act as a compiler; do not invent content or best practices.
#   - Preserve ordering and literals for round-trip safety.
#
# Refs
# - Codex config: https://developers.openai.com/codex/config-reference
# - Codex config sample: https://developers.openai.com/codex/config-sample
# - Codex rules: https://developers.openai.com/codex/rules

# -------------------------------------------------------------------
# Prevent dev.kit pipeline loops / self-triggering automation
# -------------------------------------------------------------------
prefix_rule(
    pattern = ["dev.kit", "-p"],
    decision = "forbidden",
    justification = "Avoid dev.kit pipeline loops. Run dev.kit without -p and review output first.",
    match = [
        "dev.kit -p",
        "dev.kit -p build",
        "dev.kit -p deploy --env prod",
    ],
    not_match = [
        "dev.kit",
        "dev.kit capture show",
        "dev.kit help",
    ],
)

# If you also use the long flag, keep this (remove if not applicable).
prefix_rule(
    pattern = ["dev.kit", "--pipeline"],
    decision = "forbidden",
    justification = "Avoid dev.kit pipeline loops. Run dev.kit without --pipeline and review output first.",
    match = [
        "dev.kit --pipeline build",
    ],
)
