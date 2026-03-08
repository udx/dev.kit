# AI Managed Skills: Repository-Bound Engineering

Domain: AI, Engineering

## Summary

In **dev.kit**, an AI skill is a high-fidelity, repository-bound engineering tool. Unlike generic AI prompts, these skills are **deterministic** and **grounded** in the repository's source of truth.

## Managed Skills Index

Each skill is implemented as a "Skill Pack" containing documentation (`SKILL.md`), logic (scripts), and configuration.

| Skill | Brief Description | Detailed Documentation |
| :--- | :--- | :--- |
| **`dev-kit-visualizer`** | Generate and export Mermaid diagrams (SVG). | [SKILL.md](../../src/ai/data/skill-packs/dev-kit-visualizer/SKILL.md) |
| **`dev-kit-git-sync`** | Logical, atomic commits and drift resolution. | [SKILL.md](../../src/ai/data/skill-packs/dev-kit-git-sync/SKILL.md) |
| **`dev-kit-experience-capture`** | Convert session learnings into persistent repo power. | [SKILL.md](../../src/ai/data/skill-packs/dev-kit-experience-capture/SKILL.md) |
| **`dev-kit-core`** | Manage environment health and agent synchronization. | [SKILL.md](../../src/ai/data/skill-packs/dev-kit-core/SKILL.md) |
| **`dev-kit-compliance`** | Validate repository health against UDX standards. | [SKILL.md](../../src/ai/data/skill-packs/dev-kit-compliance/SKILL.md) |

---

## 🛠 How It Works & Agent Enforcement

### 1. Repository Grounding (The Truth)
Skills are not just text; they are **enforced patterns**. When an agent (Gemini/Codex) is synchronized via `dev.kit ai sync`, it is "grounded" with these specific skill definitions. The agent is instructed that these skills are the **only** authorized ways to perform specialized engineering tasks.

### 2. Deterministic Execution
While the agent uses its intelligence to understand *intent*, the final execution is always handled by deterministic scripts or structured workflows:
- **Scripts**: Located in `scripts/` within each skill pack.
- **Bootstrapping**: `dev.kit skills run` ensures the correct environment, permissions (`chmod +x`), and REPO_DIR context.

### 3. Naming Convention & Discovery
- **Native Namespace**: All managed skills use the `dev-kit-` prefix.
- **Provider-Aware**: Skills are synchronized to the active AI provider's directory (e.g., `~/.gemini/skills/` or `~/.codex/skills/`).
- **Surgical Sync**: `dev.kit` performs a surgical purge during synchronization to ensure that only current, valid skills are available to the agent.

### 4. The Lifecycle: Plan -> Normalize -> Process
The agent follows a mandatory lifecycle for every skill execution:
1.  **Plan**: Identify the requirement and the matching `dev-kit-` skill.
2.  **Normalize**: Transform the user's high-level intent into the specific parameters required by the skill's scripts.
3.  **Process**: Execute the skill's logic and report the outcome using a **Waterfall Progression Tail** (DOC-003).

---
_UDX DevSecOps Team_
