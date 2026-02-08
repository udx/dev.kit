<img src="assets/logo.svg" alt="dev.kit logo">

# dev.kit

Deterministic developer workflow kit for humans + AI. One CLI entrypoint, shared prompts/templates under `src/`, and a stable contract for iteration.

## Install

Quick start (one-liner):
```bash
curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/main/bin/scripts/install.sh | bash

# If the installer doesn't prompt for shell updates:
source "$HOME/.udx/dev.kit/source/env.sh"
```

## Configure

Common:
```bash
dev.kit config show
dev.kit config set --key ai.enabled --value true
```

Optional: custom state path
```bash
dev.kit config set --key state_path --value "~/.udx/dev.kit/.state"
```

## Use (User Flow)

Pick a mode:

1. **Prompt-only (no AI installed)**  
Generate a deterministic prompt and run it in any tool:
```bash
dev.kit prompt --request "Summarize repo structure"
```

2. **AI-enabled (Codex installed)**  
Apply the Codex config once, then run `dev.kit exec`:
```bash
dev.kit codex apply
dev.kit exec "Summarize repo structure"
```

3. **Dry-run (print only)**  
Generate the prompt without running an AI tool:
```bash
dev.kit exec --print "Summarize repo structure"
```

Tips:
- `dev.kit exec` always uses the same prompt generator as `dev.kit prompt`.
- If AI is disabled, `dev.kit exec` prints the prompt.

## Docs

Start here: `docs/README.md`

Doc map (by topic):
- CLI and execution model: `docs/cli/overview.md`, `docs/cli/execution/index.md`
- AI integration: `docs/ai/README.md`
- Concepts and contracts: `docs/concepts/index.md`, `docs/concepts/specs.md`
- References and standards: `docs/reference/udx-reference-index.md`

## Repo Map (Core)

- `bin/` CLI entrypoints
- `lib/` runtime library code
- `src/` runtime source + templates
- `config/` runtime configuration
- `docs/` specs and contracts
- `src/ai/` shared AI integration assets
- `src/ai/data/` shared AI data (JSON)
- `src/ai/integrations/` integration-specific schemas/templates (codex, claude, gemini)
- `src/ai/data/prompts.json` iteration prompts
- `src/mermaid/` mermaid templates
- `src/docker/` docker assets
- `scripts/` helpers
