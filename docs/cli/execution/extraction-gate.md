# Extraction Gate

Domain: Execution

## Purpose

Decide when a workflow step should become a child workflow.

## Gate Questions

Answer yes or no for each. If two or more answers are yes, extract the step.

1. The step requires multiple sub-steps with different inputs or tools.
2. The step is reusable across workflows or projects.
3. The step changes multiple files or touches multiple domains.
4. The step needs a plan, verification, or fallback logic of its own.
5. The step depends on external state (network, system config, environment).

## Rule

If 2+ answers are yes, create a child workflow and reference it from the
parent step.
