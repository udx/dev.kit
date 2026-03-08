# Development Best Practices: High-Fidelity Engineering

**Domain:** Engineering / Methodology  
**Status:** Canonical

This document outlines the core engineering practices enforced by **dev.kit**. These practices ensure that the repository state remains deterministic, context-driven, and high-fidelity for both human engineers and AI agents.

---

## 🛠 Practice-to-Command Mapping

| Practice                  | Objective                                                             | dev.kit Command        |
| :------------------------ | :-------------------------------------------------------------------- | :--------------------- |
| **Environment Hydration** | Verify required software, CLI meshes, and authorized state.           | `dev.kit doctor`       |
| **Pre-work Readiness**    | Sync with origin and align feature branches before implementation.    | `dev.kit sync prepare` |
| **Intent Normalization**  | Transform ambiguous requests into deterministic `workflow.md` plans.  | `dev.kit skills run`   |
| **Atomic Sync**           | Group changes into logical, domain-specific commits to prevent drift. | `dev.kit sync run`     |
| **Visual Validation**     | Generate and maintain architecture diagrams (Mermaid/SVG) from code.  | `dev.kit visualizer`   |
| **Task Lifecycle**        | Track progress and prune session context upon task completion.        | `dev.kit task`         |

---

## 🐳 Standard Execution Runtimes

To ensure maximum fidelity, **dev.kit** is optimized for the **UDX Worker Ecosystem**. Using these images eliminates "it works on my machine" friction.

| Component                   | Role                                                                        | Source                                                              |
| :-------------------------- | :-------------------------------------------------------------------------- | :------------------------------------------------------------------ |
| **`udx/worker`**            | The foundational base layer. A pre-hydrated, secure, deterministic runtime. | [Docker Hub](https://hub.docker.com/r/usabilitydynamics/udx-worker) |
| **`udx/worker-deployment`** | The standard pattern for orchestrating worker containers across infra.      | [GitHub](https://github.com/udx/worker-deployment)                  |

### 🧪 Isolated Testing

Always validate **dev.kit** logic within a clean `udx/worker` container to emulate production-grade environments:

```bash
docker run --rm -v $(pwd):/workspace -w /workspace udx/worker ./tests/suite.sh
```

## 🏗 Practice Grounding

High-fidelity engineering is operationalized through canonical UDX resources:

| Requirement | Grounding Resource | Role |
| :--- | :--- | :--- |
| **Logic** | [`udx/dev.kit`](https://github.com/udx/dev.kit) | Validated primitives and discovery engine. |
| **Runtime** | [`udx/worker`](https://github.com/udx/worker) | Deterministic, isolated base environment. |
| **Patterns** | [`udx/reusable-workflows`](https://github.com/udx/reusable-workflows) | Validated sequences for reduced variance. |

---

## 🏗 High-Fidelity Principles

> ### 1. Grounding Before Action
>
> Never execute logic without grounding the environment. An ungrounded state is the primary source of repository drift.
>
> - **Mandate:** Run `dev.kit sync prepare` and `dev.kit doctor` at the start of every session.

> ### 2. Logical Separation of Concerns
>
> Avoid "Mega-Commits." Mixing documentation, configuration (YAML), and core source code obscures intent and breaks the audit trail.
>
> - **Mandate:** Use `dev.kit sync run` to categorize changes into logical, reviewable units.

> ### 3. Documentation as Executable Logic
>
> Treat Markdown (`docs/`) and script headers (`lib/`) as the **Command Surface**. High-fidelity headers allow the CLI to dynamically discover and map repository skills.
>
> - **Mandate:** Maintain `@description` and `@intent` blocks in all scripts to feed the Discovery Engine.

> ### 4. Fail-Open Resilience
>
> When a specialized automation fails, the system must not "hard-crash." It must fallback to standard text/logs for human or AI diagnostic review.
>
> - **Mandate:** Ensure all scripts provide high-signal output to `workflow.md` artifacts even during partial failures.

---

## 🧠 AI & Agent Integration

- **Autonomous Grounding:** Agents must run `dev.kit ai sync` to refresh their internal skill-map, but **never** push changes to `origin` without explicit user confirmation.
- **Incremental Feedback:** Use the **Waterfall Progression Tail** to provide real-time status updates. High-latency tasks must emit "Heartbeat" logs to prevent context timeouts.
- **Native Tooling Only:** AI agents must use the **same CLI commands** as humans. Do not allow agents to bypass the `dev.kit` boundary for raw shell access.

## 📚 Authoritative References

High-fidelity engineering is grounded in systematic roles and automation standards:

- **[Key Roles in specialized Dev Teams](https://andypotanin.com/best-practices-specialized-software-development/)**: Understanding specialized roles for cloud-native and resilient infrastructure.
- **[The Power of Automation](https://andypotanin.com/the-power-of-automation-how-it-has-transformed-the-software-development-process/)**: Transforming the software development process through systematic automation.

---
_UDX DevSecOps Team_
