<img src="assets/logo.svg">

[![License](https://img.shields.io/github/license/udx/worker.svg)](LICENSE) [![Documentation](https://img.shields.io/badge/docs-dev.kit-blue.svg)](./docs/)

Engineering kit for bootstrapping and orchestrating developer workflows. Designed for deterministic execution and a standardized knowledge base.

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

Start here:
- `docs/index.md`
- `docs/execution/iteration-loop.md`
- `docs/execution/subtask-loop.md`
- `skills/iteration.md`

How to run review iteration:
- `scripts/review-docs.sh`
- VS Code tasks (see `scripts/` for entry points)

Repo map:
| Area | Meaning |
| --- | --- |
| `bin/` | Product runtime CLI entrypoints (current). |
| `lib/` | Product runtime library code (current). |
| `src/` | Product runtime source (current). |
| `config/` | Product runtime configuration (current). |
| `docs/` | Spec kernel: design, contracts, and canonical repo interfaces. |
| `workflows/` | Workflow artifacts and runbooks. |
| `prompts/` | Iteration prompts and review inputs. |
| `scripts/` | Iteration tooling (review/apply helpers). |
| `templates/` | Reusable templates (docker, mermaid). |
| `schemas/` | JSON/YAML/MD schemas. |
| `assets/` | Diagrams, fixtures, and artifacts. |
| `tasks/` | Subtask loop directories (prompt/feedback). |
| `skills/` | Iteration skill contracts and workflow specs. |

Legacy:
- Legacy tree has been removed; see `docs/legacy-retirement.md` for provenance.
