# AGENTS.md

> Start with `.rabbit/context.yaml` for full repo context. Run `dev.kit repo` to refresh.

## docker-repo

Container image — a Dockerfile-based service built and published as a container image

## Start here

- ./.rabbit/context.yaml
- ./README.md
- ./.rabbit
- ./Makefile
- ./Dockerfile
- ./deploy.yml

## Commands

- **verify**: `make test`
- **build**: `make build`
- **run**: `make run`

## Gaps

- **dependencies** (partial) — Runtime signals exist, but the dependency contract is incomplete. Prefer an explicit language or package manifest over container-only dependency discovery.
- **config** (partial) — Config signals exist, but the environment contract is only partially documented. Add an example env file or clearer config documentation.

## Workflow

- Read the highest-priority repo refs first: ./.rabbit/context.yaml, ./README.md, ./.rabbit, ./Makefile, ./Dockerfile, ./deploy.yml, ./lib, ./src, /Users/jonyfq/git/udx/dev.kit/.github/ISSUE_TEMPLATE, /Users/jonyfq/git/udx/dev.kit/.github/PULL_REQUEST_TEMPLATE.md, /Users/jonyfq/git/udx/dev.kit/src/configs/github-issues.yaml, /Users/jonyfq/git/udx/dev.kit/src/configs/github-prs.yaml
- Run the canonical verification command: `make test`
- Run the canonical build command when needed: `make build`
- Use the canonical runtime command instead of ad hoc startup paths: `make run`
- Review lessons-learned and follow-up outputs after changes stabilize: `dev.kit learn`

