# How It Works

`dev.kit` turns repo-declared context into a working contract for agents.

The default starting point is:

```bash
dev.kit
```

When a repo is detected, that one command should:

- checks the current environment
- refreshes `.rabbit/context.yaml`
- regenerates `AGENTS.md`
- points to the next focused subcommand when needed

The important idea is that the flow is dynamic:

1. environment state shapes what can be detected and recommended
2. repo signals shape what can be serialized
3. gaps shape what should be repaired next
4. regenerated context shapes how the agent should proceed

The lower-level commands still exist:

- `dev.kit env`
- `dev.kit repo`
- `dev.kit agent`

Those are useful when only one layer needs to be refreshed, but the default experience should start from `dev.kit`.

## Command Flow

Think of the command flow as four linked layers:

### 1. Environment layer

`dev.kit env` detects tools, auth state, and local capability controls.

That matters because later steps should only claim GitHub, cloud, dependency, or container-aware behavior when the current machine actually supports it.

### 2. Repo contract layer

`dev.kit repo` inspects repo-owned signals and writes `.rabbit/context.yaml`.

That file should describe:

- what the repo declares clearly
- what `dev.kit` could trace deterministically
- what is still missing or only partial

### 3. Agent guidance layer

`dev.kit agent` generates `AGENTS.md` from the current repo contract.

That layer should stay smaller than `context.yaml`. Its job is to tell an agent how to operate from the repo contract, not to duplicate the contract itself.

### 4. Repair and regeneration layer

If gaps are detected, the intended loop is:

1. fix the repo-owned source asset that should declare the missing contract
2. rerun `dev.kit repo`
3. regenerate or reread `AGENTS.md`
4. validate that the gap was actually reduced or resolved

That makes gaps part of the workflow, not just passive reporting.

## Generated Artifacts

`dev.kit` produces two core artifacts:

- `.rabbit/context.yaml`
- `AGENTS.md`

`.rabbit/context.yaml` is the structured repo contract. It contains repo identity, direct-read refs, detected commands with their source, structured gaps, manifests, and dependency traces.

`AGENTS.md` is the generated guidance layer for agents. It points back to `context.yaml` instead of duplicating it, and focuses on how the agent should operate from the repo contract.

The intended split is:

- `context.yaml` answers what the repo declares
- `AGENTS.md` answers how an agent should use that declaration

The goal is to free agents from carrying repo-specific memory in prompts while still keeping the operating model current.

## Repo Assets

The repo is intentionally split into a small set of assets:

- `src/configs/*.yaml` defines repo detection, context sections, signal lists, and gap rules.
- `lib/modules/*.sh` implements thin, config-driven detection and rendering helpers.
- `lib/commands/*.sh` exposes the public command flow: `env`, `repo`, `agent`, and `uninstall`.
- `bin/dev-kit` is the CLI entrypoint and the only happy-path runner.
- `.rabbit/context.yaml` and `AGENTS.md` are generated outputs, refreshed from repo signals.
- `tests/` contains the local smoke suite for the basic command flow.

Backend-specific details such as Terraform modules, Docker images, GitHub workflows, and package scripts should appear as traced manifest or dependency details. They should not become top-level repo identities unless the repo explicitly declares that contract.

## Command Roles

`dev.kit env` inspects tools, auth state, and local env config. It defines what later steps can responsibly assume.

`dev.kit repo` analyzes the repository, records deterministic coverage, and writes `.rabbit/context.yaml`.

`dev.kit agent` reads repo context, generates `AGENTS.md`, and should point the agent toward any remaining repair loop.

## Working Model

The working model is repo-first and regeneration-first:

1. read the repo’s declared context
2. serialize it into `context.yaml`
3. generate lightweight agent guidance from that context
4. repair gaps in repo-owned source assets when needed
5. regenerate context and continue from the refreshed contract

That keeps the repo as the source of truth and reduces prompt drift between sessions.
