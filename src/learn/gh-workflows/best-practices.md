# Best practices

## Docs
- Scope is explicit and narrow.
- Required inputs are positional; defaults only when stable.
- Manual steps + script usage + verification.

## Scripts
- Bash only; `set -euo pipefail`.
- Validate dependencies early.
- Deterministic output; minimal side effects.

## Reports
- Read from a single source of truth.
- Include generated timestamp + source path.
- Markdown tables for scanability.

## 2026-01-28
- When adding workflow inputs, ensure the step producing outputs has an `id` and that docs/examples are updated in the same change.
- Document default behavior (e.g., `latest`) and include a pinning snippet for specific versions.
