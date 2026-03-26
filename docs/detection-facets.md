# Detection Facets

`dev.kit` now exposes coarse, integration-friendly facets in both `audit --json` and `bridge --json`.

The current design goal is stability, not exhaustiveness. Facets should describe durable repo traits that are cheap to detect and useful for automation.

## Current Facets

- `framework:wordpress`
- `platform:kubernetes`
- `runtime:container`
- `workflow:github`
- `repo:workflow-primary`
- `workload:automation`
- `package:node`
- `package:composer`
- `deploy:worker-config`
- `deploy:terraform`
- `deploy:kubernetes-manifests`
- `lifecycle:build`
- `lifecycle:runtime`
- `lifecycle:deploy`

## Detection Phases

`dev.kit` should detect repo identity with the cheapest signals first:

1. Root files and well-known top-level directories
2. Small targeted manifests such as workflow files and deploy configs
3. Broader glob scans only when the repo is still ambiguous

Generated and dependency-heavy directories are pruned by default to keep detection interactive.

## Extension Rules

- Add new file and directory signals in `src/configs/detection-signals.yaml` or `src/configs/archetype-signals.yaml`.
- Add new content patterns in `src/configs/detection-patterns.yaml`.
- Prefer coarse facets over highly specific one-off labels.
- Keep archetypes high-level and let facets explain why an archetype matched.
