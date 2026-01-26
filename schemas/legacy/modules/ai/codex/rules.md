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

# Overrides
#
# src/context/20_config/ai/codex/overrides.md
# Codex Rules Overrides
#
# Purpose
# - Extend or override the base rules template for Codex.
#
# Usage
# - Keep this file minimal and additive.
# - Overwrite only the sections that need changes.
#
# Incremental experience methodology
# - Build iteratively while preserving learnings from every success or failure.
# - Store experience context separately from active sources.
# - Use experience as guidance, not as a hard dependency.

# Sources

# src/context/30_module/ai/rules.md
# # AI Rules (Common)
# 
# Purpose
# - Define AI-agnostic behavior rules used by client-specific rule builds.
# - Keep common expectations in one place and avoid duplicating per-client rules.
# 
# Scope
# - Applies to CLI-based AI integrations (Codex, Claude, Gemini).
# - Client modules extend or override as needed.
# 
# Core Rules
# - Treat dev.kit output as the source of truth when provided.
# - Require confirmation before running any pipeline step.
# - Prefer dev.kit refs/docs over generic advice.
# - Keep changes small, reviewable, and reversible.
# - Avoid automation loops by refusing self-triggering commands.
# 
# Notes
# - Client modules should format and serialize these rules into their target formats.

# src/context/30_module/ai/codex/overview.md
# # AI Integration Overview
# 
# Behavior
# - Do not call `dev.kit -p` from Codex CLI to avoid loops.
# - If dev.kit output is already provided, treat it as the source of truth.
# - If `match=detected` and pipeline exists, require confirmation.
# 
# Data Sources (Fallback Order)
# - Local docs and module metadata.
# - UDX tooling repos via git/gh or cached clones.
# - Web retrieval (e.g., `@udx/mcurl`) when needed.
# 
# Rules vs Config
# - Rules define development standards and orchestration behavior.
# - Config defines permissions and enabled features for each environment.
# - Rules are versioned and templated; config is local and user-owned.
# 
# Codex Integration Inputs
# - Prompt runner: https://developers.openai.com/codex/noninteractive
# - Custom prompts: https://developers.openai.com/codex/custom-prompts
# - Skills: https://developers.openai.com/codex/skills
# 
# Related Docs
#  - Rules: `public/modules/ai/codex/rules.md`
# - Module metadata: `public/modules/codex.json`
# - Skills: `src/context/30_module/ai/codex/skills.md`
# - MCP servers: `src/context/30_module/ai/codex/mcp.md`
# - AI config: `src/context/20_config/ai/overview.md`

# src/context/20_config/standards/development-standards.md
# # Development Standards
# 
# Core Standards
# - Modularization of logic with reusable, isolated units and graceful fallbacks.
# - TDD: define expectations first and use tests to guide iteration.
# - Configs live outside the codebase and remain user-managed.
# 
# Implementation Notes
# - Prefer small, reviewable changes.
# - Keep tooling optional and detect capabilities before use.

# src/context/20_config/principles/development-tenets.md
# Based on:
# 
# - https://12factor.net
# - https://udx.io/devops-manual/12-factor-environment-automation
# - https://github.com/udx/cde
# 
# I always do:
# 
# - git status before I start new day coding 
# - push at least once a day, end of the day should be gate
# - develop design and logic for 1 asset at first and then make it re-usable and apply to other assets
# - iterate additions/changes in smallest steps possible ensuring feedback loop and improvements
# - TDD (test driven development) is core of logic design, define what is expected from development perspective and while iterate ensure validate against tests
# - use tooling that makes assets generation and execution usable and quick
# - deploy as much as possible to ensure consistency and impunity
# - convert working "sprint" into experience logs(markdown docs, manifests, tooling) to incrementally utilize, empower and productize
# - when building project features, design them as reusable tooling where possible and keep configuration outside of code (12-factor)
# - when an iteration runs longer than ~10 minutes, pause and ask for confirmation of direction; for long sessions, check in at least every ~10 minutes and after each major phase
# - when context feels low (around half or less remaining) or quality risks rise, suggest `/compact` or propose a summary/experience doc and a fresh session seeded with that context
# - when automate something, first rule is to make manually number of timess, then prepare automated tests and then develop and validate automation with CI integration
# - when you automate something, also automate graceful cleanup for everything created
# - which can run on production environment can be run on local environment
# - always do host-agnostic development with docker

