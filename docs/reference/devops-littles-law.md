# Little's Law for DevOps

## Summary

Little's Law connects WIP, throughput, and cycle time. Use it to reason about delivery flow and why too much parallel work slows shipping.

## When To Use

- Tuning delivery flow and team throughput.
- Explaining why WIP caps matter.
- Evaluating bottlenecks.

## Quick Answers

- "Why are we slow?" -> too much WIP or a bottleneck.
- "How do we shorten cycle time?" -> reduce WIP and queue time.
- "How do we increase throughput?" -> fix the bottleneck, not just add work.

## Core Model

- WIP = Throughput x Cycle Time

## Practical Moves

- Cap WIP per stage.
- Track cycle time distribution, not just averages.
- Reduce context switching.
- Identify and relieve bottlenecks.

## dev.kit Notes

- Keep workflows bounded to reduce WIP per task.
- Prefer smaller, reviewable changes.

## Source

- https://andypotanin.com/littles-law-applied-to-devops/
