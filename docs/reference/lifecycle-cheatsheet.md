# Lifecycle Cheatsheet

## Summary

Lifecycle practices that reduce production risk and keep delivery predictable. Focused on release flow, environment coordination, and operational safety.

## When To Use

- Defining install/upgrade flows.
- Designing release pipelines and migration steps.
- Aligning environment responsibilities.

## Quick Answers

- "Should we automate this?" -> start manual, then automate once stable.
- "Who owns this step?" -> assign explicit owner per stage.
- "How do we manage env vars?" -> define ownership and enforce in pipeline.

## Core Practices

- Test in multiple environments before production.
- Use orchestration to sequence lifecycle steps.
- Treat environment variables as part of release pipeline.
- Ensure app knows its environment identity.
- Plan migrations and rollbacks before deployment.
- Rotate certificates on a schedule.
- Make security a lifecycle requirement.

## dev.kit Notes

- Treat install/upgrade as explicit lifecycle steps.
- Encode migrations in workflows, not in ad-hoc steps.

## Practical Checks

- Can a release be promoted without manual edits?
- Are migrations and rollbacks written before deploy?
- Is environment identity explicit at runtime?

## Source

- https://andypotanin.com/developing-lifecycles-a-comprehensive-cheatsheet/
