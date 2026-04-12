# Workflow Model

For the product summary see [docs/overview.md](overview.md). For command reference see [docs/commands.md](commands.md).

## Phases

dev.kit operates as a pipeline. Each phase builds on the previous — global context from the env phase gates what subsequent phases can do.

```
dev.kit          →  dev.kit repo       →  dev.kit agent
─────────────────   ─────────────────    ─────────────────
validate tools      learn repo           read manifest
write context       scan docs/workflows  generate AGENTS.md
detect repo         write manifest       output AI context
                    update AGENTS.md
```

### Phase 1 — env (`dev.kit`)

Validates the local software environment, writes `$DEV_KIT_HOME/context-env.txt`, detects the current repo, and shows a brief summary.

Global context capabilities that gate downstream phases:

| Capability | Requires | If missing |
|---|---|---|
| `github_enrichment` | `gh` authenticated | GH API enrichment skipped |
| `yaml_parsing` | `yq` | Fallback to worker image |
| `json_parsing` | `jq` | Fallback parsing |
| `cloud_aws/gcp/azure` | respective CLI | Cloud context skipped |

### Phase 2 — repo (`dev.kit repo`)

Builds a resolved view of the repository: docs, scripts, workflows, Dockerfile chains, manifests, version signals. Writes `.dev-kit/manifest.json` and generates `AGENTS.md`.

Three modes:

- **learn** (default): analyze and write manifest + AGENTS.md
- **--scaffold**: also create missing directories and baseline files
- **--check**: report gaps without writing anything

### Phase 3 — agent (`dev.kit agent`)

Reads `.dev-kit/manifest.json` via `jq` and outputs structured context for AI agents. No recomputation — the manifest is the handoff. Generates `AGENTS.md` only if not already present.

## Pipeline Usage

The intended flow for starting a development session:

```bash
cd <repo>
dev.kit
dev.kit repo
dev.kit agent
```

Agents use `dev.kit agent --json` as the machine-readable context contract. `AGENTS.md` is the provider-agnostic summary.

## Separation of Responsibilities

- **Config and scripts** own deterministic workflow logic: discovery, detection, validation, policy
- **AI agents** consume the output contract and add judgment for non-deterministic work
- **Anything repeatable** should live in the repo — not only in a prompt

## Standard Repo First

dev.kit works from standard repository evidence without requiring custom metadata:

- `README` and docs
- manifests: `package.json`, `composer.json`, `Dockerfile`
- `.github/workflows/*`, `deploy.yml`, command layers
- `tests/`, verified entrypoints, runtime and build commands

Custom overlays (`AGENTS.md`, `CLAUDE.md`) are optional and secondary to repo-native sources.

## `dev.kit learn`

`dev.kit learn` evaluates lessons from recent agent sessions and routes follow-ups to durable repo artifacts (GitHub issues, wiki pages, Slack summaries).

It activates when an agent session source is configured:

- Codex: set `CODEX_HOME` to point at session logs
- Other agents: additional sources coming

Without a session source, learn reports the configured workflow destinations but has no session data to evaluate.

## 12-Factor Factors

The repo model evaluates repo health across seven practical dimensions:

| Factor | Checks |
|---|---|
| `documentation` | README, docs/, documentation sections |
| `architecture` | command/logic/view/config layer separation, line limits |
| `dependencies` | package.json, composer.json, requirements.txt, go.mod, etc. |
| `config` | .env files, documented environment variables |
| `verification` | test runner, test directory, bats files |
| `runtime` | Dockerfile, Procfile, documented run command |
| `build_release_run` | build + runtime both present |

Each factor is reported as `present`, `partial`, or `missing` with evidence and improvement guidance.
