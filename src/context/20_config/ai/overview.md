AI Integration (Iteration Draft)

Goal
- Make dev.kit the primary middleware for AI CLI workflows.
- Provide a stable, minimal contract for AI clients to follow.
- Allow human-friendly output while supporting machine parsing when needed.

Scope
- Applies to AI CLI integrations first (Codex CLI, Claude CLI, etc.).
- IDE agent integration is deferred; requirements may diverge later.
- This document is iterative and will evolve with the knowledge base design.

Core Contract
- Pipeline: If dev.kit returns a command pipeline, AI asks for user confirmation, then calls `dev.kit <command_id>`.
- Fallback: If dev.kit reports "not detected", AI provides general advice after showing dev.kit output.
- Priority: dev.kit output and references take precedence over general advice.

CLI Interface (v0)
- `dev.kit -p "<prompt>" [--format=text|json]`
- `dev.kit <command_id> [--format=text|json]`
 - Optional: `dev.kit <command_id> --step <n>` for stepwise confirmation.

JSON Response Envelope (v0)
```json
{
  "meta": {
    "version": "0.1",
    "request_id": "uuid",
    "mode": "human|ai",
    "input": "original prompt",
    "match": "detected|not_detected",
    "confidence": 0.0
  },
  "summary": "1-2 line quick answer",
  "pipeline": [
    {
      "id": "worker-deployment.config",
      "title": "Generate deployment config",
      "command": "worker-deployment config --type=bash --destination=deploy.yaml",
      "requires_confirmation": true,
      "next": "worker-deployment.run"
    }
  ],
  "next_steps": [
    {"id": "k8s.deployment.add", "label": "Define k8s deployment resources"},
    {"id": "github.workflow.add", "label": "Add GitHub workflow"}
  ],
  "refs": [
    {"label": "CLI source", "url": "https://npmjs.com/worker-deployment"}
  ],
  "docs": [
    {
      "id": "containerization.overview",
      "title": "Containerization overview",
      "tags": ["k8s", "docker", "best-practice"],
      "content": "short excerpt or pointer"
    }
  ],
  "fallback": {
    "allowed": true,
    "general_advice": "optional short guidance"
  }
}
```

Human Output (Text Mode)
- Keep the human-friendly block output.
- Add a single machine hint line for lightweight parsing:
  `[dev.kit] match=detected; confidence=0.86; pipeline=2; next_steps=3; refs=3`

AI Client Behavior (Checklist)
- Always call `dev.kit -p` for user prompts.
- If `match=detected` and `pipeline` is present, request confirmation.
- After confirmation, call `dev.kit <command_id>` for the chosen pipeline step.
- If `match=not_detected`, show dev.kit output then add general advice.
- Always prefer dev.kit references and docs when available.

Context7 (Optional Channel)
- Treat Context7 as a distribution channel for docs, not the source of truth.
- Mirror docs and metadata from dev.kit modules.
- Keep commands and pipeline logic in dev.kit CLI.

Prompting References
- Use `src/context/20_config/references/codex_prompting_guide.md` as inspiration for concise, tool-first prompts.

Open Questions (For Next Iteration)
- Exact confidence scoring strategy.
- How strict "pipeline requires confirmation" should be by default.
- Versioning strategy for CLI output and JSON schema.

Clock helper (dev.kit)
- Repo-scoped clock: `.udx/dev.kit/clock/<scope>.env`
- Codex clock: `.codex/dev.kit/clock/codex.env`
