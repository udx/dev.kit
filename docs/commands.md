# Commands

## `dev.kit` — environment

Run from any directory. Validates the local software environment, writes global context, and shows a repo summary if a repo is detected.

**What it checks:**

- Base tools: `git`, `gh`, `npm`, `docker`, `yq`, `jq`
- Cloud CLIs: `aws`, `gcloud`, `az` (optional)
- Recommended packages: `@udx/worker-deployment`, `@udx/mcurl` (optional)

**Global context** is cached to `$DEV_KIT_HOME/context-env.txt` (1-hour TTL). Clear it with `rm $DEV_KIT_HOME/context-env.txt` to force a refresh. Capabilities derived from tool state:

| Capability | Requires |
|---|---|
| `yaml_parsing` | `yq` available |
| `json_parsing` | `jq` available |
| `github_enrichment` | `gh` available and authenticated |
| `cloud_aws/gcp/azure` | respective CLI available |

Use `dev.kit --json` to inspect the full `localhost_tools` inventory and `global_context.capabilities` block.

## `dev.kit repo` — repo context

Analyzes the repository against 7 engineering factors and writes `.rabbit/context.yaml` — the canonical context artifact. Detects config manifests (YAML files that define workflow and tooling).

Three modes:

- **learn** (default): analyze repo, write `.rabbit/context.yaml`
- **--scaffold**: also create missing directories and files
- **--check**: report gaps without writing anything

```bash
dev.kit repo
dev.kit repo --scaffold
dev.kit repo --check
dev.kit repo --json
```

Output includes: archetype, profile, factors (✓ present / ◦ partial / ✗ missing), gaps, config manifests, and context path.

## `dev.kit agent` — agent instructions

Generates `AGENTS.md` — a comprehensive guide with anti-drift rules, commands, priority refs, config manifests, full workflow, engineering practices, and lessons from prior sessions.

Auto-generates `.rabbit/context.yaml` if missing — no manual `dev.kit repo` step required.

```bash
dev.kit agent
dev.kit agent --json
```

AGENTS.md includes:
- **Rules** — no filesystem scanning, verify before commit, follow the workflow
- **Config manifests** — traceable YAML dependencies with kind labels
- **Full workflow** — 15-step execution contract with operational notes

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
