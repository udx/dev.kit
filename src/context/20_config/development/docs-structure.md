# Docs Structure

Goal
- Codex-friendly first, while remaining human-readable.
- Clean and organized so docs are useful for development and AI integration.

Structure
- src/
  - index.md (CDE definition)
  - context/ (CDE context layers and source docs)
    - 10_bootstrap/
    - 20_config/ (shared config manifests)
      - ai/
      - standards/
      - architecture/
      - development/ (testing, ideas, plans, todo, refs)
      - user-experience/
      - references/
      - guides/ (can link to references)
      - specs/
      - experience/
      - tooling/
    - 30_module/ (module-specific configs and metadata)
      - ai/ (prompts, rules, skills, config, mcp, etc.)
- public/ (generated or derived outputs)
  - ai/codex.rules.md

Docs as Manifests
- Markdown docs act as manifests for Codex development and research iterations.
- Codex config, rules, and skills should be derived from these docs for consistency.

Workflow
- Edit docs in `src/context/20_config/` and `src/context/30_module/`.
- Build or derive artifacts into `public/`.
- Apply artifacts via dev.kit workflows and verify with plan/show steps.

Config and Workflows as Code
- Applies to all dev.kit modules and integrations.
- Global defaults live under `src/context/20_config/` (shared behavior).
- Module-specific overrides live under `src/context/30_module/<domain>/<module>/`.
- Merging rules: defaults first, then module-specific overrides, last-write wins.

Dynamic Tokens
- Executable: `$child` resolves to all child dirs under the current `src/context` directory.
- Non-executable: wrap in code fences to keep literal, e.g.:
```
$child
```
- Use `$child` in source docs to avoid hardcoding lists of supported modules or clients.
