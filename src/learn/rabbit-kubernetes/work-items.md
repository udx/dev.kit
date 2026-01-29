# Work items

## Default flow
1) Confirm scope and source of truth.
2) Find the config paths and read current state.
3) Implement scripts first, then docs, then reports.
4) Run scripts with read-only checks before enforcement.
5) Commit small, cohesive changes.

## IAM changes
- Define required inputs (project id, namespace).
- Decide what is positional vs env.
- Implement script to enforce config.
- Implement report script to audit config.
- Document manual steps + script usage.

## Reviews
- Check for required inputs and defaults.
- Confirm script names and doc references match.
- Ensure report output is in docs.
