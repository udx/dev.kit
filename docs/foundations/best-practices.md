# Best Practices & Patterns

**Domain:** Foundations / Engineering Standards  
**Status:** Canonical

## Summary

This document defines the high-fidelity engineering standards and reusable patterns for **dev.kit**. Adherence to these practices ensures that repository skills remain deterministic, portable, and legible to both humans and agents.

---

## 🛠 Command Mappings

Every intent should map to a deterministic CLI command. Avoid performing raw operations when a `dev.kit` primitive exists.

| Intent                | Primary Command       | Standard Procedure                                                                 |
| :-------------------- | :-------------------- | :--------------------------------------------------------------------------------- |
| **Audit Health**      | `dev.kit status --audit` | Check environment prerequisites, shell integration, and repo compliance.           |
| **Resolve Drift**     | `dev.kit sync run`    | Perform logical, domain-specific commits and automate PR creation.                  |
| **Execute Skill**     | `dev.kit skills run`  | Run a specialized repository-bound workflow script.                                 |
| **Render Diagram**    | `dev.kit visualizer`  | Generate high-fidelity Mermaid diagrams from templates.                            |
| **Manage Lifecycle**  | `dev.kit task`        | Deconstruct intent into a `workflow.md` and track resolution state.                |

---

## 🧪 High-Fidelity Patterns

### 1. The Engineering Loop (Plan-Act-Validate)
Always follow the **Iterative Resolution Cycle**. Never commit changes that haven't been validated against documentation or a test suite.
- **Pattern**: Use `dev.kit task start` to initialize the loop and `dev.kit test` to close it.

### 2. Isolated Verification
Validate logic within a clean `udx/worker` container to emulate production environments and eliminate "it works on my machine" friction.
- **Pattern**: `dev.kit test --worker` utilizes `@udx/worker-deployment` for high-fidelity verification.

### 3. Fail-Open Interaction
Specialized tools (e.g., Mermaid renderers) may not always be present. Design logic to provide raw source data as a fallback to prevent blocking the engineering flow.

---

## 🏗 Documentation Patterns

Markdown is the logical map of the repository. Use structured headers and frontmatter to ensure legibility.

### 1. Skill Metadata
Skills defined in `docs/skills/` must include a `SKILL.md` with standard metadata:
```markdown
# Skill Name
- **Intent**: key, keywords, action
- **Objective**: Concise summary of what this skill achieves.
```

### 2. Workflow State
Active tasks in `tasks/` must use a standard `workflow.md` to track progression:
```markdown
# Workflow: Task ID
- [x] Step 1: Completed action
- [>] Step 2: Active action
- [ ] Step 3: Planned action
```

---

## 🏗 Grounding Resources

| Requirement | Grounding Resource | Role |
| :--- | :--- | :--- |
| **Standards** | [`docs/reference/standards/`](../reference/standards/) | Source of truth for 12-factor and YAML compliance. |
| **Automation** | [`udx/reusable-workflows`](https://github.com/udx/reusable-workflows) | Pattern baseline for CI/CD consistency. |
| **Runtime** | [`udx/worker`](https://github.com/udx/worker) | Deterministic, isolated base environment. |

---
_UDX DevSecOps Team_
