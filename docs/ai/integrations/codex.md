# Codex Integration: Config-Driven Orchestration

Domain: AI, Integration, Codex

## Summary

The Codex integration provides a highly structured, configuration-driven AI orchestration mechanism. It uses a combination of agent definitions, rule engines, and TOML configuration files to enforce deterministic engineering behaviors.

## 🛠 Integration Mechanism: Artifact-Based Enforcement

Codex relies on structured artifacts to define its environment and operational logic. **dev.kit** synchronizes these artifacts to the `~/.codex/` directory to ground the agent.

### 1. Artifact Sync (`dev.kit ai sync codex`)
The following core artifacts are synchronized and rendered:
- **OPERATIONAL POLICY**: The agent MAY perform autonomous synchronization to ensure its Skill Mesh and environment are grounded. It continues to require explicit user authorization for all destructive or history-modifying actions (e.g., `commit`, `push`, `remove`).
1.  **`AGENTS.md`**: High-level agent definitions, including titles, intros, and core operational sections.
2.  **`config.toml`**: TOML configuration for approval policies, sandbox modes, and tool configurations.
3.  **`rules/default.rules`**: A rules engine for prefix-based decision making and security enforcement.
4.  **`skills/`**: Managed `dev-kit-` skills, synchronized for deterministic execution.

### 2. Surgical Synchronization
- **Metadata-to-Artifact**: `dev.kit` transforms repository JSON metadata (e.g., `src/ai/data/agents.json`, `config.json`, `rules.json`) into the specific file formats required by Codex.
- **Surgical Purge**: Managed skills are purged during sync to ensure only current engineering logic is active.

---

## 🏗 Operational Logic & Enforcement

The Codex integration is optimized for highly regulated environments where configuration and rules must be explicitly defined.

### Approval Policies
Codex is often configured with a strict approval policy (e.g., "Always Ask" for risky commands), which is enforced through the synchronized `config.toml`.

### Sandbox Mode
The integration supports enabling a sandbox mode for code execution, ensuring that AI-generated scripts run in isolated environments before being applied to the repository.

### Rules Engine Enforcement
The `default.rules` file allows for granular control over the agent's behavior, such as preventing the disclosure of sensitive files or enforcing specific naming conventions for new features.

---

## 🌊 Waterfall Progression (DOC-003)
Similar to Gemini, the Codex integration enforces the use of the **Compact Status Tail** (Waterfall Progression) to maintain visibility and momentum during task resolution.

## 🧠 Comparison with Gemini
| Feature | Gemini Mechanism | Codex Mechanism |
| :--- | :--- | :--- |
| **Grounding** | `GEMINI.md` Hooks | `AGENTS.md` / `config.toml` |
| **System Rules** | `system.md` (Markdown) | `default.rules` (DSL) |
| **Skill Namespace** | `~/.gemini/skills/` | `~/.codex/skills/` |

---
_UDX DevSecOps Team_
