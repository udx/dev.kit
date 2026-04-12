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

## `dev.kit repo` — repo analysis

Builds a resolved view of the repository and writes a manifest to `.dev-kit/manifest.json`.

Three modes:

- **learn** (default): read repo evidence, write manifest and `AGENTS.md`
- **--scaffold**: also create missing directories and files
- **--check**: report gaps without writing anything

```bash
dev.kit repo
dev.kit repo --scaffold
dev.kit repo --check
dev.kit repo --json
```

Output includes: archetype, profile, markers, factors (present/partial/missing), gaps, and manifest path.

## `dev.kit agent` — agent context

Reads the repo manifest (`.dev-kit/manifest.json`) and outputs a structured context for AI agents.

Requires `dev.kit repo` to have run first.

```bash
dev.kit agent
dev.kit agent --json
```

Generates `AGENTS.md` only if not already present (it is created by `dev.kit repo`).

## `dev.kit learn` — lessons learned

Evaluates the configured lessons-learned workflow from recent agent sessions.

Discovers recent agent sessions (Codex, etc.), scores them against flow patterns, and routes findings to configured destinations (GitHub issues, wiki, Slack).

```bash
dev.kit learn
dev.kit learn --json
```

## `dev.kit uninstall`

Removes the local install from `~/.udx/dev.kit` and the `~/.local/bin/dev.kit` symlink. Does not modify shell profiles.
