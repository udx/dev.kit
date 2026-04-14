# Lessons — dev.kit — 2026-04-14

Sources: claude (1 session(s)), codex (0 session(s))

## Workflow rules

- Verify the build or runtime locally before running deploy-oriented workflow assets or reporting the change as complete.
- Use repo workflow assets like deploy.yml, workflow files, and repo docs as the execution contract instead of inventing an ad hoc deploy path.
- Keep the delivery chain explicit: create or sync the branch, prepare the PR, and connect the related GitHub issue before close-out.
- Report outcomes with exact URLs, versions, findings deltas, and next steps so the follow-up can be reused by humans and agents without drift.
- Use README, docs, and tests as the first alignment surface before broad refactors so the implementation stays anchored to an explicit workflow.
- Keep local verification targeted and lightweight during iteration, then move broader or slower validation into GitHub Actions or other CI gates.
- Treat cleanup of legacy modules, configs, and leftovers as part of the feature work so the repo keeps converging on the new operating model.
- Prefer reusable YAML/manifests plus small shell wrappers over embedding policy directly into imperative scripts.
- Package agent context from repo artifacts and manifests so the workflow stays repo-centric and does not depend on ad hoc prompt memory.

## Operational references

- https://github.com/icamiami/icamiami.org/issues/1897
- https://github.com/test/repo/issues/42
- https://github.com/org/repo/issues/42
- https://github.com/udx/next.reddoorcompany.com/issues/1292
- https://github.com/udx/next.reddoorcompany.com/issues/1250
- https://github.com/icamiami/icamiami.org/issues/1895
- https://github.com/udx/next.reddoorcompany.com/issues/1299
- https://github.com/udx/worker-tooling/pull/57
- https://github.com/udx/dev.kit/pull/10
- https://github.com/udx/dev.kit/pull/11
- https://github.com/org/repo/pull/15
- https://github.com/test/repo/pull/5
- https://github.com/udx/next.reddoorcompany.com/pull/1298
- https://github.com/icamiami/gala-2024.icamiami.org/pull/6
- https://github.com/udx/rabbit-automation-action/pull/231
- https://github.com/udx/next.reddoorcompany.com/pull/1301
- https://github.com/udx/api.encerp.com/pull/197
- https://github.com/test/repo/pull/9
- https://github.com/udx/worker-engine/pull/83
- https://github.com/udx/reusable-workflows/pull/32
- https://github.com/udx/azure-apim-backup/issues/81

## Ready templates

- `Issue-to-scope`: start from the linked issue, confirm repo/workspace match, and restate the exact scope before changing code.
- `Workflow tracing`: locate the actual workflow file or deploy source first, then trace the commands and supporting docs that really drive execution.
- `Verify-before-sync`: run the relevant local build/test check before syncing, reporting completion, or preparing the PR.
- `Delivery chain`: sync the branch, prepare the PR in repo style, and connect the related issue before close-out.
- `Post-merge follow-up`: gather release/workflow evidence and post a concise update with links, findings delta, and next steps.
- `Docs-first cleanup loop`: review README/docs/tests, restate the target workflow, then simplify code and remove mismatched legacy paths in the same pass.
- `Verification scope`: run the smallest local check that proves the current change, defer heavyweight smoke coverage to CI, and call that tradeoff out explicitly.
- `Legacy reduction`: when a new direction is accepted, archive or delete conflicting old modules/configs instead of carrying both models forward.
- `Config-over-code`: express repo rules in YAML/manifests first, then keep shell glue thin and composable.
- `Agent handoff`: refresh repo context, manifest, and AGENTS instructions before deeper agent work so the repo contract is the source of truth.

## Evidence highlights

- [claude] I'm planning refactoring/re-thinking my dev.kit tool, please explore it, get familiar and validate againts my new plan [Pasted text #1 +69 lines]
- [claude] ok, let's start phase 1, break into smaller iterations if make sense, I would probably start by readme/docs, tests and basic scripts end goal is to have smart and flexible development workflow that helps improve local env, repo(s), and provide context for claud agent so no engineering drift happening and development...
- [claude] before running test we need to ensure perfomance and make sure it's not running too long, also, I see you haven't updated Readme fully, let's loop once again readme/docs, tests feel free to cleanup/consolidate/whatever, it's a first version so nobody using it so no back-compability needed
- [claude] when I said about perfomance I particularly meant tests
- [claude] so, do we understand "happy path" for refactor to new concept? [Pasted text #1 +69 lines]

