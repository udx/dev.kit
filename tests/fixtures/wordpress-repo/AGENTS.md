# AGENTS.md

> Start with `.rabbit/context.yaml` for full repo context. Run `dev.kit repo` to refresh.

## wordpress-repo

WordPress website — application code, theme, and plugin assets deployed to a WordPress host

## Start here

- ./.rabbit/context.yaml
- ./README.md
- ./.rabbit/infra_configs
- ./.rabbit
- ./.github/workflows
- ./package.json

## Commands

- **verify**: `npm test`

## Gaps

- **architecture** (partial) — Some architectural boundaries are visible, but the repository structure is not fully normalized yet. Separate commands, modules, templates, and config more explicitly.
- **config** (missing) — Externalize configuration and document the environment contract so the repo can move cleanly across environments.

## Workflow

- Read the highest-priority repo refs first: ./.rabbit/context.yaml, ./README.md, ./.rabbit/infra_configs, ./.rabbit, ./.github/workflows, ./package.json, ./wp-config.php, /Users/jonyfq/git/udx/dev.kit/.github/ISSUE_TEMPLATE, /Users/jonyfq/git/udx/dev.kit/.github/PULL_REQUEST_TEMPLATE.md, /Users/jonyfq/git/udx/dev.kit/src/configs/github-issues.yaml, /Users/jonyfq/git/udx/dev.kit/src/configs/github-prs.yaml
- Run the canonical verification command: `npm test`
- Review lessons-learned and follow-up outputs after changes stabilize: `dev.kit learn`

