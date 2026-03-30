# dev.kit

![dev.kit](assets/logo.svg)

`dev.kit` is a 12-factor repo adapter for UDX development workflows.

It is intended to work against normal repositories without requiring custom repo metadata. Standard engineering files remain the source of truth: `README`, docs, tests, manifests, workflow files, deploy config, and command layers. `dev.kit bridge` then translates that standard repo evidence into a cleaner contract for AI agents.

It scans a repository for the workflow contracts that reduce drift across engineering teams: documentation, dependency contracts, config boundaries, verification entrypoints, runtime entrypoints, and build/release/run separation.

It also detects lightweight repo identity facets such as `framework:wordpress`, `runtime:container`, and `deploy:worker-config` so audit and bridge output can explain why a repo was classified a certain way.

The goal is to make repos easier to work on the same way every time. As a repo gets closer to a 12-factor operating model, humans and agents need less tribal knowledge to build, test, run, deploy, and improve it.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/main/bin/scripts/install.sh | bash
dev.kit
```

This installs `dev.kit` into `~/.udx/dev.kit` and adds `dev.kit` to `~/.local/bin/dev.kit`. If `~/.local/bin` is not already on `PATH`, the installer prints the exact command to export it manually.

It is designed to keep repo work grounded in explicit contracts:

- what the repo is
- how humans and agents should work in it
- how local `git/udx` repos relate to remote `github.com/udx/*` knowledge
- which tools and formats define the operating surface: `git`, `gh`, `npm`, `docker`, `yml`

The design goal is context-driven engineering through repo-driven mechanisms:

- 12-factor by default
- repo-centric instead of agent-centric
- test-driven development with smoke-first verification
- markdown/yaml/mmd as durable working formats
- self-contained contracts that are easy to extend without overengineering

There is also a strict separation of responsibilities:

- config plus scripts own deterministic workflow logic, discovery, and policy
- agents consume repo context, saved refs, and command output instead of inventing behavior
- anything critical to repeatability should live in the repo, not only in prompts

## Commands

`dev.kit explore`

- Reports what a repo is, which workflows matter, and which refs to read first.
- Surfaces the knowledgebase hierarchy and operating surface used across UDX repos.

`dev.kit`

- Audits the current repo as a 12-factor engineering contract.
- Returns a short improvement plan by default.
- `--json` returns the same model in machine-readable form.

`dev.kit bridge`

- Exposes the repo model for agents and automation.
- Returns detected archetypes, factor statuses, entrypoints, priority refs, knowledge roots, and guidance so agents can work from grounded repo reality instead of guessing.
- Does not require custom repo-only metadata. Optional saved context can help, but standard repo files remain the primary contract.

`dev.kit save`

- Saves repo-local working context into `./.udx/dev.kit/` for the next session.
- Generates `todo.md`, `context.md`, and `refs.md` from the current repo state and warns before overwriting existing saved context.

`dev.kit sync`

- Evaluates the configured `dev.sync git` workflow for the current git repository.
- Reports workflow state only. It does not create branches, push commits, or open pull requests.
- Shows a short repo-focused summary in text mode and full workflow detail in JSON mode.

`dev.kit learn`

- Evaluates the configured lessons-learned workflow for recent pull requests.
- Keeps the output lightweight and schema-driven so it can later feed GitHub issues, wiki pages, or Slack summaries without adding hidden logic.

## Examples

```bash
dev.kit
dev.kit explore
dev.kit --json
dev.kit bridge --json
dev.kit save
dev.kit sync
dev.kit learn
```

![compliance audit](assets/compliance-audit.svg)

![dev.kit bridge](assets/dev-kit-bridge.svg)

## Why It Matters

Run `dev.kit` when a repo is new, drifting, hard to onboard into, or inconsistent across environments.

The value is operational clarity:

- develop without tribal knowledge
- verify changes predictably
- automate build and runtime workflows
- let teammates and agents operate with less ambiguity
- standardize how work moves from local changes to CI and deployment

## Uninstall

```bash
dev.kit uninstall
```

Removes the local install from `~/.udx/dev.kit` and the `~/.local/bin/dev.kit` symlink.

Further docs:

- [Workflow](/Users/jonyfq/git/udx/dev.kit/docs/workflow.md)
- [Engineering Guide](/Users/jonyfq/git/udx/dev.kit/docs/engineering-guide.md)
- [Pull Requests](/Users/jonyfq/git/udx/dev.kit/docs/pull-requests.md)
- [Development](/Users/jonyfq/git/udx/dev.kit/docs/development.md)
- [Detection Facets](/Users/jonyfq/git/udx/dev.kit/docs/detection-facets.md)

## Tests

Use focused checks during development:

```bash
bash tests/smoke.sh
bash tests/full.sh
```

Run `tests/smoke.sh` for normal local work. Reserve `tests/full.sh` for broader regression coverage and CI-style verification. Keep new tests lightweight by default so agents can verify command contracts without pulling in heavy environment setup.
