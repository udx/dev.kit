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

## Configure (First Run)

See current config:

```bash
dev.kit config show
```

Defaults (out of the box):

- AI disabled (`ai.enabled = false`)
- Minimal prompt (`exec.prompt = ai.codex.min`)
- Non-streaming logs (`exec.stream = false`)
- Repo-scoped context (`context.enabled = true`, `context.max_bytes = 4000`)

Optional: set explicit state path

```bash
dev.kit config set --key state_path --value "~/.udx/dev.kit/state"
```

Enable AI (Codex):

```bash
dev.kit config set --key ai.enabled --value true
dev.kit codex apply
```

## Use (Incremental)

1. **Prompt-only (no AI installed)**  
   Generate a deterministic prompt and run it in any tool:

```bash
dev.kit prompt --request "Summarize repo structure"
```

2. **AI-enabled (Codex installed)**  
   Run `dev.kit exec` to generate + execute the prompt:

```bash
dev.kit exec "Summarize repo structure"
```

If Codex is not installed, `dev.kit exec` prints the prompt so you can run it manually.

3. **Dry-run (print only)**

```bash
dev.kit exec --print "Summarize repo structure"
```

## Auto-Detection + Suggestions

- `dev.kit exec` uses the same prompt generator as `dev.kit prompt`.
- If AI is disabled or Codex is missing, `dev.kit exec` prints the prompt and exits.
- Context history is automatically included (repo-scoped).

## What You Can Do (Core)

```bash
dev.kit prompt --request "Summarize repo structure"
dev.kit exec "Summarize repo structure"
dev.kit exec --print "Summarize repo structure"
```

Context controls:

```bash
dev.kit exec --reset "remember: 1234"
dev.kit exec --no-context "one-off question"
dev.kit context show
```

## With AI Integration (Empower)

Apply repo skills to Codex:

```bash
dev.kit codex apply
dev.kit ai skills
```

Tips:

- Streaming logs are off by default; pass `--stream` for full runner output.
- Simple requests answer directly; complex requests route to workflow.

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
