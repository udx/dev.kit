# Workflow

This document explains the workflow model behind `dev.kit`, not the full user guide. For the product summary, start with [docs/overview.md](/Users/jonyfq/git/udx/dev.kit/docs/overview.md). For command-by-command reference, use [docs/commands.md](/Users/jonyfq/git/udx/dev.kit/docs/commands.md).

## Context-Driven Engineering

`dev.kit` treats the repository as the primary source of truth. The goal is not agent-specific cleverness. The goal is a repo-driven mechanism that lets any human or agent recover the same operating context from the same evidence:

- 12-factor workflow boundaries
- repo-centric commands and refs
- test-driven development with lightweight smoke suites first
- durable formats such as markdown, yaml, and mermaid
- self-contained docs, config, tests, and repo-native task tracking

## Standard Repo First

`dev.kit` should not require custom files to understand a repository. It is expected to read standard engineering signals first:

- `README` and docs
- manifests such as `package.json`, `composer.json`, and `Dockerfile`
- `.github/workflows/*`, deploy config, and command layers
- `tests/`, documented verification entrypoints, and runtime/build commands

If TODOs, refs, or context notes are valuable, keep them in the repo as normal files so humans and programs read the same source. The main job of `dev.kit action` is to translate ordinary repo signals into a better working contract for humans and AI agents.

At UDX, this often means:

- WordPress repos are mostly conventional, and the most important differences are often under `.rabbit/` and `.github/`.
- Non-WordPress repos still follow the same repo-first rule, but the key distinguishing refs may instead be `package.json`, `deploy.yml`, `Makefile`, `docs/`, or other standard top-level contracts.
- In every case, `README.md` remains one of the highest-value files to read first.
- If the repo leans on shared workflow or delivery tooling, humans and agents should also inspect the relevant dependency repos, especially under `udx/*`.

## Separation of Responsibilities

To avoid engineering drift, `dev.kit` keeps a hard boundary between deterministic repo behavior and agent behavior:

- YAML catalogs and shell scripts define what can be discovered, evaluated, rendered, and tested mechanically.
- AI agents read those contracts, docs, tests, TODOs, and refs to decide how to work within the repo.
- If a rule needs to be repeatable, it should move into config, templates, tests, or scripts rather than staying implicit in an agent prompt.

## When to Use `dev.kit`

Use `dev.kit` when you need to understand or normalize how a repository should be worked on.

Common cases:

- a new repo has unclear build, test, or runtime conventions
- a mature repo has drifted across teams or environments
- an agent needs grounded repo context before making changes
- you want one reproducible way to verify and operate the service

## What `dev.kit` Looks For

The current action model focuses on practical 12-factor workflow boundaries:

- `documentation`
- `architecture`
- `dependencies`
- `config`
- `verification`
- `runtime`
- `build_release_run`

Each factor is reported as `present`, `partial`, or `missing`, with evidence and improvement advice.

## Human Workflow

1. Run `dev.kit explore` or just `dev.kit`.
2. Run `dev.kit action`.
3. Read the missing or partial factors and the generated next actions.
4. Normalize the repo around one clear way to configure, verify, build, and run it.
5. Re-run `dev.kit action` to confirm the repo model is improving.

## Agent Workflow

1. Run `dev.kit explore` or `dev.kit action --json`.
2. Use the reported factor model and entrypoints as the working contract.
3. Prefer discovered commands over inferred ones.
4. Improve partial or missing factors as part of the change when appropriate.

## Knowledgebase Hierarchy

UDX development work usually spans two related knowledge roots:

- local repos under `git/udx`
- remote repos and pull requests under `github.com/udx/*`

`dev.kit` keeps those roots explicit so repo work stays grounded in the same local and remote context instead of drifting into agent-specific assumptions.

## Current Scope

The detector currently recognizes common signals from Node, PHP, shell, and container-oriented repos. The scan policy is config-driven from [src/configs](/Users/jonyfq/git/udx/dev.kit/src/configs), so supported signals can grow without changing the CLI model.

Broader repo working rules and engineering expectations live in [docs/engineering-guide.md](/Users/jonyfq/git/udx/dev.kit/docs/engineering-guide.md).
