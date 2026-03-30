# Detection Facets

`dev.kit` now exposes coarse, integration-friendly facets in both `explore --json` and `action --json`.

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

## Reading Priority

For repo exploration and agent grounding, `dev.kit` should prefer standard engineering refs before anything custom:

1. `README.md` or `readme.md`
2. `docs/`
3. workflow and delivery contracts such as `.github/workflows/`, `.rabbit/`, `deploy.yml`, and `Makefile`
4. runtime and dependency contracts such as `package.json`, `composer.json`, and `Dockerfile`
5. framework-specific roots such as `wp-config.php` and `wp-content/`

Typical WordPress repos at UDX often share most of their structure, with the most important repo-specific differences concentrated in `.rabbit/` and `.github/`. Other repo families follow the same principle less uniformly, so `dev.kit` should still inspect repo-standard files such as `package.json`, `deploy.yml`, `Makefile`, `docs/`, and `README.md`.

## Extension Rules

- Add new file and directory signals in `src/configs/detection-signals.yaml` or `src/configs/archetype-signals.yaml`.
- Add new content patterns in `src/configs/detection-patterns.yaml`.
- Prefer coarse facets over highly specific one-off labels.
- Keep archetypes high-level and let facets explain why an archetype matched.
