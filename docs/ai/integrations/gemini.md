# Gemini Integration: Native Grounding & Hooks

Domain: AI, Integration, Gemini

## Summary

The Gemini integration is the primary AI orchestration mechanism for **dev.kit**. It leverages the native Gemini CLI's context-loading capabilities (Hooks) to enforce repository-bound engineering standards.

## 🛠 Integration Mechanism: The Grounding Hook

Gemini CLI automatically loads context from `.gemini/` directories found in the repository root or the user's home directory. **dev.kit** utilizes this to inject a "Thin Empowerment Layer" (Grounding) into every agent session.

### 1. The Context Chain
When you run a Gemini command, the agent loads these artifacts in order:
1.  **`~/.gemini/system.md`**: Global system instructions and core mandates.
2.  **`~/.gemini/GEMINI.md`**: Repository-specific context, added memories, and execution logic.
3.  **`~/.gemini/skills/`**: The library of managed `dev-kit-` skills.

### 2. Synchronization (`dev.kit ai sync gemini`)
Synchronization is the process of hydrating the Gemini environment with the repository's current state.
- **Artifact Rendering**: Templates in `src/ai/integrations/gemini/templates/` are rendered with real-time metadata (Skill lists, tool definitions).
- **Surgical Purge**: Stale skills are removed to ensure only valid, current engineering logic is available.
- **Native Namespace**: Skills are prefixed with `dev-kit-` for deterministic discovery.

---

## 🏗 Enforcement & Core Mandates

The Gemini integration enforces a strict operational framework defined in `GEMINI.md`:

### Repository-as-a-Skill
The agent is instructed to treat the entire repository as a standalone "Skill." Every interaction must be grounded in the repository's source of truth (code, docs, and configurations).

### Mandatory Execution Lifecycle
Gemini is hard-coded to follow the **Plan -> Normalize -> Process** workflow:
- **Plan**: Deconstruct requests into discrete requirements.
- **Normalize**: Align intent with UDX patterns and repository standards.
- **Process**: Execute logic using managed skills.

### Sub-Agent Orchestration
For complex tasks, the agent acts as an orchestrator, delegating sub-pipelines to specialized sub-agents and aggregating their results into structured engineering reports.

---

## 🌊 Waterfall Progression (DOC-003)
Gemini is enforced to terminate every interaction with a **Compact Status Tail**. This ensures that the user always has a clear view of the current "Drift" and the progress toward resolution.

```markdown
**Progression**: `[task-id]`
- [x] Step 1: <summary> (Done)
- [>] Step 2: <summary> (Active)
- [ ] Step 3: <summary> (Planned)
```

## 🧠 Future-Proofing: Gemini Hooks
The integration is designed to leverage upcoming Gemini features, such as:
- **Native Skill Hooks**: Direct integration between Gemini CLI and `dev.kit` skill scripts.
- **Persistent Memory Hooks**: Enhanced session persistence across disparate repositories.

---
_UDX DevSecOps Team_
