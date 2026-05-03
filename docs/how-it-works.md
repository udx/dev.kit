# How It Works

`dev.kit` has one primary job: turn repo-declared context into a working contract for agents.

The happy path is:

```bash
dev.kit
```

When a repo is detected, that one command:

- checks the current environment
- refreshes `.rabbit/context.yaml`
- regenerates `AGENTS.md`
- points to the next focused subcommand when needed

The lower-level commands still exist:

- `dev.kit env`
- `dev.kit repo`
- `dev.kit agent`
- `dev.kit learn`

Those are useful when only one layer needs to be refreshed, but the default experience should start from `dev.kit`.

## Generated Artifacts

`dev.kit` produces two core artifacts:

- `.rabbit/context.yaml`
- `AGENTS.md`

`.rabbit/context.yaml` is the structured repo contract. It contains repo identity, direct-read refs, detected commands with their source, structured gaps, manifests, and dependency traces.

`AGENTS.md` is the generated guidance layer for agents. It points back to `context.yaml` instead of duplicating it, and focuses on how the agent should operate from the repo contract.

The intended split is:

- `context.yaml` answers what the repo declares
- `AGENTS.md` answers how an agent should use that declaration

## Repo Assets

The repo is intentionally split into a small set of assets:

- `src/configs/*.yaml` defines repo detection, context sections, signal lists, gap rules, and learning guidance.
- `lib/modules/*.sh` implements thin, config-driven detection and rendering helpers.
- `lib/commands/*.sh` exposes the public command flow: `env`, `repo`, `agent`, `learn`, and `uninstall`.
- `bin/dev-kit` is the CLI entrypoint and the only happy-path runner.
- `.rabbit/context.yaml` and `AGENTS.md` are generated outputs, refreshed from repo signals.
- `tests/` contains the local smoke suite for the basic command flow.

Backend-specific details such as Terraform modules, Docker images, GitHub workflows, and package scripts should appear as traced manifest or dependency details. They should not become top-level repo identities unless the repo explicitly declares that contract.

## Command Roles

`dev.kit env` inspects tools, auth state, and local env config. It is where local capability controls live.

`dev.kit repo` analyzes the repository and writes `.rabbit/context.yaml`.

`dev.kit agent` reads repo context and generates `AGENTS.md`.

`dev.kit learn` extracts optional local lessons into `.rabbit/dev.kit/`. Those artifacts are local-only and are not part of the committed repo contract.

## Working Model

The working model is repo-first:

1. read the repo’s declared context
2. serialize it into `context.yaml`
3. generate lightweight agent guidance from that context
4. let the current repo experience shape the next action

That keeps the repo as the source of truth and reduces prompt drift between sessions.
