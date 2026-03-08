# Software Supply Chain Security

## Summary

Supply chain security focuses on protecting dependencies, build pipelines, and release artifacts. The goal is to reduce hidden risk from third-party code and automated systems.

## When To Use

- Reviewing dependency policy.
- Designing build and release pipelines.
- Auditing artifact integrity.

## Quick Answers

- "How do we trust dependencies?" -> pin, verify, and monitor.
- "How do we trust artifacts?" -> sign and verify releases.
- "What is the minimum baseline?" -> SBOM, integrity checks, restricted builds.

## Baseline Controls

- Pin and verify dependencies with integrity metadata.
- Use SBOMs for visibility and audits.
- Restrict build permissions and isolate build environments.
- Sign and verify artifacts before deployment.
- Monitor upstream package changes.

## dev.kit Notes

- Prefer deterministic builds and pinned dependencies in tooling.
- Keep build outputs in state, not in source.

## Practical Checks

- Can you trace a release artifact to its sources?
- Are builds reproducible in isolated environments?
- Are deployment artifacts signed and verified?

## Source

- https://andypotanin.com/software-supply-chain-security/
