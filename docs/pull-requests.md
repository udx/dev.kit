# Pull Requests

This document is specifically about PR quality and review shape. It is intentionally narrower than the overall workflow or engineering guide.

Useful pull requests are not just code dumps. They explain the operational change clearly enough that reviewers, CI, and future agents can understand what changed and why.

## What Good PRs Should Do

- state the problem first
- summarize the actual change in a short `Changes` section
- describe the real diff between the base branch and the PR branch, not the idealized change you wish the branch contained
- keep the scope coherent instead of mixing unrelated work
- start from a branch that is reasonably fresh against the target base branch
- include docs or examples when behavior or workflow changes
- give reviewers enough runtime or config context to validate the change

## Preferred Shape

Use a structure like this:

```md
## Problem

What is broken, drifting, risky, or unclear?

## Changes

- concrete change 1
- concrete change 2
- concrete change 3

## Validation

- command or workflow used to verify
- relevant environment or scenario notes

## Related

- issue, incident, or follow-up links
```

If screenshots, logs, or runtime traces make the problem clearer, include them. Use them to support the explanation, not replace it.

## What The Example PRs Do Well

Reference examples:

- `udx/worker-site#76`
- `udx/worker#117`
- `udx/worker#113`

Patterns worth repeating from those PRs:

- they explain the problem in operational terms, not only code terms
- they keep the change list concrete and scannable
- they connect config, runtime, and dependency updates instead of pretending the code changed in isolation
- they include documentation updates when workflow or behavior changes
- they show real scenarios or examples when precedence, secrets, or runtime behavior is subtle

## PR Rules

- keep one PR focused on one logical improvement area
- do not open a PR from a long-lived catch-all branch if the work can still be split or rebased cleanly
- if the change has multiple logical parts, use separate commits with clean commit subjects
- include docs updates when the engineering contract changes
- prefer reproducible validation over “tested locally” statements
- do not hide important behavior changes inside dependency bump PRs without explaining the behavioral reason

## Branch Hygiene

PR quality starts before the PR body is written.

- sync with the target base branch before starting or resuming work
- avoid stacking unrelated work on one long-lived branch
- if the branch already accumulated mixed history, split it before review when practical
- if splitting is not practical, be explicit in the PR body that the PR is cumulative and group the changes honestly

A good PR body cannot rescue a bad branch shape. It can only make the review less painful.

## Anti-Patterns

- vague titles that do not describe the operational change
- large mixed PRs with unrelated fixes
- no explanation of config or runtime impact
- no validation notes for behavior-sensitive changes
- missing docs when commands, structure, or workflow expectations changed

## How This Fits `dev.kit`

`dev.kit` should eventually validate more of this automatically:

- whether workflow-affecting changes also updated docs
- whether architecture or config contracts changed without explanation
- whether PR-sized changes stay aligned with the repo's engineering guide
