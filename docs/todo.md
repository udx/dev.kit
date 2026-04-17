# dev.kit improvement backlog

## Product direction

- [ ] Keep `dev.kit` centered on GitHub-first development and agent execution.
- [ ] Make the session contract explicit: each work session should start with `dev.kit`, `dev.kit repo`, and `dev.kit agent`, then continue from `context.yaml` and `AGENTS.md`.
- [ ] Keep the product simple. `dev.kit` should stay middleware between repo-declared context and live GitHub experience, not a second workflow system.

## GitHub pattern reuse

- [ ] Generate branch names from current repo naming patterns.
- [ ] Generate PR titles and descriptions from recent repo PR style and structure.
- [ ] Generate issue titles and descriptions from recent repo issue style and structure.
- [ ] Generate issue and PR comments from existing repo follow-up and close-out patterns.

## Review and verification loop

- [ ] Make bot-review handling explicit: read feedback from Copilot, CodeQL, Devin, and similar reviewers, fix or reply, then resolve threads.
- [ ] Make workflow monitoring explicit: inspect related GitHub workflow runs after pushes and use failures as a fix loop, not just a status badge.
- [ ] Keep local verification scoped and lightweight when GitHub workflows already provide the primary verification surface.

## History-aware debugging

- [ ] When debugging, use related issues, PRs, and commit history to understand prior changes and possible regressions before inventing a new theory.
- [ ] Use the linked GitHub issue as the cross-repo context root when work spans multiple repos.

## Why this matters

`dev.kit` should keep reminding agents to use dev, team, and org experience from GitHub repos as part of the actual work loop. It should also surface repo gaps and push that learning back into repo contracts so the next session starts from better context.
