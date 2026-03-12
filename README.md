# dev.kit

![dev.kit](assets/logo.svg)

`dev.kit` is a 12-factor repo adapter.

It scans a repository for the workflow contracts that reduce drift across engineering teams: documentation, dependency contracts, config boundaries, verification entrypoints, runtime entrypoints, and build/release/run separation.

The goal is to make repos easier to work on the same way every time. As a repo gets closer to a 12-factor operating model, humans and agents need less tribal knowledge to build, test, run, deploy, and improve it.

## Commands

`dev.kit`

- Audits the current repo as a 12-factor engineering contract.
- Returns a short improvement plan by default.
- `--json` returns the same model in machine-readable form.

`dev.kit bridge`

- Exposes the repo model for agents and automation.
- Returns detected archetypes, factor statuses, entrypoints, and guidance so agents can work from grounded repo reality instead of guessing.

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

## Install

```bash
bash bin/scripts/install.sh
source "$HOME/.udx/dev.kit/bin/env/dev-kit.sh"
dev.kit
```

## Examples

```bash
dev.kit
dev.kit --json
dev.kit bridge --json
```

## Uninstall

```bash
"$HOME/.udx/dev.kit/bin/scripts/uninstall.sh"
```

Further docs:

- [Workflow](/Users/jonyfq/git/udx/dev.kit/docs/workflow.md)
- [Engineering Guide](/Users/jonyfq/git/udx/dev.kit/docs/engineering-guide.md)
- [Pull Requests](/Users/jonyfq/git/udx/dev.kit/docs/pull-requests.md)
- [Development](/Users/jonyfq/git/udx/dev.kit/docs/development.md)
