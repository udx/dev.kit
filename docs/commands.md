# Commands

## Core Commands

`dev.kit explore`

- Best first step when entering a repo.
- Reports repo identity, priority refs, operating surface, knowledge sources, and typical workflows.

`dev.kit`

- Audits the repo against workflow factors such as documentation, architecture, config, verification, runtime, and build/run separation.
- Returns improvement guidance in text or JSON.

`dev.kit bridge --json`

- Produces the AI-facing connector for the same repo model.
- Keeps agents grounded in standard repo evidence rather than inferred habits.

## Workflow Commands

`dev.kit sync`

- Evaluates predefined Git workflows.
- Shows text summaries by default and full step detail in JSON.
- Intended to stay evaluation-oriented until deterministic automation is ready.

`dev.kit learn`

- Evaluates lessons-learned workflows for recent PRs.
- Keeps destinations such as GitHub issues, wiki pages, or Slack summaries explicit and schema-driven.

## Continuity Commands

`dev.kit save`

- Writes optional repo-local continuity files under `./.udx/dev.kit/`.
- Useful for long-lived work, but not required for `dev.kit` to understand a repo.

`dev.kit status`

- Reports local installation state.

`dev.kit uninstall`

- Removes the local install.
