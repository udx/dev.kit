# AI Prompts: The Configuration Layer

Domain: AI

## Purpose

Define how **dev.kit** transforms chaotic user intent into a high-fidelity, deterministic prompt. The AI treats these prompts as the primary **Configuration Layer** for interacting with the repository.

## Prompt Generation Structure

`dev.kit` generates prompts by aggregating multiple sources:

1.  **Common Prompt**: `src/ai/data/prompts.json` - Core engineering logic.
2.  **Integration Overlays**: `src/ai/integrations/codex/prompts.json` - Engine-specific optimizations.
3.  **Active Repository Context**: `context.yaml`, active skills, and local documentation.
4.  **Operational Experience**: Current task status and iteration logs.

## The Workflow Generator Prompt (Core Logic)

This is the primary logic used by `dev.kit` to translate intent into a deterministic action plan:

```text
You are a deterministic workflow generator.

Task:
Convert the user request into a workflow document that uses CLI execution steps.

Input:
- User request (freeform).
- Referenced files and context (paths or summaries).

Logic:
- Derive the minimal number of steps required to complete the request.
- Each step must include: Task, Input, Logic/Tooling, Expected output.
- Use CLI execution primitives for each step.
- Mark each step with status: planned.
- Apply the Extraction Gate; if 2+ answers are yes, extract a child workflow.
- Child workflows are nested under the parent workflow directory.

Output:
- A single Markdown workflow file with ordered steps and status per step.
```

## CLI Usage

- `dev.kit prompt`: Generate the normalized prompt artifact (stdout).
- `dev.kit prompt --out <file>`: Export the prompt for manual use.
- `dev.kit skills run`: Automatically generates and submits the prompt to the configured AI engine.

## Engine-Specific Overlays (Codex/Gemini)

Overlays allow `dev.kit` to adapt the prompt for specific AI capabilities:

- **Codex**: Includes interactive tips like `!` for shell commands and `/review` or `/fork` slash commands.
- **Gemini**: Includes rule enforcement and systematic log capture hooks.

## Configuration & Selection

- **Local Config**: `<repo>/.udx/dev.kit/config.env`
- **Global Config**: `~/.udx/dev.kit/config.env`
- **Key**: `exec.prompt` - Determines which template is used (e.g., `ai`, `ai.codex`).

---
_UDX DevSecOps Team_

