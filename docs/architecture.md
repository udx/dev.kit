# Architecture

## Config Catalog

The `src/configs/` directory is the knowledge library that drives all detection, classification, and output. Shell modules read from it — they never hardcode the same values. This makes the detection layer extensible without changing CLI code.

| File | Kind | Role |
|---|---|---|
| `context-config.yaml` | contextConfig | Root file/dir markers and priority reference paths |
| `detection-signals.yaml` | detectionSignals | File globs, dir lists, architecture thresholds |
| `detection-patterns.yaml` | detectionPatterns | Regex patterns for verification, build, run, env vars |
| `archetype-signals.yaml` | archetypeSignals | File/dir signals per archetype (wordpress, kubernetes, …) |
| `archetype-rules.yaml` | archetypeRules | Precedence order, required + supporting facets per archetype |
| `development-workflows.yaml` | developmentWorkflows | Git workflow steps and capabilities |
| `development-practices.yaml` | developmentPractices | Engineering principles surfaced in guidance output |
| `knowledge-base.yaml` | knowledgeBase | Local and remote repo hierarchy roots |
| `learning-workflows.yaml` | learningWorkflows | Agent session flow patterns and routing rules |
| `repo-scaffold.yaml` | repoScaffold | Baseline dirs/files and per-archetype scaffold definitions |

All catalogs use the same schema: `kind`, `version`, `config`. Parsed by `lib/modules/config_catalog.sh` via `dev_kit_catalog_value()`.

## Module Map

```
lib/modules/
  bootstrap.sh          — env setup, DEV_KIT_HOME, module path list
  config_catalog.sh     — YAML catalog reader (awk-based, no yq dependency)
  local_env.sh          — tool validation, global context, cache
  output.sh             — terminal formatting (title, section, row, list)
  utils.sh              — JSON escaping, CSV/array helpers, YAML parsing
  repo_signals.sh       — repo root detection, file/glob/pattern matching
  repo_archetypes.sh    — facet detection, archetype classification
  repo_factors.sh       — 12-factor analysis (present/partial/missing)
  repo_reports.sh       — factor summary JSON, agent contract
  repo_workflows.sh     — entrypoints JSON, workflow contract
  repo_scaffold.sh      — manifest write, AGENTS.md, scaffold apply
  dev_sync.sh           — git state, gh auth, branch analysis, next hint
  learning_sources.sh   — agent session discovery and flow scoring
  template_renderer.sh  — mustache-style template rendering

lib/commands/
  repo.sh               — learn/scaffold/check modes, writes manifest
  agent.sh              — reads manifest, outputs AI context
  learn.sh              — lessons-learned from agent sessions
  uninstall.sh          — removes dev.kit installation
```

## Data Flow

```
bin/dev-kit
    │
    ├─ dev_kit_run_home()        ← Phase 1: env + context + repo summary
    │   ├─ local_env.sh          → tool validation, capabilities, context cache
    │   ├─ repo_signals.sh       → repo root detection, markers
    │   ├─ repo_archetypes.sh    → archetype + profile
    │   └─ dev_sync.sh           → git state, next action hint
    │
    ├─ dev_kit_cmd_repo()        ← Phase 2: repo analysis + manifest
    │   └─ repo.sh               → renders repo.json template
    │       ├─ repo_signals.sh
    │       ├─ repo_archetypes.sh
    │       ├─ repo_factors.sh
    │       ├─ repo_reports.sh   → factor summary JSON
    │       ├─ repo_workflows.sh → entrypoints, workflow contract
    │       └─ repo_scaffold.sh  → manifest write, AGENTS.md
    │
    ├─ dev_kit_cmd_agent()       ← Phase 3: AI context from manifest
    │   └─ agent.sh              → renders agent.json template
    │       └─ reads .dev-kit/manifest.json via jq (no module calls)
    │
    └─ dev_kit_cmd_learn()       ← Phase 4: lessons from agent sessions
        └─ learn.sh              → renders learn.json template
            └─ learning_sources.sh → session discovery + flow scoring
```

## Manifest

`.dev-kit/manifest.json` is the handoff artifact between `dev.kit repo` and `dev.kit agent`. Written by `repo_scaffold.sh`, read by `agent.sh` directly via `jq`. No recomputation on the agent side.

Fields: `repo`, `path`, `archetype`, `profile`, `priority_refs`, `entrypoints`, `workflow_contract`, `factors`.

## Global Context

`$DEV_KIT_HOME/context-env.txt` — cached tool lines, written on first run, TTL 1 hour.

Format: `tool|category|status` per line.

Capabilities are derived from this file on every call (no extra processes). Downstream phases read capabilities to gate features:

```
github_enrichment = gh available + auth ok
yaml_parsing      = yq available
json_parsing      = jq available
cloud_aws/gcp/az  = respective CLI available
```

Clear cache: `rm "$DEV_KIT_HOME/context-env.txt"`

## Output Contract

Every command supports `--json` for machine-readable output. The JSON schemas are defined in `src/templates/`:

- `repo.json` — archetype, profile, markers, factors, gaps, manifest path
- `agent.json` — repo context, priority refs, entrypoints, workflow contract, factors
- `learn.json` — session, flow, destinations, shared context

These templates are the stable contract for agents and automation. Shell output (no `--json`) is for humans only and may change freely.
