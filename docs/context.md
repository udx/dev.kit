# Context

`.rabbit/context.yaml` is the structured repo contract produced by `dev.kit repo`.

It should answer: what can be fetched from this repo programmatically, what was detected, what is missing, and what other repos or workflows this repo depends on.

## Role

`context.yaml` is the machine-friendly map of the repository. It is not the place for agent policy, step-by-step behavior, or prompt-style instructions.

Use it for facts such as:

- repo identity
- priority refs
- canonical commands
- detected gaps
- manifests that define behavior
- traced dependencies and where they are used
- workflow and practice data that can be emitted from repo-owned config

## How It Is Produced

Run:

```bash
dev.kit repo
```

That command inspects repo-native signals, resolves what it can deterministically, and writes `.rabbit/context.yaml`.

If the file is missing, `dev.kit agent` can generate it first before writing `AGENTS.md`.

## What Feeds It

`context.yaml` comes from evidence `dev.kit` can fetch or derive from the repo and its configured integrations:

- README and docs
- manifests like `package.json`, `composer.json`, `Dockerfile`
- `.github/workflows/*`
- `deploy.yml`
- tests and command surfaces
- YAML config catalogs in `src/configs/`
- GitHub repo signals when available

The key boundary is simple: if `dev.kit` can detect it, trace it, or serialize it, it belongs here.

## Main Sections

The generated file in this repo currently includes:

- `repo`
- `refs`
- `commands`
- `gaps`
- `practices`
- `workflow`
- `dependencies`
- `manifests`
- `lessons`

Depending on available integrations, it may also include GitHub-derived data.

## What Each Section Means

`repo` identifies the repository through values such as `name`, `archetype`, and `profile`.

`refs` is the priority reading list. It tells an agent or tool which files and directories matter first.

`commands` is the detected execution surface, such as `verify`, `build`, and `run`.

`dependencies` is cross-repo tracing. Each entry explains what external repo, package, or workflow was referenced and which local files use it.

`gaps` is a checklist of missing or partial factors `dev.kit` could detect programmatically.

`manifests` lists the config files that define repo behavior. In `dev.kit`, these are first-class interfaces.

`practices` and `workflow` are still structured repo data. They come from repo-owned catalogs, not from prompt-time improvisation.

`lessons` links prior session artifacts produced by `dev.kit learn`.

## What Does Not Belong Here

`context.yaml` should not try to be the final agent prompt.

It is not where you explain:

- how an agent should interpret ambiguity
- how an agent should sequence work for a user
- how an agent should balance repo context against current task context

That layer belongs in `AGENTS.md`.

## Efficiency Goal

The point of `context.yaml` is compression without losing structure.

It should let an agent answer questions like:

- What commands exist?
- What docs and manifests matter first?
- What dependencies are real, and where are they used?
- Which engineering factors are missing?
- What workflow steps are already declared by the repo?

If that data is available in `context.yaml`, the agent does not need to rediscover it by scanning.

## JSON Contract

For automation, the repo command JSON surface is defined by:

- `src/templates/repo.json`

That JSON output and `.rabbit/context.yaml` are the stable structured surfaces from `dev.kit repo`.
