# Workflow Step Gates

This document defines when a workflow step should be extracted into a child workflow.

## Extraction Gate

Use this checklist for any workflow step:

- Reused in more than one workflow? yes/no
- More than 3 sub-steps? yes/no
- Needs independent validation? yes/no
- Exceeds bounded-work limits (steps/files/new files/moves)? yes/no

If 2 or more are "yes", extract to a child workflow.
Child workflows are created only when the parent step is iterated; during root workflow creation, reference the intended child path.

## Inline Gate

Keep the step inline when:

- The step is one-off or single-use.
- The step has 3 or fewer sub-steps.
- The step does not require separate validation or rollback.

## Step Metadata Requirements

- Each step must include `done: false|true`.
- Workflow must include bounded-work metadata; prefer `manifests/workflow-template.md` as the baseline.
