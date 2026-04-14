# Overview

`dev.kit` is a repo-driven development tool.

## Goal

Context-driven engineering through repo-native mechanisms:

- Develop without tribal knowledge. Verify changes predictably.
- Let teammates and agents operate with less ambiguity.
- Standardize how work moves from local changes to CI and deployment.
- Keep deterministic logic in repo config and scripts. Reserve AI agents for judgment that can't be scripted.

## Phases

dev.kit operates in phases. Each phase builds on the previous and uses global context to gate what it can do.

### 1. env — `dev.kit`

Validates the local software environment and writes a global context file (`$DEV_KIT_HOME/context-env.txt`). This context determines what downstream phases can do:

- `github_enrichment` — active only when `gh` is installed and authenticated
- `yaml_parsing` — active only when `yq` is available
- `json_parsing` — active only when `jq` is available
- `cloud_aws/gcp/azure` — active only when respective CLI is available

### 2. repo — `dev.kit repo`

Builds a resolved view of the repository: docs, scripts, workflows, deploy config, Dockerfile chains, manifests. Identifies gaps against 7 engineering factors. Detects config manifests (YAML files that define workflow and tooling). Pulls GitHub context via `gh api`. Writes `.rabbit/context.yaml`.

### 3. agent — `dev.kit agent`

Generates `AGENTS.md` — a comprehensive agent guide with rules, refs, config manifests, full workflow, and lessons. Auto-generates `.rabbit/context.yaml` if missing.

### 4. learn — `dev.kit learn`

Scans recent Claude and Codex agent sessions, extracts workflow patterns and operational references, and writes a lessons artifact at `.rabbit/dev.kit/lessons-*.md`. Lessons feed back into context.yaml on next `dev.kit repo` run.

## What `dev.kit` Does

- `dev.kit` — validates env, writes global context, detects repo
- `dev.kit repo` — analyzes repo, writes `.rabbit/context.yaml`, optionally scaffolds structure
- `dev.kit agent` — generates `AGENTS.md` with full repo context and traceable YAML dependencies
- `dev.kit learn` — extracts lessons from Claude and Codex sessions, writes durable artifact

## Design Principles

**Repo-centric**: works from standard repository evidence (README, docs, tests, manifests, workflows, deploy config). Does not require custom metadata files.

**Standard signals first**: markdown and YAML are durable working formats. Repo-native sources (README, docs, TODO, workflows) take precedence over custom overlays.

**Strict separation**: config and scripts own deterministic discovery and policy. Templates own output shape. Agents consume repo facts and add bounded judgment. If behavior must be repeatable, it should move into the repo — not live only in prompts.

**Traceable dependencies**: YAML manifests define workflow and tooling behavior. Agents trace dependencies to config manifests, not shell code. Config manifests are listed in `.rabbit/context.yaml` and inlined into `AGENTS.md`.
