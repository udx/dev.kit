# Context Coverage

`.rabbit/context.yaml` is the structured coverage report for the repository.

It should answer three questions:

1. what did `dev.kit` detect?
2. what can be serialized cleanly?
3. what is still missing or only partial?

## What It Covers

`context.yaml` is for facts and deterministic transforms built from repo signals.

Typical sections include:

- repo identity
- priority refs
- detected verify, build, and run commands
- gaps
- manifests
- dependencies
- lessons

Depending on the repo and environment, it may also include live repo experience that can be serialized safely.

## What Gaps Mean

`gaps` is not a generic TODO list. It is the set of engineering factors that `dev.kit` could not confirm fully from the available signals.

That means a gap can represent:

- something missing
- something incomplete
- something present but too thin to treat as strong coverage

This is why context coverage testing should include broken or degraded repos, not only healthy ones.

## What Does Not Belong There

`context.yaml` should not become a prompt or a workflow script.

It is not the right place for:

- agent behavior rules
- long-form operating guidance
- issue or PR handling advice
- subjective reasoning about what an agent should do next

Those belong in `AGENTS.md`.

## Coverage Strategy

The coverage model is repo-first:

- read README, docs, manifests, workflows, tests, and deploy config
- detect commands and factor signals
- trace deterministic dependencies
- report gaps where coverage is weak

That keeps `context.yaml` useful both for healthy repos and for repos that need cleanup.