# src/context/20_config/user-experience/cli-output.md
# # CLI Output (Text Mode)
# 
# Guidelines
# - Single header block with product name and status.
# - Compact sections: Status, Pipeline, Refs, Next Steps.
# - Minimal color use; readable without color.
# - Fixed markers for machine parsing, e.g. `[dev.kit] match=...`.
# - Consistent spacing to avoid noisy output.
# 
# Example
# ```
# -------------
#  @udx/dev.kit
# -------------
# 
# Status: detected (confidence 0.86)
# Pipeline:
#   1) worker-deployment config --type=bash --destination=deploy.yaml
#   2) worker-deployment run --config=deploy.yaml
# Refs:
#   - https://npmjs.com/worker-deployment
# 
# [dev.kit] match=detected; confidence=0.86; pipeline=2; next_steps=3; refs=1
# ```

# src/context/20_config/references/codex_prompting_guide.md
# Codex Prompting Guide (Extracted Notes)
# 
# Source
# - https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide/
# - Captured via `mcurl` for offline reference.
# 
# Purpose
# - Summarize prompt guidance relevant to dev.kit integration.
# - Keep rules short, actionable, and safe-by-default.
# 
# Key Highlights
# - Prefer a strong base prompt (Codex-Max style) and add tactical rules.
# - Avoid upfront plans/preambles that can interrupt long rollouts.
# - Emphasize tool usage and exploration over freeform text.
# - Encourage parallel tool calls when possible.
# - Optimize for correctness and safe behavior, not shortcuts.
# 
# Integration Notes for dev.kit
# - Always route user prompts through `dev.kit -p "<prompt>"`.
# - Use `dev.kit <command_id>` for explicit workflows after confirmation.
# - Require previews for apply/push/destructive actions.
# - Keep edits small and reversible; avoid silent failures.

# src/context/20_config/ai/codex/index.md
# # Codex AI config
# 
# Scope
# - Codex-specific rules and overrides for dev.kit integration.
# 
# Docs
# - `rules-template.md`: base rules template for Codex CLI.
# - `overrides.md`: optional overrides applied after the template.

# src/context/20_config/ai/codex/overrides.md
# # Codex Rules Overrides
# #
# # Purpose
# # - Extend or override the base rules template for Codex.
# #
# # Usage
# # - Keep this file minimal and additive.
# # - Overwrite only the sections that need changes.
# #
# # Incremental experience methodology
# # - Build iteratively while preserving learnings from every success or failure.
# # - Store experience context separately from active sources.
# # - Use experience as guidance, not as a hard dependency.

