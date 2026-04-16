# Integration

`dev.kit` works because it separates repo knowledge from agent behavior, then links them in one session flow.

The goal is not to generate more files. The goal is to reduce uncertainty about what exists, what matters, and how to act.

## Core Flow

The integration model starts with three commands:

```bash
dev.kit
dev.kit repo
dev.kit agent
```

Those commands connect four layers:

1. local environment detection
2. structured repo context generation
3. agent contract generation
4. human or agent execution

For agents, this is not only a first-time setup flow. It is the resync loop. On each new interaction or session, rerun the flow so the next action starts from current repo context rather than stale memory.

## Separation Of Responsibilities

The split should stay explicit:

- `dev.kit repo` produces `.rabbit/context.yaml`
- `dev.kit agent` produces `AGENTS.md`

`context.yaml` is the fetched map of the repo and its detectable signals.

`AGENTS.md` is the operating contract that tells an agent how to use that map together with workflow expectations, GitHub context, and learned patterns.

That separation keeps both artifacts smaller and more reliable.

## Developer Integration

For developers, `dev.kit` provides:

- a quick environment check
- a generated summary of repo factors and gaps
- a canonical command surface for verify, build, and run
- a repeatable way to understand repo expectations before changing code

This reduces time spent rediscovering how a repo works.

## Agent Integration

For agents, `dev.kit` provides:

- a structured reading surface in `context.yaml`
- config and workflow manifests as first-class interfaces
- a behavior contract in `AGENTS.md`
- JSON output for automation and toolchains

This means agents can spend less effort on discovery and more effort on scoped execution.

## GitHub And History

GitHub and learning data are most useful when they support agent decisions, not when they blur the repo map.

In practice:

- repo and integration signals can be serialized into `context.yaml`
- current issues, PRs, lessons, and workflow expectations become most useful in `AGENTS.md`

That gives agents both structure and recency without mixing roles.

## Workflow Integration

The generated workflow is intended to fit into normal engineering work:

1. start the session with `dev.kit`, `dev.kit repo`, and `dev.kit agent`
2. read the generated repo contract and agent contract
3. do the actual implementation or review work
4. verify with repo-declared commands
5. optionally run `dev.kit learn` so session outcomes feed future runs

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
- `AGENTS.md` stays directive and execution-oriented
- both are regenerated cheaply at session start

That gives developers and agents one contract with two surfaces instead of two competing sources of truth.
