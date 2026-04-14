# Detection Facets

`dev.kit` exposes coarse, integration-friendly facets in `dev.kit repo --json` and `dev.kit agent --json`.

The current design goal is stability, not exhaustiveness. Facets should describe durable repo traits that are cheap to detect and useful for automation.

## Current Facets

- `framework:wordpress`
- `platform:kubernetes`
- `runtime:container`
- `workflow:github`
- `repo:workflow-primary`
- `package:node`
- `package:composer`
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

## Key Distinctions

- `deploy:terraform` fires when `.tf` files or a `terraform/` directory exist — regardless of whether Kubernetes manifests are also present.
- `platform:kubernetes` requires actual K8s manifests (`k8s/*.yaml`, `Chart.yaml`, `helmfile.yaml`) or Helm chart directories. Terraform alone does not imply Kubernetes.
- `repo:workflow-primary` fires when `action.yml`/`action.yaml` is present at the root, or when GitHub workflows are the only primary artifact (no app code, no K8s manifests, no package.json).

## Reading Priority

For repo exploration and agent grounding, `dev.kit` should prefer standard engineering refs before anything custom:

1. `README.md` or `readme.md`
2. `docs/`
3. workflow and delivery contracts such as `.github/workflows/`, `.rabbit/`, `deploy.yml`, and `Makefile`
4. runtime and dependency contracts such as `package.json`, `composer.json`, and `Dockerfile`
5. framework-specific roots such as `wp-config.php` and `wp-content/`

## Extension Rules

- Add new file and directory signals in `src/configs/detection-signals.yaml` or `src/configs/archetype-signals.yaml`.
- Add new content patterns in `src/configs/detection-patterns.yaml`.
- Prefer coarse facets over highly specific one-off labels.
- Keep archetypes high-level and let facets explain why an archetype matched.
