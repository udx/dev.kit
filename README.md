# dev.kit

<https://udx.dev/kit>

**Dynamic repo context for developers and AI agents.**

dev.kit scans what humans and agents shouldn't scan manually — tools, factors, dependencies, cross-repo relationships. It produces one context file. Developers read it. Agents execute from it.

```bash
npm install -g @udx/dev-kit
```

---

## How it works

```
dev.kit          →  dev.kit repo        →  dev.kit agent
─────────────────   ──────────────────    ──────────────────
check environment   analyze repo          generate AGENTS.md
detect archetype    trace dependencies    write execution contract
guide to next       write context.yaml    from context.yaml
```

Each command enriches context and guides to the next. Run at every session start.

---

## Quick start

```bash
cd my-repo
dev.kit            # check tools, detect repo
dev.kit repo       # analyze factors, trace deps, write .rabbit/context.yaml
dev.kit agent      # generate AGENTS.md execution contract
```

---

## What gets generated

**`.rabbit/context.yaml`** — one file, complete repo context:

```yaml
repo:
  name: dev.kit
  archetype: library-cli
  profile: node

refs:
  - ./README.md
  - ./docs/architecture.md
  - ./package.json

commands:
  verify: make test
  build: make build

dependencies:
  - repo: udx/reusable-workflows
    type: reusable workflow
    resolved: true
    archetype: workflow-repo
    used_by:
      - .github/workflows/npm-release-ops.yml

gaps:
  - architecture (partial)
  - config (partial)
```

**`AGENTS.md`** — execution contract with 8 rules, commands, refs, dependencies, workflow, practices. Works with Claude, Codex, Gemini, Copilot — any agent that reads files.

---

## Commands

| Command | What it does |
|---------|-------------|
| `dev.kit` | Check environment, detect repo, show next step |
| `dev.kit repo` | Analyze factors, trace dependencies, pull GitHub signals, write `context.yaml` |
| `dev.kit repo --force` | Re-resolve all dependencies from scratch |
| `dev.kit agent` | Generate `AGENTS.md` from `context.yaml` |
| `dev.kit learn` | Extract patterns from Claude/Codex sessions into lessons artifact |

All commands support `--json` for machine-readable output.

---

## Cross-repo tracing

Traces dependencies from 6 sources: workflow reuse, GitHub actions, Docker images, versioned YAML, GitHub URLs, npm packages.

Same-org repos resolved via `gh api` + sibling directory. Docker images mapped to source repos automatically.

```yaml
# udx/rabbit-automation-action
dependencies:
  - repo: udx/gh-workflows
    type: reusable workflow
    resolved: true

  - repo: usabilitydynamics/udx-worker-tooling:0.19.0
    type: base image
    resolved: true
    source_repo: udx/worker-tooling
```

---

## Install

```bash
# npm (recommended)
npm install -g @udx/dev-kit

# or curl
curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/main/bin/scripts/install.sh | bash
```

---

## Docs

- [Overview](docs/overview.md) — design principles and phases
- [Commands](docs/commands.md) — full command reference with output details
- [Workflow](docs/workflow.md) — pipeline phases, factors, session flow
- [Architecture](docs/architecture.md) — config catalog, module map, data flow