# src/context/20_config/ai/codex/rules-template.md
# # ~/.codex/rules/default.rules
# # Execpolicy rules for Codex CLI (Starlark).
# # Docs: https://developers.openai.com/codex/rules
# #
# # dev.kit Rules (Codex CLI)
# #
# # Core behavior
# # - Do not call `dev.kit -p` from Codex CLI to avoid loops.
# # - If dev.kit output is already provided, use it as the source of truth.
# # - Prefer dev.kit refs/docs over generic advice.
# # - For known workflows, prefer dev.kit commands after user confirmation when the user is already in dev.kit.
# #
# # Safety
# # - Require previews for apply/push/destructive steps.
# # - Keep changes small and reversible.
# # - Never auto-move secrets; only suggest secure storage options.
# # - Do not call `dev.kit -p` from Codex CLI to prevent loops.
# #
# # Prompting guidance
# # - Follow Codex prompting guidance for tool use and concise responses.
# # - Use capture logs for iteration: ask the user to run `dev.kit capture show` and review before cleaning.
# # - For AI iterations, check for doc updates with `dev.kit docs changelog --show` and inform the user if changes affect the current context.
# # - If an iteration runs longer than ~10 minutes, pause and confirm direction; for long sessions, check in at least every ~10 minutes and re-confirm after each major phase (aim for at least 3 check-ins).
# # - When context seems low (around half or less remaining) or quality risks rise, proactively suggest `/compact`, or propose a summary/experience doc and starting a fresh session with that context.
# # - On ~10-minute cadence (or every ~10 turns), ask the user to run `/status`; if context <50%, recommend `/compact`, `/fork`, or a fresh session with a summary.
# # - If dev.kit provides a wall-clock helper, prefer that signal for cadence checks.
# # - When manual cleanup is needed, advise cleanup management steps or available commands; if dev.kit tooling exists, prefer those commands over ad-hoc cleanup.
# # - Use `codex execpolicy check` as a lightweight validation/test step for rule changes when applicable.
# # - Use the incremental experience methodology:
# #   - Build iteratively while preserving learnings from every success or failure.
# #   - Store experience context separately from active sources.
# #   - Use experience as guidance, not as a hard dependency.
# # - Use deterministic artifact generation for Markdown-to-artifact prompts:
# #   - Context is authoritative; missing context yields missing output.
# #   - Act as a compiler; do not invent content or best practices.
# #   - Preserve ordering and literals for round-trip safety.
# #
# # Refs
# # - Codex config: https://developers.openai.com/codex/config-reference
# # - Codex config sample: https://developers.openai.com/codex/config-sample
# ... (truncated; 70 lines total)

# src/context/20_config/ai/index.md
# # AI Configs (Source)
# 
# This directory holds AI integration source docs.
# 
# Contents
# - `overview.md`: unified AI integration contract and behavior.
# - `codex/index.md`: Codex-specific rules and overrides index.
# - `codex/rules-template.md`: Codex rules template used for artifacts.
# - `codex/overrides.md`: optional overrides/extensions for Codex.
# - Add more AI-specific configs here as needed.

# src/context/20_config/ai/overview.md
# AI Integration (Iteration Draft)
# 
# Goal
# - Make dev.kit the primary middleware for AI CLI workflows.
# - Provide a stable, minimal contract for AI clients to follow.
# - Allow human-friendly output while supporting machine parsing when needed.
# 
# Scope
# - Applies to AI CLI integrations first (Codex CLI, Claude CLI, etc.).
# - IDE agent integration is deferred; requirements may diverge later.
# - This document is iterative and will evolve with the knowledge base design.
# 
# Core Contract
# - Pipeline: If dev.kit returns a command pipeline, AI asks for user confirmation, then calls `dev.kit <command_id>`.
# - Fallback: If dev.kit reports "not detected", AI provides general advice after showing dev.kit output.
# - Priority: dev.kit output and references take precedence over general advice.
# 
# CLI Interface (v0)
# - `dev.kit -p "<prompt>" [--format=text|json]`
# - `dev.kit <command_id> [--format=text|json]`
#  - Optional: `dev.kit <command_id> --step <n>` for stepwise confirmation.
# 
# JSON Response Envelope (v0)
# ```json
# {
#   "meta": {
#     "version": "0.1",
#     "request_id": "uuid",
#     "mode": "human|ai",
#     "input": "original prompt",
#     "match": "detected|not_detected",
#     "confidence": 0.0
#   },
#   "summary": "1-2 line quick answer",
#   "pipeline": [
#     {
#       "id": "worker-deployment.config",
#       "title": "Generate deployment config",
#       "command": "worker-deployment config --type=bash --destination=deploy.yaml",
#       "requires_confirmation": true,
# ... (truncated; 93 lines total)

