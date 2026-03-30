# dev.kit

![dev.kit](assets/logo.svg)

`dev.kit` is a repo-driven development tool for UDX engineering workflows.

It works from standard repository evidence first: `README`, docs, tests, manifests, workflow files, deploy config, and command layers. It does not require custom repo metadata. `dev.kit action` translates that repo evidence into grounded next steps for humans and AI agents.

The goal is to let humans and agents enter almost any repo, recover its operating model from the repo itself, and improve it without engineering drift.

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
- which dependency and tooling repos should be read when repo workflows depend on them

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

## Command Surface

`dev.kit explore`

- Also the default when you run plain `dev.kit`.
- Reports what a repo is, which workflows matter, and which refs to read first.
- Surfaces the knowledgebase hierarchy and operating surface used across UDX repos.
- Emits a concrete workflow contract from repo facts.

`dev.kit action`

- Audits the repo as an engineering contract and turns that into concrete next actions.
- Combines factor findings, agent guidance, git workflow evaluation, and optional continuity refresh in one place.
- `--json` returns the same model in machine-readable form.
- `--refresh-context` regenerates optional repo-local continuity files under `./.udx/dev.kit/`.

`dev.kit learn`

- Evaluates the configured lessons-learned workflow for recent pull requests.
- Keeps the output lightweight and schema-driven so it can later feed GitHub issues, wiki pages, or Slack summaries without adding hidden logic.

## Quick Start

```bash
dev.kit explore
dev.kit action
dev.kit action --json
dev.kit learn
```

![compliance audit](assets/compliance-audit.svg)

![dev.kit bridge](assets/dev-kit-bridge.svg)

## Why It Matters

Run `dev.kit explore` and `dev.kit action` when a repo is new, drifting, hard to onboard into, or inconsistent across environments.

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

## Docs

Start here:

- [Overview](/Users/jonyfq/git/udx/dev.kit/docs/overview.md)
- [Commands](/Users/jonyfq/git/udx/dev.kit/docs/commands.md)
- [Workflow Model](/Users/jonyfq/git/udx/dev.kit/docs/workflow.md)

Contributor and repo guidance:

- [Engineering Guide](/Users/jonyfq/git/udx/dev.kit/docs/engineering-guide.md)
- [Development](/Users/jonyfq/git/udx/dev.kit/docs/development.md)
- [Pull Requests](/Users/jonyfq/git/udx/dev.kit/docs/pull-requests.md)

Reference:

- [Detection Facets](/Users/jonyfq/git/udx/dev.kit/docs/detection-facets.md)

## Tests

Use focused checks during development:

```bash
bash tests/smoke.sh
bash tests/full.sh
```

Run `tests/smoke.sh` for normal local work. Reserve `tests/full.sh` for broader regression coverage and CI-style verification. Keep new tests lightweight by default so agents can verify command contracts without pulling in heavy environment setup.
