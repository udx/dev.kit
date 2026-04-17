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
- how to choose between GitHub workflow verification and local verification
- how to use current GitHub history as the primary dynamic source
- how to fall back to repo workflow, practice catalogs, and lessons without drifting
- how to loop on PR reviews, status checks, and follow-up comments until delivery is actually clean

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

That order matters. `AGENTS.md` should keep agents from skipping straight to implementation when the repo already has issue history, open PR discussion, branch conventions, workflow results, or bot feedback that should shape the next action.

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

This is also where dev.kit can keep common GitHub-facing behaviors explicit, for example:

- derive branch, issue, and PR naming from current repo patterns
- write PR bodies and issue updates in the style the repo already uses
- monitor workflow runs after a push
- read bot feedback, reply, fix, and resolve threads before human review

Verification should follow the same priority:

1. detect the repo's canonical verify surface from `context.yaml`
2. prefer GitHub workflow executions and monitor them when the repo already has CI coverage
3. use local verification when GitHub coverage is missing, when a workflow failure needs local reproduction, or when a quick scoped local check is the fastest way to debug

So `AGENTS.md` should acknowledge local verify commands from repo context, but it should not enforce local execution as a universal rule.

After a PR exists, the same contract should stay explicit:

1. monitor related GitHub workflow executions and status checks
2. loop bot feedback on the PR
3. fix issues, reply to comments, and resolve threads
4. repeat until workflow state and bot feedback are clean

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
