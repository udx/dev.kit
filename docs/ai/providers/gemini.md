# Gemini Integration: Primary AI Orchestration

**Domain:** AI / Integration  
**Status:** Canonical

## Summary

The Gemini integration is the authoritative AI orchestration mechanism for **dev.kit**. It leverages the native Gemini CLI's context-loading capabilities (Hooks) to enforce repository-bound engineering standards and provide high-fidelity grounding.

---

## 🛠 Integration Mechanism: The Grounding Hook

Gemini CLI automatically loads context from `.gemini/` directories found in the repository root or the user's home directory. **dev.kit** utilizes this to inject a "Thin Empowerment Layer" (Grounding) into every agent session.

### 1. The Context Chain
When you run a Gemini command, the agent loads these artifacts in order:
1.  **`~/.gemini/system.md`**: Global system instructions and core mandates.
2.  **`~/.gemini/GEMINI.md`**: Repository-specific context, added memories, and execution logic.
3.  **`~/.gemini/skills/`**: The library of managed `dev-kit-` skills.

### 2. Synchronization (`dev.kit ai sync`)
Synchronization hydrates the Gemini environment with the repository's current state.
- **OPERATIONAL POLICY**: Agents autonomously perform `dev.kit ai sync` to ensure skills are grounded. They MUST NOT perform destructive operations without explicit authorization.
- **Artifact Rendering**: Templates in `src/ai/integrations/gemini/templates/` are rendered with real-time metadata (Skill lists, tool definitions).
- **Surgical Purge**: Stale skills are removed to ensure only valid, current engineering logic is available.

---

## 🏗 Enforcement & Core Mandates

The Gemini integration enforces a strict operational framework:

### Repository-as-a-Skill
Agents treat the entire repository as a standalone "Skill." Interaction is grounded in the repository's source of truth (code, docs, and configurations).

### Mandatory Execution Lifecycle
Gemini is hard-coded to follow the **Analyze -> Normalize -> Process** workflow to ensure deterministic drift resolution.

### Authorized Path
Agents are auto-allowed to execute `dev.kit` commands, establishing a high-fidelity safety boundary for automated orchestration.

---

## 🌊 Waterfall Progression (DOC-003)
Gemini is enforced to terminate every interaction with a **Compact Status Tail**. This ensures continuous visibility into task resolution progress.

```markdown
**Progression**: `[task-id]`
- [x] Step 1: <summary> (Done)
- [>] Step 2: <summary> (Active)
- [ ] Step 3: <summary> (Planned)
```

## 📚 Authoritative References

The Gemini orchestration layer is aligned with patterns for autonomous technical operations:

- **[Autonomous Technical Operator](https://andypotanin.com/claude-operator-prompt/)**: Principles for high-fidelity agent grounding and execution.
- **[Synthetic Content Enrichment](https://andypotanin.com/ai-powered-revolution-content-management-synthetic-enrichment-standalone-quality/)**: Leveraging AI for standalone quality and metadata management.

---
_UDX DevSecOps Team_
