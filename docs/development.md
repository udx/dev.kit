# Development

This document is for working on the `dev.kit` codebase itself. For product behavior and repo workflow concepts, start with [docs/overview.md](/Users/jonyfq/git/udx/dev.kit/docs/overview.md) and [docs/workflow.md](/Users/jonyfq/git/udx/dev.kit/docs/workflow.md).

## Test

Use focused verification first:

```bash
bash tests/smoke.sh --only explore,action
```

Use the broader worker-backed run when needed:

```bash
bash tests/run.sh
```

Use the real local repo sweep when you want to pressure-test `dev.kit` against actual `git/udx/*` repos:

```bash
bash tests/local-udx.sh
DEV_KIT_LOCAL_REPOS_MAX=10 bash tests/local-udx.sh
DEV_KIT_LOCAL_REPOS_ONLY=dev.kit,www.peakclt.com bash tests/local-udx.sh
DEV_KIT_LOCAL_REPOS_COMMANDS=explore bash tests/local-udx.sh
DEV_KIT_LOCAL_REPOS_ONLY=www.peakclt.com DEV_KIT_LOCAL_REPOS_COMMANDS=action bash tests/local-udx.sh
DEV_KIT_LOCAL_REPOS_FAIL_ON_WEAK=1 bash tests/local-udx.sh
```

## Notes

- `bash tests/smoke.sh` is the preferred default during normal development.
- `bash tests/local-udx.sh` is a JSON-aware scored sweep over real `git/udx/*` repos. It should record weak contracts without failing the entire run unless command output breaks or `DEV_KIT_LOCAL_REPOS_FAIL_ON_WEAK=1` is set.
- Prefer `DEV_KIT_LOCAL_REPOS_COMMANDS=explore` or `DEV_KIT_LOCAL_REPOS_COMMANDS=action` when working on one command path.
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
