# Smart Dependency Detection

`dev.kit repo` does more than list local files. It also traces dependencies that shape how the repo really works.

## What It Detects

Cross-repo tracing currently covers sources such as:

- reusable GitHub workflows
- GitHub actions
- Docker images
- versioned YAML references
- GitHub URLs
- npm packages

These are then mapped into dependency entries in `.rabbit/context.yaml`.

## Resolution Model

The tracing model is deterministic.

If `dev.kit` can resolve a dependency confidently, it records:

- the dependency target
- its type
- whether it was resolved
- where it is used in the current repo

When possible, same-org dependencies are resolved from current GitHub metadata and local sibling repos. Docker images may also be mapped back to likely source repos.

## Why It Matters

This is what makes `context.yaml` more useful than a plain file inventory.

A repo often depends on workflows, images, or external modules that live elsewhere. If those relationships are visible in the generated contract, an agent can trace execution paths faster and with less guesswork.

## Coverage Limits

Dependency detection still follows the same rule as the rest of `dev.kit`: report what can actually be observed.

If a dependency cannot be resolved confidently from the available repo and environment signals, it should remain partial rather than be invented.
