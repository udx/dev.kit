# Development

This document is for working on the `dev.kit` codebase itself. For product behavior and repo workflow concepts, start with [docs/overview.md](/Users/jonyfq/git/udx/dev.kit/docs/overview.md) and [docs/workflow.md](/Users/jonyfq/git/udx/dev.kit/docs/workflow.md).

## Test

Use focused verification first:

```bash
bash tests/smoke.sh
```

Use the broader worker-backed run when needed:

```bash
bash tests/run.sh
```

## Notes

- `bash tests/smoke.sh` is the preferred default during normal development.
- `bash tests/run.sh` uses [deploy.yml](/Users/jonyfq/git/udx/dev.kit/deploy.yml) with the globally installed `worker` CLI.
- The suite validates install, env setup, dynamic command discovery, Bash completion, and uninstall in a fresh temporary `HOME`.

## Git Rules

This repo keeps Git policy minimal and programmatic:

- tracked line-ending rules live in [.gitattributes](/Users/jonyfq/git/udx/dev.kit/.gitattributes)
- optional tracked hooks live in [.githooks](/Users/jonyfq/git/udx/dev.kit/.githooks)

Enable the tracked hooks once per clone:

```bash
git config core.hooksPath .githooks
```

Current hooks:

- [commit-msg](/Users/jonyfq/git/udx/dev.kit/.githooks/commit-msg) enforces lowercase commit subjects, excluding Git-generated subjects such as `Merge`, `Revert`, `fixup!`, and `squash!`
- [pre-push](/Users/jonyfq/git/udx/dev.kit/.githooks/pre-push) runs `bash tests/run.sh`

Broader engineering expectations are documented in [docs/engineering-guide.md](/Users/jonyfq/git/udx/dev.kit/docs/engineering-guide.md).
