# Development

## Test

Canonical verification runs in the preconfigured worker container:

```bash
bash tests/run.sh
```

## Notes

- `bash tests/run.sh` uses [deploy.yml](/Users/jonyfq/git/udx/dev.kit/deploy.yml) with the globally installed `worker` CLI.
- The suite validates install, env setup, dynamic command discovery, Bash completion, and uninstall in a fresh temporary `HOME`.
