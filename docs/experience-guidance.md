# Experience Guidance

`AGENTS.md` is the generated operating layer built on top of `.rabbit/context.yaml`.

Its purpose is not to restate the repo map. Its purpose is to help an agent operate from that repo map without drifting.

## What It Should Do

`AGENTS.md` should stay lightweight and role-aware.

That means it should help with:

- how to start from the repo contract
- what to read first
- how to prefer manifests over guesswork
- when to verify locally
- when live repo experience should matter more than defaults

It should not force one fixed software-delivery script onto every agent role.

## Repo Experience

Current GitHub state is one possible live operating layer.

For some tasks, issues, pull requests, reviews, and workflow runs are central. For others, the useful guidance may be more about repo structure, verification surface, deployment context, or operational signals.

That is why generated guidance should be shaped by:

- repo contract first
- live repo experience where it is relevant and available
- lessons and fallback defaults last

## Why This Layer Exists

Raw repo facts are necessary, but not sufficient.

An agent still needs direction on how to use those facts. `AGENTS.md` is that direction layer, but it should remain smaller than `context.yaml` and should always point back to the repo contract instead of copying it.

## Practical Rule

The practical session-start rule remains simple:

```bash
dev.kit
```

Then read:

- `.rabbit/context.yaml`
- `AGENTS.md`

That keeps each session anchored to current repo context instead of stale prompt memory.