# src/context/index.md
# # CDE context system
# 
# The CDE context system is the handler and dispatcher for structured context in dev.kit. It uses integrated metadata, supports unlimited nested levels, and treats CDE-compliant context documents as configuration sources for different output types.
# 
# <details>
# <summary>Prompt(Context schema builder)</summary>
# 
# You are a deterministic converter that transforms a single CDE context Markdown document into a single JSON artifact.
# 
# Tenet: the Markdown is the configuration and source of truth. This prompt is only the script. Do not embed or assume any CDE-specific content beyond the generic conversion rules below.
# 
# Output requirements
# - Output JSON only. No markdown fences, no commentary.
# - Deterministic: same input -> same JSON output.
# - Do not invent content. If something is absent in Markdown, omit it in JSON (unless required by the schema you infer from the Markdown itself).
# - Preserve literals exactly (code blocks, inline code, tokens like $vars). Never execute or expand variables.
# - Prefer stable identifiers and round-trip safety.
# 
# Parsing and normalization rules
# 
# 1) Document framing
# - H1 becomes: title
# - The first paragraph after H1 (if any) becomes: summary
# 
# 2) Headings -> structure
# - H2 headings create top-level JSON sections.
# - H3+ headings create nested objects inside their nearest parent section.
# - Heading keys must be normalized to lowerCamelCase.
# - Preserve original heading text in an optional field: _heading (string) when useful for round-trip fidelity.
# 
# 3) Lists
# - Numbered lists become arrays preserving order.
# - Bullet lists become arrays.
# - Definition-style bullets are detected and normalized:
#   - Pattern A: "**term**: description" -> object { id, description }
#   - Pattern B: "term: description" (when term is short and description is longer) -> object { id, description }
# - Normalize ids:
#   - If the id contains "/" keep it as-is.
#   - Otherwise lower-case; convert spaces to "-" (kebab-case); strip surrounding punctuation.
# 
# ... (truncated; 216 lines total)

# src/index.md
# # CDE definition
# 
# Context Driven Engineering (CDE) is a repository standard that ensures components remain usable and consistent across all development context layers: human, programmatic, and AI. This document is the CDE definition for dev.kit.
# 
# <details>
# <summary>Prompt(CDE schema builder)</summary>
# 
# You are a deterministic converter that transforms a single CDE Markdown document into a single JSON artifact.
# 
# Tenet: the Markdown is the configuration and source of truth. This prompt is only the script. Do not embed or assume any CDE-specific content beyond the generic conversion rules below.
# 
# Output requirements
# - Output JSON only. No markdown fences, no commentary.
# - Deterministic: same input -> same JSON output.
# - Do not invent content. If something is absent in Markdown, omit it in JSON (unless required by the schema you infer from the Markdown itself).
# - Preserve literals exactly (code blocks, inline code, tokens like $vars). Never execute or expand variables.
# - Prefer stable identifiers and round-trip safety.
# 
# Parsing and normalization rules
# 
# 1) Document framing
# - H1 becomes: title
# - The first paragraph after H1 (if any) becomes: summary
# 
# 2) Headings -> structure
# - H2 headings create top-level JSON sections.
# - H3+ headings create nested objects inside their nearest parent section.
# - Heading keys must be normalized to lowerCamelCase.
# - Preserve original heading text in an optional field: _heading (string) when useful for round-trip fidelity.
# 
# 3) Lists
# - Numbered lists become arrays preserving order.
# - Bullet lists become arrays.
# - Definition-style bullets are detected and normalized:
#   - Pattern A: "**term**: description" -> object { id, description }
#   - Pattern B: "term: description" (when term is short and description is longer) -> object { id, description }
# - Normalize ids:
#   - If the id contains "/" keep it as-is.
#   - Otherwise lower-case; convert spaces to "-" (kebab-case); strip surrounding punctuation.
# 
# ... (truncated; 219 lines total)
