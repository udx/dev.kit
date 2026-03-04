# The UDX Methodology: CLI-Wrapped Automation (CWA)

`dev.kit` is built on a specific methodology for automating development processes: **CLI-Wrapped Automation (CWA).**

## The Bigger Picture

1.  **Repo is a Skill**: Every repository exposes its capabilities through structured scripts and CLI commands.
2.  **dev.kit is the Translator**: `dev.kit` translates complex repository logic into a standardized interface for both humans and AI.
3.  **The Result**: An **experienced dev flow without bullshit**.

## dev.kit: Smart Engineering Interface Translator

At its core, `dev.kit` is a **Smart Engineering Interface Translator.** It acts as an orchestrator that maps local development tools, scripts, and context into a high-fidelity interface for:

*   **Humans**: Providing consistent CLI commands that are easy to remember and use.
*   **AI Agents**: Translating repo-scoped context, skills, and rules into deterministic prompts and MCP server interactions.

### Core Principles

#### 1. Script-First (Modularity)
All automation begins as a simple, modular shell script. Whether it's a test runner, a deployment helper, or a diagram generator, the logic is encapsulated in a standalone script (`scripts/*.sh` or `lib/*.sh`).

#### 2. CLI-Wrapped (Consistency)
To ensure scripts run exactly the same way on every developer's machine and in CI/CD, they are wrapped by a unified CLI entrypoint (`bin/dev.kit`).
*   **Input Normalization**: The CLI validates and normalizes arguments before passing them to the script.
*   **Deterministic Context**: The CLI sets up a predictable environment (paths, constants, state) using `lib/utils.sh` and `bin/env/dev-kit.sh`.

#### 3. Orchestration with `environment.yaml`
`dev.kit` uses `environment.yaml` as its configuration orchestrator. This file defines:
*   **System Settings**: Paths and environment defaults.
*   **AI Mapping**: How repository rules and skills are mapped to AI agents.
*   **Context Management**: How memory and repo-scoped knowledge are stored.

#### 4. AI-First Execution
By wrapping all automation in a CLI, we provide a stable and high-quality interface for AI agents.
*   **Agent-as-a-Skill**: Every repository becomes a collection of "skills" (CLI commands) that an AI agent can reliably call.
*   **Deterministic Output**: AI agents receive structured output (JSON or Markdown) from the CLI, making their feedback loop more accurate and less prone to hallucination.

## The Execution Lifecycle

For every automated task, `dev.kit` follows this lifecycle:

1.  **Plan**: Break the user request into discrete CLI command calls.
2.  **Normalize**: Standardize inputs, check environment health (`doctor`), and map the necessary context.
3.  **Process**: Execute the CLI-wrapped logic and return a structured result.

## Why CWA?

*   **Portability**: Scripts that work locally will work everywhere because the CLI manages their context.
*   **Maintainability**: Decoupling the UI (CLI) from the Logic (Scripts) allows for rapid iteration of tools without breaking the user's (or the AI's) expectations.
*   **Scalability**: New scripts can be added to the repository and instantly exposed as new "skills" through the CLI.
