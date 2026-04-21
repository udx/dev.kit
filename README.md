# dev.kit

<https://udx.dev/kit>

**Repository context coverage for coding agents.**

`dev.kit` turns repository knowledge into a working contract for agents. It helps an agent start from what the repo already declares, then continue from current repo and GitHub context instead of guessing.

The goal is straightforward: detect repo context, serialize it into `.rabbit/context.yaml`, and generate `AGENTS.md` that stays aligned with that context.

```bash
npm install -g @udx/dev-kit
```

## Quick start

```bash
cd my-repo
dev.kit            # full guided refresh: env + repo context + AGENTS.md
dev.kit env        # inspect tools, auth state, and env config
dev.kit env --config
dev.kit repo       # refresh only .rabbit/context.yaml
dev.kit agent      # refresh only AGENTS.md
```

## Commands

| Command | What it does |
|---------|-------------|
| `dev.kit` | Happy path: check environment, refresh repo context, generate `AGENTS.md` |
| `dev.kit env` | Inspect environment tools, auth state, and env config |
| `dev.kit env --config` | Create or update local env config for disabling tools or credentials |
| `dev.kit repo` | Analyze factors, trace dependencies, pull GitHub signals, write `context.yaml` |
| `dev.kit repo --force` | Re-resolve all dependencies from scratch |
| `dev.kit agent` | Generate `AGENTS.md` from `context.yaml` |
| `dev.kit learn` | Extract patterns from Claude/Codex sessions into lessons artifact |

All commands support `--json` for machine-readable output.

## Install

```bash
# npm (recommended)
npm install -g @udx/dev-kit

# no npm?
curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/latest/bin/scripts/install.sh | bash
```

Use one install path at a time. Installing with npm removes the curl-managed `~/.udx/dev.kit` home and shim. Installing with curl removes the global `@udx/dev-kit` package before laying down the local shim and home directory.

## Docs

- [How It Works](docs/how-it-works.md) — the happy path, artifacts, and command roles
- [Environment Config](docs/environment-config.md) — `dev.kit env`, `env.yaml`, and capability control
- [Context Coverage](docs/context-coverage.md) — what `context.yaml` covers, what gaps mean, and what is intentionally excluded
- [Experience Guidance](docs/experience-guidance.md) — how `AGENTS.md` is generated and how live repo experience shapes guidance
- [Smart Dependency Detection](docs/smart-dependency-detection.md) — cross-repo tracing sources and resolution model
- [Installation](docs/installation.md) — npm and curl installs, cleanup, uninstall, and verification

## Testing

For fast local checks, the repo still includes a shell test suite:

```bash
bash tests/suite.sh --only core
```

For installed-CLI testing in a real worker environment, use the published worker image:

```bash
bash tests/worker-smoke.sh
```

That runner:

- installs the current repo with `npm install -g /workspace`
- runs the installed `dev.kit` inside `usabilitydynamics/udx-worker:latest`
- mounts a target repo so `dev.kit` can be exercised against real local repos
- copies the target repo into scratch space by default so repo context can be intentionally broken without touching the original checkout
- supports `DEV_KIT_TEST_DISABLED_TOOLS` and `DEV_KIT_TEST_DISABLED_CREDS` for env-config scenarios
- supports `DEV_KIT_TEST_PREPARE_CMD` for lightweight repo mutation before running `dev.kit`
