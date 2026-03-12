# Development

## Test

Canonical verification runs in the preconfigured worker container:

```bash
bash tests/run.sh
```

## Notes

- `bash tests/run.sh` uses [deploy.yml](/Users/jonyfq/git/udx/dev.kit/deploy.yml) with the globally installed `worker` CLI.
- The suite validates install, env setup, dynamic command discovery, Bash completion, and uninstall in a fresh temporary `HOME`.

## Git Rules

This repo keeps Git policy minimal and programmatic:

- tracked line-ending rules live in [.gitattributes](/Users/jonyfq/git/udx/dev.kit/.gitattributes)
- an optional tracked hook enforces lowercase commit subjects from [.githooks/commit-msg](/Users/jonyfq/git/udx/dev.kit/.githooks/commit-msg)

Enable the tracked hooks once per clone:

```bash
git config core.hooksPath .githooks
```

The commit hook allows Git-generated subjects such as `Merge`, `Revert`, `fixup!`, and `squash!`, but otherwise rejects uppercase letters in the first commit line.
