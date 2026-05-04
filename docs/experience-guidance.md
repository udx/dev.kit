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
- how to react when gaps are present

It should not force one fixed software-delivery script onto every agent role.

## What It Should Enforce

The generated guidance should make a few behaviors explicit:

1. start new sessions with `dev.kit`
2. read `.rabbit/context.yaml` before broad exploration
3. treat repo-owned files and manifests as the primary contract
4. if gaps exist, repair the source assets that should declare the missing contract
5. rerun `dev.kit repo` after those fixes so the agent continues from regenerated context

That is how `AGENTS.md` becomes an enforcement layer instead of just a note file.

## Repo Experience

Current GitHub state is one possible live operating layer.

For some tasks, issues, pull requests, reviews, and workflow runs are central. For others, the useful guidance may be more about repo structure, verification surface, deployment context, or operational signals.

That is why generated guidance should be shaped by:

- repo contract first
- live repo experience where it is relevant and available
- small built-in defaults last

## Why This Layer Exists

Raw repo facts are necessary, but not sufficient.

An agent still needs direction on how to use those facts. `AGENTS.md` is that direction layer, but it should remain smaller than `context.yaml` and should always point back to the repo contract instead of copying it.

It should also keep the instructions provider-neutral so the same repo contract can help Copilot, local agents, and cloud agents.

## Practical Rule

The practical session-start rule remains simple:

```bash
dev.kit
```

Then read:

- `.rabbit/context.yaml`
- `AGENTS.md`

That keeps each session anchored to current repo context instead of stale prompt memory.

If gaps remain, `AGENTS.md` should make the regeneration loop obvious rather than leaving the agent to invent one.
