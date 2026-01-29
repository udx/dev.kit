# Best practices

## Docs
- Keep scope explicit (client project vs cluster project).
- Put required inputs first; keep defaults only when stable.
- Provide both manual steps and a script path.
- Include a minimal verification section with read-only commands.
- Keep examples short and runnable.

## Scripts
- Bash only; `set -euo pipefail`.
- Required inputs should be positional args.
- Optional inputs should be env overrides.
- Validate dependencies early (`gcloud`, `yq`).
- Output should be deterministic and easy to parse.
- Avoid side effects unless the script’s purpose is enforcement.

## Reports
- Read config from a single source of truth.
- Include generation time + source path.
- Prefer markdown tables for quick scanning.
- Separate data collection from presentation.

## IAM (worker-site client)
- GSA must exist in the client project.
- GSA needs `roles/secretmanager.secretAccessor`.
- GSA must allow Workload Identity for the namespace KSA.
- KSA name is `worker-site` across namespaces.
