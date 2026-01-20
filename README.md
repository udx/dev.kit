# dev.kit

Engineering kit for bootstrapping and orchestrating developer workflows. Can be integrated with AI CLI (Codex|Claude|Gemini) for automated execution and a standardized knowledge base.

Why use it:
- Consistent entrypoint for local workflows.
- Explicit, reversible setup with minimal shell edits.
- Safe, discoverable automation for humans and AI.

Install:
curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/main/bin/scripts/install.sh | bash

Enable:
dev.kit enable --shell=bash   # or --shell=zsh

Flow:
- Install creates `~/.udx/dev.kit/` and drops env/config there.
- Enable opts into auto-init for new shells (and loads autocomplete).
- Each session prints

```
> dev.kit: active
> Run `dev.kit` to start
```

Docs:
- `docs/index.md` (entry point)
- `docs/overview.md` (short guide)
- `docs/concepts/devsecops-demo.md` (team demo)
