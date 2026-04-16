# Agents

`dev.kit agent` turns repo context into agent instructions.

Its main output is `AGENTS.md`, generated from `.rabbit/context.yaml` plus the repo's workflow, practice, and learning inputs.

## Role

If `context.yaml` answers what is known, `AGENTS.md` answers how an agent should operate.

This is the behavior layer. It tells an agent how to use the fetched repo contract efficiently and with minimal drift.

`AGENTS.md` should stay simpler than `context.yaml`. It is a built artifact, not the full repo map.

One core rule should stay explicit: start each new interaction or session by rerunning:

```bash
dev.kit
dev.kit repo
dev.kit agent
```

That keeps repo context, workflow expectations, and generated instructions in sync before deeper work.

## What It Generates

Run:

```bash
dev.kit agent
```

This writes `AGENTS.md`. If `.rabbit/context.yaml` does not exist yet, `dev.kit agent` generates context first.

## Why `AGENTS.md` Exists

Raw repo facts are not enough. Agents still need explicit operating instructions for how to read, decide, verify, and hand work off.

`AGENTS.md` exists to define:

- session-start and interaction-start behavior
- context boundaries
- what to read first
- how to prioritize manifests over implementation
- how to follow the repo workflow
- how to verify before reporting completion
- how to use current GitHub history as the primary dynamic source
- how to fall back to repo workflow, practice catalogs, and lessons without drifting

## Inputs

`AGENTS.md` is generated from repo evidence, not handwritten prompt text:

- `.rabbit/context.yaml`
- YAML workflow and practice catalogs in `src/configs/`
- GitHub repo context when available
- lessons from prior agent sessions

That keeps the instructions grounded and refreshable.

The intended decision order is:

1. current repo contract from `.rabbit/context.yaml`
2. current GitHub experience for this repo
3. repo-declared default workflows and practices
4. prior lessons and other secondary history

## Main Sections

The generated contract typically includes:

- rules
- repo commands
- priority refs
- config manifests
- external dependencies
- GitHub context
- workflow steps
- learned practices

## What Belongs Here

`AGENTS.md` is where dynamic execution guidance belongs.

That includes:

- how an agent should start each session
- how an agent should interpret repo context
- how an agent should use GitHub issues, PRs, and recent history first
- how an agent should sequence work and verification
- how an agent should avoid scanning and guesswork

It should not restate:

- priority refs
- manifest inventories
- dependency maps

Those already belong in `.rabbit/context.yaml`.

This is the layer that combines static repo contract with current repo experience.

## Relationship To `.rabbit/context.yaml`

`.rabbit/context.yaml` is the structured repo map.

`AGENTS.md` is the agent-facing execution contract built on top of that map.

A useful shorthand is:

- `context.yaml` = fetched and serialized repo knowledge
- `AGENTS.md` = instructions for using that knowledge well

They should stay separate, but tightly coupled.

`context.yaml` should stay factual and serializable.

`AGENTS.md` should stay directive, current-state aware, and smaller.

## Efficiency Goal

The best result is a short path from repo state to grounded agent action:

1. `context.yaml` tells the agent what exists and what was detected.
2. `AGENTS.md` tells the agent how to act on that information.
3. The agent spends less time rediscovering the repo and more time doing scoped work.

## JSON Surface

For machine-readable agent integration, use:

```bash
dev.kit agent --json
```

The JSON template for that surface is:

- `src/templates/agent.json`

## Provider-Agnostic

`AGENTS.md` is not tied to one model or tool. The goal is a repo-native execution contract that can guide Codex, Claude, Gemini, Copilot, or other agents without rewriting the repo’s expectations for each provider.
