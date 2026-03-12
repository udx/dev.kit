# Team Workflow

This repo treats development workflow as part of the operating contract.

The goal is simple: start from current repo reality, keep changes verifiable while you work, and always leave the branch in a recoverable state.

## Start of Session

Before continuing work:

```bash
git status
git pull --ff-only
```

Then align your branch with the current base branch for the repo:

```bash
git merge origin/main
```

If the repo uses a different base branch such as `staging`, merge that branch instead.

## During Work

- keep changes scoped so verification and review stay clear
- prefer the repo's canonical commands over ad hoc local habits
- use `dev.kit` when build, test, config, or runtime expectations are unclear
- use `dev.kit bridge --json` when an agent needs grounded repo context

## End of Session

Before stopping work:

- commit your current state, even if the work is partial
- push the branch so CI and PR protection can validate it
- leave enough context in the branch and commit history that tomorrow starts from facts, not memory

This reduces hidden local progress and protects the rest of the team from drift.

## Hooked Enforcement

Tracked Git hooks are optional but recommended for this repo:

```bash
git config core.hooksPath .githooks
```

Current hooks:

- `commit-msg`: rejects uppercase commit subjects, except Git-generated subjects such as `Merge`, `Revert`, `fixup!`, and `squash!`
- `pre-push`: runs `bash tests/run.sh` before push

Hooks should enforce only deterministic local checks. Team habits such as morning branch sync are documented here rather than hard-blocked.
