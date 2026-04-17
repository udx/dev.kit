# Integration

`dev.kit` works because it separates repo knowledge from agent behavior, then links them in one session flow.

The goal is not to generate more files. The goal is to reduce uncertainty about what exists, what matters, and how to act.

Another way to say it: dev.kit is middleware between repo-declared context and live GitHub experience. It keeps agents and developers grounded in the repo contract, then points them toward the current issue, PR, review, and workflow state that should drive the next decision.

## Core Flow

The integration model starts with three commands:

```bash
dev.kit
dev.kit repo
dev.kit agent
```

Those commands connect five layers:

1. local environment detection
2. structured repo context generation
3. deterministic tracing and mapping
4. agent contract generation
5. human or agent execution

For agents, this is not only a first-time setup flow. It is the resync loop. On each new interaction or session, rerun the flow so the next action starts from current repo context rather than stale memory.

## Separation Of Responsibilities

The split should stay explicit:

- `dev.kit repo` produces `.rabbit/context.yaml`
- `dev.kit agent` produces `AGENTS.md`

`context.yaml` is the fetched map of the repo and its detectable signals.

`AGENTS.md` is the operating contract that tells an agent how to use that map together with current GitHub context, learned patterns, and repo workflow defaults.

That separation keeps both artifacts smaller and more reliable.

In practice:

- `context.yaml` owns refs, manifests, commands, dependencies, and gaps
- `AGENTS.md` points back to `context.yaml` and stays focused on workflow, practices, and behavior

## Developer Integration

For developers, `dev.kit` provides:

- a quick environment check
- a generated summary of repo factors and gaps
- a canonical command surface for verify, build, and run
- a repeatable way to understand repo expectations before changing code

This reduces time spent rediscovering how a repo works.

It also shortens common GitHub loops. Instead of inventing a new branch name, PR structure, or issue update style each time, the repo contract can point the session back to current repo patterns and current review state first.

## Agent Integration

For agents, `dev.kit` provides:

- a structured reading surface in `context.yaml`
- config and workflow manifests as first-class interfaces
- a behavior contract in `AGENTS.md`
- JSON output for automation and toolchains

This means agents can spend less effort on discovery and more effort on scoped execution.

That execution should stay GitHub-aware. The intended behavior is not just "read files, then code." It is "refresh repo contract, inspect current GitHub experience, act, then loop on workflows and automated review until the change is actually ready."

## GitHub And History

GitHub and learning data are most useful when they support agent decisions, not when they blur the repo map.

In practice:

- repo and integration signals can be serialized into `context.yaml`
- current issues, PRs, and repo history are the primary dynamic inputs in `AGENTS.md`
- workflow expectations and practice catalogs act as fallback defaults in `AGENTS.md`
- lessons remain secondary memory that should not outrank live repo or GitHub state

That gives agents both structure and recency without mixing roles.

## Workflow Integration

The generated workflow is intended to fit into normal engineering work:

1. start the session with `dev.kit`, `dev.kit repo`, and `dev.kit agent`
2. read the generated repo contract and agent contract
3. inspect current GitHub issue, PR, review, and branch context before inventing a new path
4. do the actual implementation or review work
5. verify through the repo-declared surface, preferring GitHub workflow runs when the repo already has CI coverage
6. loop on bot reviews, workflow failures, and follow-up comments until the delivery chain is clean
7. optionally run `dev.kit learn` so session outcomes feed future runs

## Config-Driven Integration

`dev.kit` does not rely on hidden prompt rules. It integrates through repo-owned config and workflow assets:

- `src/configs/*.yaml`
- workflow files
- repo manifests
- docs
- tests

That makes behavior inspectable, versioned, and reusable.

## Efficiency Goal

The best integration is:

- `context.yaml` stays factual and structured
- tracing and mapping stay deterministic
- `AGENTS.md` stays directive and execution-oriented
- GitHub experience stays the primary dynamic source for agent judgment
- both are regenerated cheaply at session start

That gives developers and agents one contract with two surfaces instead of two competing sources of truth.
