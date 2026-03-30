# Engineering Guide

This document is about how to build `dev.kit`, not how to use it on another repo. For the user-facing model, see [docs/overview.md](/Users/jonyfq/git/udx/dev.kit/docs/overview.md), [docs/commands.md](/Users/jonyfq/git/udx/dev.kit/docs/commands.md), and [docs/workflow.md](/Users/jonyfq/git/udx/dev.kit/docs/workflow.md).

`dev.kit` treats engineering workflow as part of the repository contract.

The point is not ceremony. The point is reducing drift so teammates and agents can work the same repo in the same way without long discussions, hidden local habits, or guesswork.

## Core Rules

- Keep repository workflow explicit: one clear way to configure, verify, build, run, and deploy.
- Prefer repo contracts over personal habits. If a command matters, document it or expose it.
- Keep logic modularized and split by responsibility.
- Keep configuration and output contracts in data or templates when possible instead of embedding structure in command code.
- Keep module files under roughly `300-400` lines when possible. Split before a file becomes a catch-all.
- Keep docs split by concern so product intent, workflow model, contributor rules, and PR guidance do not blur together.

## Structural Pattern

For this repo, and for repos `dev.kit` should favor:

- controller layer: `lib/commands/`
- model and service layer: `lib/modules/`
- view and output layer: `src/templates/`
- config and contracts: `src/configs/`

This is not strict framework MVC. It is a practical separation of command surface, domain logic, output rendering, and configuration.

## Start of Session

Before continuing work:

```bash
git status
git pull --ff-only
```

Then align your branch with the repo's current base branch:

```bash
git merge origin/main
```

If the repo uses a different base branch such as `staging`, merge that branch instead.

## During Work

- keep changes scoped so verification and review stay clear
- prefer the repo's canonical commands over ad hoc local habits
- use `dev.kit` when build, test, config, or runtime expectations are unclear
- use `dev.kit action --json` when an agent needs grounded repo context

## End of Session

Before stopping work:

- commit your current state, even if the work is partial
- push the branch so CI and PR protection can validate it
- leave enough context in the branch and commit history that tomorrow starts from facts, not memory

This reduces hidden local progress and protects the rest of the team from drift.

## Enforcement

Some of these rules are documentable habits. Some are enforceable.

Good enforcement targets:

- commit message policy
- canonical verification before push
- explicit config and output contracts
- module structure and file-size guidance
- pull request structure and operational clarity

Poor enforcement targets:

- whether someone checked `git status` at the start of the day
- whether they merged the right base branch at the right moment without repo context

`dev.kit` should increasingly validate the enforceable parts of this guide, so the repo teaches its own operating model to both humans and agents.

Useful PR guidance is documented separately in [docs/pull-requests.md](/Users/jonyfq/git/udx/dev.kit/docs/pull-requests.md).
