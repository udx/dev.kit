# Overview

`dev.kit` produces dynamic repo context. Developers and AI agents consume the same output — no separate workflows.

## The split

dev.kit handles deterministic work that should be repeatable:
- Tool detection and environment validation
- Repo factor analysis (docs, architecture, dependencies, config, verification, runtime, build)
- Cross-repo dependency tracing and resolution
- GitHub signal collection (issues, PRs, security alerts)
- Context artifact generation

Agents and developers handle judgment:
- Code changes, refactoring, feature implementation
- PR creation and review
- Architecture decisions
- Gap prioritization

## Phases

```
dev.kit          →  dev.kit repo        →  dev.kit agent        →  dev.kit learn
─────────────────   ──────────────────    ──────────────────     ──────────────────
check environment   analyze factors       generate AGENTS.md     scan agent sessions
detect archetype    trace dependencies    write execution         extract patterns
guide to next       write context.yaml    contract               write lessons
```

### 1. env — `dev.kit`

Validates the local software environment. Each tool is shown with what it enables. Capabilities gate downstream features:

| Capability | Requires | If missing |
|---|---|---|
| `github_enrichment` | `gh` authenticated | GitHub API enrichment skipped |
| `yaml_parsing` | `yq` | Fallback to awk parsing |
| `json_parsing` | `jq` | Fallback parsing |
| `cloud_aws/gcp/azure` | respective CLI | Cloud context skipped |

### 2. repo — `dev.kit repo`

Analyzes the repository against 4 factors (documentation, dependencies, config, pipeline). Traces cross-repo dependencies from 6 sources. Pulls live GitHub signals. Writes `.rabbit/context.yaml`.

Flags: `--check` (read-only), `--force` (re-resolve dependencies).

### 3. agent — `dev.kit agent`

Generates `AGENTS.md` — a deterministic execution contract with 8 rules, commands, refs, dependencies, workflow, and practices. Auto-generates `.rabbit/context.yaml` if missing.

### 4. learn — `dev.kit learn`

Scans recent Claude and Codex agent sessions, extracts workflow patterns and operational references, writes a lessons artifact at `.rabbit/dev.kit/lessons-*.md`. Lessons feed back into context.yaml on next run.

## Design principles

**Standard signals first** — README, docs, tests, manifests, workflows, deploy config. No custom metadata files required.

**Config over code** — detection patterns, archetype rules, workflow steps all defined in YAML. Shell is thin glue.

**Deterministic scanning** — dev.kit produces the same context from the same repo state. No randomness, no LLM calls.

**One file handoff** — `.rabbit/context.yaml` is the single artifact between dev.kit and everything downstream.
