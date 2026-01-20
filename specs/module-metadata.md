Module Metadata Format (Iteration Draft)

Goal
- Standardize how modules expose functions, workflows, and docs for search + AI routing.
- Keep schema minimal; allow future extensions without breaking older modules.

Directory Convention (Suggested)
bin/modules/<module-name>/
  schema.yml
  functions/
  instructions/
  docs/

schema.yml (v0)
Note: JSON is valid YAML, so schema files can start as JSON for easy parsing.

Default Schema (Minimal)
```json
{
  "id": "module-id",
  "version": "0.1",
  "title": "Module Title",
  "components": {
    "docs": [],
    "prompts": [],
    "workflows": []
  }
}
```

```json
{
  "id": "git",
  "version": "0.1",
  "title": "Git Module",
  "components": {
    "docs": [
      {
        "id": "git.guide",
        "path": "docs/guides/git-guide.md",
        "tags": ["git", "workflow", "commands"]
      }
    ],
    "prompts": [
      {
        "id": "git.reset.unpushed",
        "text": "remove latest unpushed commits",
        "workflow_id": "git.reset.unpushed"
      }
    ],
    "workflows": [
      {
        "id": "git.reset.unpushed",
        "title": "Remove latest unpushed commits",
        "edge_cases": [
          "If commits are already pushed, use revert or coordinate with the team.",
          "If the branch is protected, history rewrite may be blocked."
        ],
        "steps": [
          {
            "id": "git.reset.soft",
            "command": "git reset --soft HEAD~1",
            "note": "Keep changes staged.",
            "runnable": false
          }
        ],
        "response": {
          "instructions": [
            "Verify commits are not pushed before using reset."
          ],
          "normalized": "Use git reset with soft/mixed/hard based on whether you want to keep staged or working changes."
        }
      }
    ]
  }
}
```

Full Example (v0)
```json
{
  "id": "worker-deployment",
  "version": "0.1",
  "title": "Worker Deployment",
  "description": "Generate and run Kubernetes deployment configs for workers.",
  "tags": ["k8s", "deployment", "worker", "infra"],
  "entrypoints": {
    "prompt": ["k8s deployment", "worker deployment", "run nodejs on k8s"],
    "commands": ["worker-deployment.config", "worker-deployment.run"]
  },
  "functions": [
    {
      "id": "worker-deployment.config",
      "title": "Generate deployment config",
      "command": "worker-deployment config --type=bash --destination=deploy.yaml",
      "inputs": [
        {"name": "type", "required": false, "default": "bash"},
        {"name": "destination", "required": false, "default": "deploy.yaml"}
      ],
      "outputs": [
        {"type": "file", "path": "deploy.yaml"}
      ],
      "requires_confirmation": true
    },
    {
      "id": "worker-deployment.run",
      "title": "Run deployment",
      "command": "worker-deployment run --config=deploy.yaml",
      "requires_confirmation": true
    }
  ],
  "instructions": [
    {
      "id": "worker-deployment.pipeline.default",
      "title": "Default deployment pipeline",
      "steps": [
        "worker-deployment.config",
        "worker-deployment.run"
      ],
      "next_steps": [
        "k8s.deployment.add",
        "github.workflow.add"
      ]
    }
  ],
  "docs": [
    {
      "id": "containerization.overview",
      "title": "Containerization overview",
      "path": "docs/containerization.md",
      "tags": ["k8s", "docker", "best-practice"],
      "summary": "Why containerization matters and when to use it."
    }
  ],
  "refs": [
    {"label": "CLI source", "url": "https://npmjs.com/worker-deployment"},
    {"label": "Worker docs", "url": "https://udx.dev/worker"}
  ]
}
```

Field Notes
- `id`: stable module identifier; used in responses and indexing.
- `entrypoints.prompt`: keyword/phrase seeds for prompt matching.
- `entrypoints.commands`: preferred command IDs for pipelines.
- `functions`: atomic commands; used to build pipelines.
- `instructions`: reusable pipelines/workflows.
- `docs`: module-local docs; indexable for search.
- `refs`: external references for output enrichment.
- `edge_cases`: optional notes for safety and non-happy paths.
- `protected`: optional step flag for apply/push/destructive actions.
- `preview_command`: optional step command to show a dry run or diff.
- `preview`: optional step text if a command is not available.

Matching Strategy (v0)
- Prompt -> doc/title/tag match
- Doc -> module
- Module -> instruction pipeline
- Fallback -> general advice if no matches

Docs as Metadata (v0)
- During early iterations, docs can live in `docs/` and be indexed by a simple
  mapping table.
  - Later, docs should be moved into `bin/modules/<name>/docs/` and referenced by
  module metadata for tighter cohesion.

Open Questions
- Whether to include CLI output templates in metadata.
- How to model dependencies across modules.
- Confidence scoring rules for prompt matching.
