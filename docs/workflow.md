# Workflow

## When to Use `dev.kit`

Use `dev.kit` when you need to understand or normalize how a repository should be worked on.

Common cases:

- a new repo has unclear build, test, or runtime conventions
- a mature repo has drifted across teams or environments
- an agent needs grounded repo context before making changes
- you want one reproducible way to verify and operate the service

## What `dev.kit` Looks For

The current audit focuses on practical 12-factor workflow boundaries:

- `documentation`
- `architecture`
- `dependencies`
- `config`
- `verification`
- `runtime`
- `build_release_run`

Each factor is reported as `present`, `partial`, or `missing`, with evidence and improvement advice.

## Human Workflow

1. Run `dev.kit`.
2. Read the missing or partial factors.
3. Normalize the repo around one clear way to configure, verify, build, and run it.
4. Re-run `dev.kit` to confirm the repo model is improving.

## Agent Workflow

1. Run `dev.kit bridge --json`.
2. Use the reported factor model and entrypoints as the working contract.
3. Prefer discovered commands over inferred ones.
4. Improve partial or missing factors as part of the change when appropriate.

## Current Scope

The detector currently recognizes common signals from Node, PHP, shell, and container-oriented repos. The scan policy is config-driven from [src/configs](/Users/jonyfq/git/udx/dev.kit/src/configs), so supported signals can grow without changing the CLI model.

Broader repo working rules and engineering expectations live in [docs/engineering-guide.md](/Users/jonyfq/git/udx/dev.kit/docs/engineering-guide.md).
