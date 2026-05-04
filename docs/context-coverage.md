# Context Coverage

`.rabbit/context.yaml` is the structured coverage report for the repository.

It should answer three questions:

1. what did `dev.kit` detect?
2. what can be serialized cleanly?
3. what is still missing or only partial?

## What It Covers

`context.yaml` is for facts and deterministic transforms built from repo signals.

Typical sections include:

- repo identity
- direct-read refs
- detected verify, build, and run commands with source hints
- structured gaps with factor, status, message, and evidence
- manifests as structured entries
- dependencies

Depending on the repo and environment, it may also include live repo experience that can be serialized safely.
Dynamic GitHub state such as issues, pull requests, reviews, workflow runs, and alerts is intentionally not serialized. Agents should fetch those live with `gh` when the current task needs them.

This is important: `context.yaml` is not trying to be a complete narrative. It is trying to be a usable contract with explicit coverage boundaries.

## What Gaps Mean

`gaps` is not a generic TODO list. It is the set of engineering factors that `dev.kit` could not confirm fully from the available signals.

That means a gap can represent:

- something missing
- something incomplete
- something present but too thin to treat as strong coverage

Each gap entry should say:

- which factor is weak
- whether it is `missing` or `partial`
- the current message for that condition
- the observed evidence that led to that result

This is why context coverage testing should include broken or degraded repos, not only healthy ones.

## Gap Repair Loop

Gaps are meant to drive a repair loop:

1. read the gap and its evidence
2. identify the repo-owned source asset that should carry that contract
3. patch that source asset instead of editing generated output
4. rerun `dev.kit repo`
5. confirm that the regenerated context improved

That means gaps are part of maximum context discovery, not just an error report.

## What Does Not Belong There

`context.yaml` should not become a prompt or a workflow script.

It is not the right place for:

- agent behavior rules
- long-form operating guidance
- issue or PR handling advice
- subjective reasoning about what an agent should do next
- local-only lesson artifacts

Those belong in `AGENTS.md`.

## Coverage Strategy

The coverage model is repo-first:

- read README, docs, manifests, workflows, tests, and deploy config
- detect commands and factor signals
- trace deterministic dependencies
- report gaps where coverage is weak

That keeps `context.yaml` useful both for healthy repos and for repos that need cleanup.

The measure of success is not perfect inference. It is:

- strong traceability where possible
- explicit unknowns where not
- a clear path to improve repo coverage over time
