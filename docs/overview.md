# dev.kit Overview (v2)

dev.kit is a local engineering kit that speeds up development workflows through
opt-in tooling, reusable pipelines, and a knowledge base that can be used by both
humans and AI assistants.

## Core idea

- Keep code, config, and docs separated but integrated.
- Prefer opt-in integration and reviewable changes.
- Use `~/.udx/dev.kit/` as the local state/config home.

## Quick flow

1) Install:
   - `bin/scripts/install.sh` installs to `~/.udx/dev.kit/` and prompts config.
2) Configure:
   - Optional shell startup integration (status + reminder).
   - Optional AI CLI integration.
3) Use:
   - `dev.kit -p "<prompt>"` for prompt-driven routing.
   - `dev.kit <command_id>` for step-by-step pipelines.
   - Shell autocomplete loads after `dev.kit enable --shell=...`.

## Modules (assets + docs)

Each module is a small unit with separated assets. The long-term plan is to keep
docs close to modules and also use them as metadata for AI responses.

See `specs/module-metadata.md` for the draft module format.

## AI integration

AI integration is optional but first-class. When enabled, AI clients must route
through dev.kit for prompts, then confirm pipeline steps with the user.

See `specs/ai-integration.md` for the contract.
