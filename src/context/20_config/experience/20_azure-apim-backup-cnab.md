# Azure APIM Backup CNAB Release

Team: Jony Fq (Human) + Codex CLI (AI)
Repo: udx/azure-apim-backup (product) + udx/worker-cnab (tooling)
Standard: Context-Driven Engineering (CDE)

## Team Context

- Jony Fq (Human): Product engineer driving Azure Marketplace release and CNAB packaging.
- Codex CLI (AI): Troubleshooting, scripting, and release pipeline alignment.

## Repository Context

- Product repo holds CNAB assets under `ci/configs/cnab` and the Marketplace manifest.
- Worker repo provides a consistent toolchain for Porter/ORAS and publish scripts.
- Release workflow relies on the worker container for deterministic packaging.

## Design Context: CNAB Assets and Schema Alignment

Objective: Ensure Marketplace-required fields (`clusterArmTemplate`, `uiDefinition`) are populated and validated in the published CNAB config.

Design characteristics:
- Keep offer-specific assets in the product repo; keep tooling in the worker image.
- Inject base64 content into `porter.yaml` at build time, not as committed data.
- Validate published CNAB config payloads with ORAS before Marketplace submission.

Concrete design decisions:
- Use camelCase keys in both manifest and Porter custom fields: `clusterArmTemplate`, `uiDefinition`.
- Use `yq load_str(...)` to inject large base64 values safely.
- Add post-publish verification that decodes base64 and rejects placeholders.

## Delivery Model: Worker-Driven Publishing

Operational model:
- Worker container is the single execution unit for Porter builds and ORAS validation.
- `deploy-cnab.yml` mounts product repo and runs `acr-login.sh` + `publish-cnab-bundle.sh`.
- CNAB assets are auto-detected from the mounted `ci/configs/cnab` directory.

## Iteration Protocol (Trace, Fix, Validate)

Loop used to resolve Marketplace errors:
1. Pull published bundle and inspect CNAB config blob via ORAS.
2. Identify placeholders or missing keys.
3. Fix injection logic and key casing.
4. Rebuild/publish and re-verify CNAB config payload.

## Collaboration Workflow (Human + Codex)

- Reproduce Marketplace validation locally with ORAS and CNAB config inspection.
- Keep CNAB assets in repo; keep injection logic in worker script.
- Prefer deterministic validation steps over manual inspection.

### Cadence Snapshot

- Inspect bundle: `oras manifest fetch` + `oras blob fetch`.
- Inject assets: `yq eval ... load_str(...)` in worker script.
- Validate config payload: base64 decode checks and placeholder guards.

## Operational Configuration (Useful Only)

- CNAB assets: `ci/configs/cnab/manifest.yaml`, `porter.yaml`, `azuredeploy.json`, `createUIDefinition.json`.
- Worker entrypoint: `publish-cnab-bundle.sh` in the container PATH.
- Required secrets: ACR creds and Marketplace registry access.

## Examples of Applied Practice

- Verified config blob contained base64 (not placeholders) after publish.
- Updated manifest/porter keys to match Marketplace schema casing.
- Moved base64 injection to `yq load_str` for large payload safety.

## CDE Alignment (Three Layers)

1. Software source specific standard:
   - CNAB assets remain in product repo as source of truth.
2. 12-factor GitHub repo standard:
   - Worker container provides consistent tooling and reproducible builds.
3. Context-Driven Engineering:
   - Explicit key naming and validation steps reduce implicit assumptions.

## Operational Practices

- Always validate the published CNAB config blob before submission.
- Keep Porter templates in repo; do not bake offer assets into the worker image.
- Use the worker container for all Marketplace release builds.

## Next Extensions (Planned)

- Add a template fallback for `porter.yaml` when missing, without overriding repo assets.
- Automate CPA validation in the release pipeline after publish.
