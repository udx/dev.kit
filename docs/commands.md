# Commands

## `dev.kit` — environment

Run from any directory. Validates the local software environment, detects the repo, and guides to the next pipeline step.

**What it checks:**

- Required: `git`, `gh`, `npm`, `docker`, `yq`, `jq` — each shown with what it enables
- Cloud CLIs: `aws`, `gcloud`, `az` (optional)
- Recommended: `@udx/worker-deployment`, `@udx/mcurl` (optional)

Capabilities derived from tool availability:

| Capability | Requires |
|---|---|
| `yaml_parsing` | `yq` available |
| `json_parsing` | `jq` available |
| `github_enrichment` | `gh` available and authenticated |
| `cloud_aws/gcp/azure` | respective CLI available |

Use `dev.kit --json` to inspect the full `localhost_tools` inventory and `global_context.capabilities` block.

## `dev.kit repo` — repo context

Analyzes the repository against 4 engineering factors (documentation, dependencies, config, pipeline) and writes `.rabbit/context.yaml` — the canonical context artifact. Detects config manifests (YAML files that define workflow and tooling).

Two modes:

- **learn** (default): analyze repo, pull GitHub context, trace dependencies, write `.rabbit/context.yaml`
- **--check**: report gaps without writing anything
- **--force**: re-resolve all dependency repos from scratch (skip cached context.yaml in sibling repos)

```bash
dev.kit repo
dev.kit repo --check
dev.kit repo --force
dev.kit repo --json
```

Output includes: archetype, profile, factors (✓ present / ◦ partial / ✗ missing), gaps, dependencies, and context path.

### Dependency tracing

`dev.kit repo` traces dependencies from 6 sources (all config-driven from `detection-signals.yaml`):

1. **Reusable workflows** — `uses: org/repo/.github/workflows/...@ref`
2. **GitHub actions** — `uses: org/repo@ref` (direct action references)
3. **Docker images** — `FROM` in Dockerfiles, `image:` in Compose and workflow files, `uses: docker://`
4. **Versioned YAML configs** — `version: domain/repo/module/v1` URIs in `.rabbit/`
5. **GitHub URLs** — `github.com/org/repo` patterns in YAML and markdown
6. **npm packages** — `dependencies` and `devDependencies` from `package.json`

Resolution:
- **Same-org repos**: resolved via `gh api` (primary) then sibling directory lookup. Returns archetype, profile, description.
- **Docker images**: if the Docker Hub org differs from the GitHub org, the image name is matched against same-org repos (e.g., `usabilitydynamics/udx-worker-tooling` → `udx/worker-tooling`).
- **External deps**: listed with `resolved: false` for agent reference. No nested scanning.

Each dependency includes `used_by` — the specific files in the current repo that reference it.

## `dev.kit agent` — execution contract

Generates `AGENTS.md` — a deterministic execution contract with strict rules, commands, priority refs, config manifests, GitHub context, full workflow, engineering practices, and versioned workflow artifacts.

Auto-generates `.rabbit/context.yaml` if missing — no manual `dev.kit repo` step required.

```bash
dev.kit agent
dev.kit agent --json
```

AGENTS.md includes:
- **Contract** — 8 rules: no scanning, strict boundaries, manifests before code, context over memory, verify locally, follow workflow, reuse over invention, remember context
- **Config manifests** — traceable YAML dependencies with kind labels
- **GitHub context** — open issues, recent PRs, security alerts (via `gh api`)
- **Full workflow** — execution sequence with operational notes
- **Engineering practices** — 17 principles from lessons learned

## `dev.kit learn` — agent experience

Scans recent Claude and Codex agent sessions, extracts workflow patterns and operational references, and writes a lessons artifact at `.rabbit/dev.kit/lessons-*.md`.

Lessons feed back into `.rabbit/context.yaml` on next `dev.kit repo` run and are referenced from `AGENTS.md`.

```bash
dev.kit learn
dev.kit learn --json
dev.kit learn --sources claude
```

## `dev.kit uninstall`

Removes the local install from `~/.udx/dev.kit` and the `~/.local/bin/dev.kit` symlink. Does not modify shell profiles.
