# Runtime Layout

dev.kit stores its installed engine and runtime state under a single root to
keep cleanup and upgrades predictable.

## Default root

`~/.udx/dev.kit/`

## Structure

```
~/.udx/dev.kit/
  source/       # installed dev.kit engine (snapshot)
  state/        # runtime state (mutable)
    codex/
      workflows/<repo-id>/...
      tasks/<repo-id>/...
      logs/<repo-id>/
        exec-<timestamp>.log
        exec-<timestamp>.prompt.md
        exec-<timestamp>.request.txt
        exec-<timestamp>.result.md
        exec-<timestamp>.meta
    capture/<repo-id>/...
    cache/
```

## Repo-local overrides

Some features use a repo-local store when `capture.mode=repo` or when a repo
explicitly opts in:

```
<repo>/.udx/dev.kit/config.env
<repo>/.udx/dev.kit/capture/
```

## Environment variables

- `DEV_KIT_HOME` (default: `~/.udx/dev.kit`)
- `DEV_KIT_SOURCE` (default: `~/.udx/dev.kit/source`)
- `DEV_KIT_STATE` (default: `~/.udx/dev.kit/state`)
- `DEV_KIT_CONFIG` (default: `$DEV_KIT_STATE/config.env`)

If `source/` or `state/` is missing, dev.kit falls back to legacy paths under
`DEV_KIT_HOME`.

## Config key

- `state_path` overrides the runtime state directory.
  Example: `dev.kit config set --key state_path --value "~/.udx/dev.kit/.state"`
