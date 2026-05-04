# dev.kit

<https://udx.dev/kit>

**Repository context coverage and agent operating guidance.**

`dev.kit` turns repo design into a usable contract for agents.

It does three things:

1. inspect what the current environment can really support
2. detect and serialize repo context into `.rabbit/context.yaml`
3. generate `AGENTS.md` so each new session starts from current repo reality instead of prompt memory

The model is repo-first, gap-aware, and regeneration-friendly. `dev.kit` should describe what the repo declares, note what it cannot confirm yet, and make the next repair step obvious.

```bash
npm install -g @udx/dev-kit
```

## Quick start

```bash
# first make sure your dev.kit install is current
# npm install -g @udx/dev-kit
# or: curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/latest/bin/scripts/install.sh | bash

cd my-repo
dev.kit            # happy path: env + repo context + AGENTS.md
dev.kit env        # inspect tools, auth, and capability controls
dev.kit env --config
dev.kit repo       # refresh only .rabbit/context.yaml
dev.kit agent      # refresh only AGENTS.md
```

## Operating loop

The intended loop is simple:

1. make sure the local `dev.kit` install is current
2. run `dev.kit` at the start of a session
3. let `dev.kit env` shape what capabilities are actually available
4. let `dev.kit repo` write the current repo contract into `.rabbit/context.yaml`
5. let `dev.kit agent` generate operating guidance from that contract
6. if gaps are detected, fix the repo-owned source assets, rerun `dev.kit repo`, then validate the regenerated context

That keeps context dynamic, grounded in repo signals, and resistant to drift.

## Commands

| Command | Role |
|---------|------|
| `dev.kit` | Start here. Refresh environment awareness, repo context, and agent guidance together. |
| `dev.kit env` | Detect tools, auth state, and local capability controls so later steps stay honest. |
| `dev.kit env --config` | Create or update env config for disabling specific tools or credentials. |
| `dev.kit repo` | Detect refs, commands, gaps, manifests, and dependencies, then write `.rabbit/context.yaml`. |
| `dev.kit repo --force` | Re-resolve dependency context from scratch. |
| `dev.kit agent` | Generate `AGENTS.md` from the current repo contract and its gaps. |

All commands support `--json` for machine-readable output and should guide the next step in human- and agent-friendly terms.

## Generated artifacts

`dev.kit` produces two main artifacts:

- `.rabbit/context.yaml` — the machine-readable repo contract
- `AGENTS.md` — the generated operating layer for agents

Keep the boundary strict:

- `context.yaml` is for repo facts, traces, commands, manifests, dependencies, and gaps
- `AGENTS.md` is for how an agent should operate from that contract, including gap-repair behavior

## Install

```bash
# npm (recommended)
npm install -g @udx/dev-kit

# no npm?
curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/latest/bin/scripts/install.sh | bash
```

Use one install path at a time. Installing with npm removes the curl-managed home and shim. Installing with curl removes the global npm package first. More detail: [Installation](docs/installation.md).

## Docs

- [How It Works](docs/how-it-works.md) — command flow, generated artifacts, and regeneration loop
- [Environment Config](docs/environment-config.md) — capability detection and env controls
- [Context Coverage](docs/context-coverage.md) — what `context.yaml` should contain and what gaps mean
- [Experience Guidance](docs/experience-guidance.md) — what `AGENTS.md` should instruct agents to do
- [Smart Dependency Detection](docs/smart-dependency-detection.md) — deterministic cross-repo and manifest tracing
- [Installation](docs/installation.md) — npm and curl installs, cleanup, uninstall, and verification

## Testing

For fast local checks:

```bash
bash tests/suite.sh --only core
```

For installed-CLI testing in a real worker environment:

```bash
bash tests/worker-smoke.sh
```

For opt-in validation against real local repos:

```bash
bash tests/real-repos.sh /path/to/repo1 /path/to/repo2
```

The worker runner is the main integration path for heavier scenarios such as gap repair, env toggles, and real-repo mutation. Real-repo testing is local-only and can include both public and private repos without baking those assumptions into CI.
