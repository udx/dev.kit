# Workflow Model

For the product summary see [docs/overview.md](overview.md). For command reference see [docs/commands.md](commands.md).

## Phases

dev.kit operates as a pipeline. Each phase builds on the previous — global context from the env phase gates what subsequent phases can do.

```
dev.kit          →  dev.kit repo       →  dev.kit agent     →  dev.kit learn
─────────────────   ─────────────────    ─────────────────    ─────────────────
validate env        analyze factors      write AGENTS.md      scan agent sessions
detect repo         detect manifests     auto-generate        extract patterns
show next steps     write context.yaml   context if needed    write lessons artifact
```

### Phase 1 — env (`dev.kit`)

Validates the local software environment, detects the current repo, and guides to the next pipeline step. Each tool is shown with what it enables.

Capabilities that gate downstream phases:

| Capability | Requires | If missing |
|---|---|---|
| `github_enrichment` | `gh` authenticated | GH API enrichment skipped |
| `yaml_parsing` | `yq` | Fallback to awk parsing |
| `json_parsing` | `jq` | Fallback parsing |
| `cloud_aws/gcp/azure` | respective CLI | Cloud context skipped |

### Phase 2 — repo (`dev.kit repo`)

Analyzes the repository against 4 factors (documentation, dependencies, config, pipeline). Detects config manifests (YAML files that define workflow and tooling). Writes `.rabbit/context.yaml`.

Three modes:

- **learn** (default): analyze, trace dependencies, pull GitHub context, and write `.rabbit/context.yaml`
- **--check**: report gaps without writing anything
- **--force**: re-resolve all dependency repos from scratch

### Phase 3 — agent (`dev.kit agent`)

Generates `AGENTS.md` — a comprehensive agent guide with anti-drift rules, commands, priority refs, config manifests, full workflow, and lessons. Auto-generates `.rabbit/context.yaml` if missing.

### Phase 4 — learn (`dev.kit learn`)

Scans recent Claude and Codex agent sessions, extracts workflow patterns, and writes a lessons artifact at `.rabbit/dev.kit/lessons-*.md`. Lessons feed back into context.yaml on next `dev.kit repo` run.

## Pipeline Usage

The intended flow for starting a development session:

```bash
cd <repo>
dev.kit
dev.kit repo
dev.kit agent
# ... do work ...
dev.kit learn
```

`dev.kit agent` auto-generates context if `.rabbit/context.yaml` is absent — `dev.kit repo` is not a hard prerequisite. Agents use `dev.kit agent --json` as the machine-readable contract. `AGENTS.md` is the provider-agnostic guide.

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

`dev.kit learn` scans recent Claude and Codex agent sessions, extracts workflow patterns and operational references, and writes a durable lessons artifact.

Supported sources:

- Claude: auto-discovered from `~/.claude/projects/` and `~/.claude/history.jsonl`
- Codex: auto-discovered from `$CODEX_HOME/sessions/`

Use `--sources claude` or `--sources codex` to limit to one source. Without agent sessions, learn reports the configured workflow destinations but has no data to evaluate.

## Factors

dev.kit evaluates what it can detect and advise on programmatically. App architecture and runtime are left to agents and developers.

| Factor | Detects |
|---|---|
| `documentation` | README, docs/ |
| `dependencies` | package.json, composer.json, requirements.txt, go.mod, etc. |
| `config` | .env files, documented environment variables |
| `pipeline` | CI workflows, test commands, deploy configs, infra dirs |

Each factor is reported as `present`, `partial`, or `missing` with evidence and improvement guidance.
