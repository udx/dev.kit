# Overview

`dev.kit` is a repo-driven development tool.

It works from standard repository evidence first:

- `README` and docs
- tests and verification entrypoints
- manifests such as `package.json`, `composer.json`, and `Dockerfile`
- workflow files, deploy config, and command layers

It does not require custom repo metadata to be useful. Optional saved context under `./.udx/dev.kit/` can improve continuity, but the main contract should still live in ordinary repo files.

## Goal

The goal is context-driven engineering through repo-native mechanisms:

- 12-factor workflow boundaries
- repo-centric operation instead of agent-centric operation
- smoke-first, test-driven normalization
- durable repo formats such as markdown, yaml, and mermaid
- clear separation between deterministic repo logic and agent judgment

## What `dev.kit` Does

- `dev.kit explore` explains what a repo is, which refs matter, and which workflows are typical.
- `dev.kit` audits the repo against practical engineering factors.
- `dev.kit bridge --json` translates repo evidence into grounded AI-agent context.
- `dev.kit sync` evaluates Git pull/push readiness through predefined workflows.
- `dev.kit learn` evaluates lessons-learned workflows for recent pull requests.
- `dev.kit save` writes optional repo-local continuity files for later sessions.

## Mental Model

`dev.kit` should stay raw and composable:

- YAML catalogs and shell scripts own deterministic discovery and policy.
- Templates own output shape.
- Agents consume repo facts and add bounded judgment.
- If behavior must be repeatable, it should move into the repo instead of living only in prompts.
