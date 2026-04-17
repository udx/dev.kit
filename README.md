# dev.kit

<https://udx.dev/kit>

**GitHub-first session flow for developers and AI agents.**

dev.kit separates three concerns:

- base repo context signals
- deterministic tracing and mapping
- agent execution behavior

It generates `.rabbit/context.yaml` as the structured repo contract, then generates `AGENTS.md` as a built execution artifact that tells agents how to use that context with current GitHub experience first, and repo-declared workflow defaults when GitHub does not provide enough signal.

In practice, dev.kit is middleware between repo facts and live GitHub experience. It keeps each work session anchored to the repo contract, then pushes developers and agents to use current issues, pull requests, review threads, workflow runs, and prior repo patterns before inventing new approaches.

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

Each command moves the session forward and tells the next actor what to do. Agents should rerun the flow at each new interaction or session so context, workflow, and repo state stay synced.

---

## Quick start

```bash
cd my-repo
dev.kit            # check tools, detect repo
dev.kit repo       # analyze factors, trace deps, write .rabbit/context.yaml
dev.kit agent      # generate AGENTS.md execution contract
```

The intended operating loop is:

1. install `dev.kit`
2. start work with `dev.kit`, `dev.kit repo`, and `dev.kit agent`
3. read `.rabbit/context.yaml` and `AGENTS.md`
4. do the actual implementation using current GitHub repo experience first
5. resync the same flow at the next interaction or after repo changes

---

## Generated Context And Workflow

**`.rabbit/context.yaml`** — generated repo map from repo definitions, source files, detected commands, traced dependencies, gaps, and other serializable repo signals:

```yaml
repo:
  name: dev.kit
  archetype: library-cli
  profile: node

refs:
  - ./README.md
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
  - config (partial)
```

**`AGENTS.md`** — generated execution artifact for agents. It should stay simpler than `context.yaml`: rules, workflow, verification, and how to use current GitHub and learned context without duplicating refs, manifests, or dependency maps already serialized in `context.yaml`.

Together, these two artifacts create a disciplined loop:

- `context.yaml` says what the repo declares and what dev.kit could trace
- `AGENTS.md` says how to act on that contract using live GitHub experience first

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

## Repo Context

Repo context comes from repo source first: README, docs, workflows, manifests, tests, and other declared refs. `dev.kit repo` then traces and maps dependencies, commands, gaps, and other serializable signals into `context.yaml`. `AGENTS.md` turns that repo map into an operating contract for agents, using current GitHub context as the primary dynamic input and repo workflow/practice catalogs as fallback defaults.

That means dev.kit does not just tell an agent what files exist. It also pushes the session toward the repo's real delivery loop: branch naming based on repo history, issue and PR writing based on existing patterns, bot feedback loops, and workflow status checks before close-out.

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

# no npm?
curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/latest/bin/scripts/install.sh | bash
```

Use one install path at a time. Installing with npm removes the curl-managed `~/.udx/dev.kit` home and shim. Installing with curl removes the global `@udx/dev-kit` package before laying down the local shim and home directory.

---

## Docs

- [Installation](docs/installation.md) — npm and curl installs, cleanup, uninstall, and verification
- [Context](docs/context.md) — `.rabbit/context.yaml`, its sections, and how it is generated
- [Agents](docs/agents.md) — `AGENTS.md` generation and how agents use it
- [Integration](docs/integration.md) — how the CLI, repo context, and agent workflow fit together
