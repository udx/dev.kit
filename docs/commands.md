# Commands

## Core Commands

`dev.kit explore`

- Best first step when entering a repo.
- Reports repo identity, priority refs, source chain, knowledge sources, and workflow contract.

`dev.kit action`

- Produces grounded next actions for humans and agents from the same repo model.
- Combines factor findings, workflow contract, git workflow state, and agent guidance.
- Supports `--json`.

`dev.kit learn`

- Evaluates lessons-learned workflows for recent PRs.
- Keeps destinations such as GitHub issues, wiki pages, or Slack summaries explicit and schema-driven.

`dev.kit uninstall`

- Removes the local install.
