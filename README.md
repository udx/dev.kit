# ⚡️ dev.kit: The Repo Engine

**The deterministic middleware that translates chaotic repositories into high-fidelity, 12-factor standards.**

`dev.kit` acts as a **Contextual Proxy** between your environment and AI agents. It serves as both the **Logic** (the engine) and the **Template** (the blueprint) to resolve architectural drift.

---

## 🕹 The Single-Command Interface

The entire engine is distilled into a single, high-impact verb.

### `dev.kit`

**The Pulse Check.** Instantly analyzes your repository, calculates your **Fidelity Score**, and generates a prioritized `workflow.md` of required drift resolutions.

- **`dev.kit --json` (Compliance Mode)** Outputs a machine-readable audit of 12-factor misalignments. Agents use this to identify and fix "Fidelity Gaps" (missing tests, broken builds, or structural drift).

- **`dev.kit bridge --json` (Development Mode)** Resolves the repository into high-fidelity, agent-friendly assets. It maps the **Skill Mesh**, available CLI primitives, and internal logic so agents can execute tasks without hallucinating paths or patterns.

---

## 🏗 How it Works

- **The Normalization Gate**: Chaotic repo states are filtered into bounded, repeatable workflow artifacts.
- **Logic-as-Template**: The `dev.kit` repository is the canonical example of the standards it enforces. Its structure is the blueprint; its commands are the truth.
- **The Bridge**: Instead of feeding an agent raw files, the `bridge` command provides a structured "Map of Truth," ensuring the agent works within validated boundaries.

---

## ✅ The Fidelity States

| State         | Human Experience        | Agent Experience                                   |
| :------------ | :---------------------- | :------------------------------------------------- |
| **Build**     | _I know how to build._  | Strict 12-factor separation (Build/Release/Run).   |
| **Test**      | _I know how to verify._ | Deterministic loops to validate health instantly.  |
| **Structure** | _I know where to add._  | Standardized hierarchy; zero-guesswork navigation. |
| **Pattern**   | _I know how to grow._   | Repeatable Analyze-Normalize-Process sequences.    |

---

## 🚀 60-Second Onboard

```bash
# 1. Install & Run the Pulse Check
curl -sSL [https://dev.kit/install](https://dev.kit/install) | bash && dev.kit

# 2. Let an Agent Fix Compliance
dev.kit --json | agent-execute "Fix all fidelity gaps"

# 3. Let an Agent Develop a Feature
dev.kit bridge --json | agent-execute "Add a new module using existing primitives"
```
