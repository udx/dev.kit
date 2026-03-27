# dev.kit

![dev.kit](assets/logo.svg)

`dev.kit` is a 12-factor repo adapter.

It scans a repository for the workflow contracts that reduce drift across engineering teams: documentation, dependency contracts, config boundaries, verification entrypoints, runtime entrypoints, and build/release/run separation.

It also detects lightweight repo identity facets such as `framework:wordpress`, `runtime:container`, and `deploy:worker-config` so audit and bridge output can explain why a repo was classified a certain way.

The goal is to make repos easier to work on the same way every time. As a repo gets closer to a 12-factor operating model, humans and agents need less tribal knowledge to build, test, run, deploy, and improve it.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/main/bin/scripts/install.sh | bash
dev.kit
```

This installs `dev.kit` into `~/.udx/dev.kit` and adds `dev.kit` to `~/.local/bin/dev.kit`. If `~/.local/bin` is not already on `PATH`, the installer prints the exact command to export it manually.

## Commands

`dev.kit`

- Audits the current repo as a 12-factor engineering contract.
- Returns a short improvement plan by default.
- `--json` returns the same model in machine-readable form.

`dev.kit bridge`

- Exposes the repo model for agents and automation.
- Returns detected archetypes, factor statuses, entrypoints, and guidance so agents can work from grounded repo reality instead of guessing.

`dev.kit save`

- Saves repo-local working context into `./.udx/dev.kit/` for the next session.
- Generates `todo.md`, `context.md`, and `refs.md` from the current repo state and warns before overwriting existing saved context.

`dev.kit sync`

- Evaluates the configured development sync workflow for the current git repository.
- Reports which git and GitHub review steps are done, pending, blocked, or skipped.

## Examples

```bash
dev.kit
dev.kit --json
dev.kit bridge --json
dev.kit save
dev.kit sync
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

Run `tests/smoke.sh` for normal local work. Reserve `tests/full.sh` for broader regression coverage and CI-style verification.
