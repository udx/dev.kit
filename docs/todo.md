# TODO

## Audit Model

- tighten factor-specific evidence so architecture, runtime, and config do not bleed into each other
- add architecture checks for oversized command files and oversized modules in scanned repos beyond the current shell-first heuristics
- detect explicit deployment contracts and CI workflow contracts more deeply, not only via filenames and documented commands
- extend architecture detection for more stacks and conventions without collapsing back into hardcoded language logic

## Bridge Model

- expose more explicit engineering-contract guidance for agents, including preferred edit boundaries and validation order
- add machine-readable improvement priority or severity so agents can plan fixes more predictably
- improve CLI and output UI so factor status, evidence, and guidance are easier to scan quickly

## Validation

- add worker-backed fixture coverage for architecture edge cases
- add fixtures for larger application layouts and infra-heavy repos
- add checks for repos that document commands but do not actually expose them
- make git hooks fail more gracefully when local prerequisites such as Docker are unavailable, while keeping the enforcement intent clear

## Docs

- keep the README short and product-facing as the CLI model evolves
- keep the engineering guide aligned with what `dev.kit` can actually validate
