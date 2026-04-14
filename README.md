# dev.kit

<https://udx.dev/kit>

**A foundation for context-driven development.**

Simple. Repo-centric. Agent-agnostic.

`dev.kit` resolves a repository into a working system by building context in three layers:

1. **Repo context** — what actually exists: docs, configs, manifests, tests, workflows
2. **Dev environment** — what tools and auth are available: git, gh, docker, npm, cloud CLIs
3. **UDX ecosystem** — shared resources: `github.com/udx/*` repos, `@udx/*` npm packages, Docker Hub images

Each layer reduces guesswork. AI agents operate from repo context with traceable YAML dependencies — no scanning, no drift, no guesswork.

---

## Flow

```
dev.kit          →  dev.kit repo       →  dev.kit agent     →  dev.kit learn
─────────────────   ─────────────────    ─────────────────    ─────────────────
validate env        analyze factors      write AGENTS.md      scan agent sessions
detect repo         detect manifests     auto-generate        extract patterns
show next steps     write context.yaml   context if needed    write lessons artifact
```

Each step feeds the next. `dev.kit agent` auto-generates context if `.rabbit/context.yaml` is absent — no manual steps required.

---

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/main/bin/scripts/install.sh | bash

cd my-repo
dev.kit
dev.kit repo
dev.kit agent
```

---

## Commands

### `dev.kit` — environment

Run in any directory. Detects your repo type, checks local tools, reads priority files, and tells you what to do next.

- Auto-detects archetypes: library-cli, runtime-image, wordpress-site, infra-pipeline, workflow-repo
- Checks local tools: git, gh, npm, docker, jq, cloud CLIs
- Outputs human text or `--json` for agents

```
$ dev.kit
dev.kit

[env]
  - base tools ok

> my-project • library-cli • profile shell

[read first]
  - ./README.md
  - ./docs/architecture.md

[do next]
  - Inspect git status and worktree shape first.
  more:              dev.kit repo | dev.kit agent | dev.kit learn
```

---

### `dev.kit repo` — repo context

Analyzes your repo against 7 engineering factors and writes `.rabbit/context.yaml` — a single file with everything an agent needs: refs, commands, practices, workflow steps, config manifests, and gaps.

- Writes `.rabbit/context.yaml` — the source of truth for all downstream commands
- Detects config manifests (YAML files that define workflow and tooling)
- `--scaffold` creates missing dirs and files
- `--check` reports gaps without changing anything

```
$ dev.kit repo
dev.kit repo

> my-project • library-cli • mode: learn

[factors]
  documentation:     ✓ present
  architecture:      ◦ partial
  config:            ◦ partial
  verification:      ✓ present
  runtime:           ◦ partial
  build_release_run: ✓ present

[gaps]
  - 3 factor(s) missing or partial — run dev.kit repo --scaffold to apply fixes

[context]
  - .rabbit/context.yaml

[next]
  agent context:     dev.kit agent
  session lessons:   dev.kit learn
  apply fixes:       dev.kit repo --scaffold
```

---

### `dev.kit agent` — agent instructions

Generates AGENTS.md — a comprehensive guide that gives any agent everything it needs to work without scanning the filesystem. Auto-generates `.rabbit/context.yaml` if missing.

AGENTS.md includes:
- **Rules** — anti-drift, anti-scanning constraints
- **Commands** — verify, build, run entrypoints
- **Priority refs** — the only files an agent should read
- **Config manifests** — traceable YAML dependencies with kind labels
- **Full workflow** — 15-step execution contract with operational notes
- **Lessons** — patterns learned from prior agent sessions

```
$ dev.kit agent
dev.kit agent

> my-project • library-cli • profile shell

[commands]
  verify:            make test
  build:             make build
  run:               make run

[context]
  agents.md:         /path/to/AGENTS.md
  context.yaml:      /path/to/.rabbit/context.yaml

[start session with]
  - Following AGENTS.md context and repo workflow, [your task here]

[next]
  refresh context:   dev.kit repo
  session lessons:   dev.kit learn
```

Works with Claude, Codex, Gemini, Copilot — any agent that can read files.

---

### `dev.kit learn` — agent experience

Scans recent Claude and Codex sessions, extracts workflow patterns, and writes a lessons artifact at `.rabbit/dev.kit/lessons-*.md`. Lessons feed back into context.yaml on next `dev.kit repo` run.

- Reads Claude and Codex session artifacts automatically
- Detects workflow patterns: issue-to-scope, verify-before-sync, PR chains
- Merges incrementally — new sessions add to prior lessons
- Lessons are referenced from context.yaml and AGENTS.md

```
$ dev.kit learn
dev.kit learn

> dev.learn pr • lessons from agent sessions

[sources]
  claude:            3 session(s) found
  codex:             1 session(s) found

[learned]
  - Verify locally before deploying
  - Use repo workflow assets as the execution contract
  - Keep the delivery chain explicit

[artifact]
  - .rabbit/dev.kit/lessons-my-project-2026-04-14.md

[next]
  refresh context:   dev.kit repo
  update agent:      dev.kit agent
```

---

## Without agents

Use `dev.kit` directly to:

- validate your environment
- understand repositories
- identify structural gaps
- scaffold and standardize projects

Context is the core output. Agents consume it.

---

## Why

**Repo-centric**
The repository is the source of truth. Context comes from docs, configs, manifests, tests — not prompt memory.

**YAML interfaces + tooling**
All behavior is defined in YAML manifests. Shell is thin glue. Agents trace dependencies to config, not code.

**Incremental knowledge base**
Every `dev.kit learn` run adds to a durable lessons artifact. Every lesson is useful — patterns learned from real agent sessions feed back into context.

**Agent-agnostic**
AGENTS.md works with Claude, Codex, Gemini, Copilot — any agent that reads files. Repo context first, not model-specific prompts.

**TDD-friendly**
Verification is a core factor. The workflow enforces verify-before-sync. Tests exist or the gap is flagged.

**Reusable workflows**
Development workflows, PR templates, issue templates, and bot reviewer guidance are defined in YAML configs and applied across repos.

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/main/bin/scripts/install.sh | bash
```

---

## Docs

- [Overview](docs/overview.md)
- [Commands](docs/commands.md)
- [Workflow Model](docs/workflow.md)
- [Architecture](docs/architecture.md)
- [Detection Facets](docs/detection-facets.md)
