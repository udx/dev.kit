# 12-Factor (Applied)

## Summary

The 12-Factor App is a set of operational principles for services. In dev.kit, it guides how configs, environments, and runtime behavior should be structured.

## When To Use

- Defining configuration strategy.
- Designing runtime layout and process management.
- Establishing logging and release discipline.

## Quick Answers

- "Where should config live?" -> environment variables or runtime config files; repos can also store environment mappings and templates.
- "How do we separate build and run?" -> build artifacts once, then promote.
- "How should logs be handled?" -> treat as streams, not files.

## Principle Snapshots

- Codebase: one repo, many deploys.
- Dependencies: explicit and isolated.
- Config: stored in environment.
- Backing services: attachable resources.
- Build, release, run: strict separation.
- Processes: stateless, share-nothing.
- Port binding: export services via ports.
- Concurrency: scale via process model.
- Disposability: fast startup, clean shutdown.
- Dev/prod parity: keep environments similar.
- Logs: event streams.
- Admin processes: run as one-offs.

## dev.kit Notes

- Prefer runtime config under `~/.udx/dev.kit/state` for mutable state.
- Keep env mapping templates in repo when needed.
- Separate template rendering from execution.

## Sources

- https://12factor.net/
- https://udx.io/devops-manual/12-factor-environment-automation
