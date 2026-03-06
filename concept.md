# dev.kit: Global CLI Experience for Deterministic Engineering

- Resolves the **Development Drift** between developer task and normalized execution steps.
- Provides a mechanism to ensure repo-centric standardized development to ensures deterministic engineering.
- AI Agent Integration: Acts as the **Configuration Mechanism** for user intent, mapping high-level prompts to repository-based skills and deterministic execution steps.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/udx/dev.kit/main/bin/scripts/install.sh | bash
```

## The "Consistency & Trust" Vision

The core principle is that **The Repository is the Source of Truth**. `dev.kit` acts as the orchestrator that hydrates the AI with this truth.

### The Equation for Consistency:

`Repo Context + dev.kit Primitives + AI Reasoning = Deterministic Resolution`

- **Repo Context**: Knowledge (`context.yaml`), standards, and repository structure.
- **dev.kit Primitives**: Modular tools and skills (`dev-kit-` prefixed) that perform discrete actions.
- **AI Reasoning**: Agents (Gemini/Codex) that plan and verify, governed by a **Normalization Gate**.

## Core Workflow: Plan -> Normalize -> Process

1.  **Plan**: Analyze the intent against the repository context.
2.  **Normalize**: Convert the plan into a deterministic, step-by-step workflow (DOC-003). **STOP & ASK** if ambiguity exists.
3.  **Process**: Execute modular steps using `dev.kit` commands, providing real-time feedback to the agent for verification.

## Repository-as-a-Skill

Every repository is treated as a standalone **Skill**. `dev.kit` maps internal logic into a unified interface, allowing agents to "learn" how to interact with any codebase instantly via `context.yaml`.

## High-Fidelity Interaction Loop

```mermaid
graph TD
    User([User / Human]) -- Intent / Goal --> DevKit[dev.kit CLI]

    subgraph Repository_Boundary [Repository Context (The Source of Truth)]
        RepoData[(Repo Context: context.yaml, docs, code)]
        RepoSkills[Repository-as-a-Skill]
    end

    DevKit -- Hydrate Context --> Agent[AI Agent]
    RepoData -- Provide Context --> Agent

    subgraph AI_Reasoning_Loop [AI Reasoning & Orchestration]
        Agent -- 1. Plan & Normalize --> Plan[Normalized Workflow]
        Plan -- 2. Execute Step --> DevKit
        DevKit -- 3. Feedback / Result --> Agent
        Agent -- 4. Verify & Iterate --> Plan
    end

    DevKit -- Execution --> System[System / Cloud / Repo Change]
    System -- Drift Detected? --> DevKit

    style DevKit fill:#f9f,stroke:#333,stroke-width:4px
    style Repository_Boundary fill:#e1f5fe,stroke:#01579b
    style AI_Reasoning_Loop fill:#fff3e0,stroke:#e65100
```

## Outcomes

- **Global Availability**: `dev.kit` is available in any directory or repository.
- **Context Awareness**: Automagically detects repository type, dependencies, and standards.
- **Hallucination-Free**: Agents are bounded by local tools and verified repository state.
- **Experienced Flow**: Delivers a structured, waterfall-like progression for any task.
