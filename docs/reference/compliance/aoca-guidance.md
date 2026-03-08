# AOCA Guidance: Automation Standardization

**Domain:** Reference / Compliance  
**Status:** Canonical

## Summary

The **Art of Cloud Automation (AOCA)** is the primary UDX guidance source for automation and platform decisions. In **dev.kit**, AOCA provides the foundational patterns used to reduce operational variance and align governance with engineering workflows.

---

## 🛠 dev.kit Grounding: Guidance-to-Action

| AOCA Focus Area | dev.kit Implementation | Primitive / Command |
| :--- | :--- | :--- |
| **Automation Baseline** | Standardized CLI wrappers for all repo tasks. | `dev.kit skills` |
| **Reduced Variance** | Bounded, multi-step engineering loops. | `workflow.md` |
| **Embedded Governance** | Compliance checks integrated into diagnostics. | `dev.kit doctor` |
| **Knowledge Capture** | Dynamic discovery of engineering experience. | `dev.kit ai advisory` |

---

## 🏗 High-Fidelity Mandates

### 1. Standard-First Automation
Never introduce ad-hoc automation that bypasses the `dev.kit` boundary. All repository logic must be exposed as high-fidelity "Skills."
- **Action**: Use script headers (`@description`, `@intent`) to feed the **Dynamic Discovery Engine**.

### 2. Traceable Governance
Compliance evidence must be a natural byproduct of the **Drift Resolution Cycle**.
- **Action**: Ensure all `workflow.md` artifacts include explicit verification steps.

---

## Operational Cues

- **Ambiguous Practice?** -> Consult `dev.kit ai advisory` for AOCA-aligned patterns.
- **New Skill Required?** -> Use AOCA baseline patterns to define the interface and logic.

## 🏗 AOCA Grounding

Automation standardization is operationalized through canonical UDX resources:

| AOCA Area | Grounding Resource | Role |
| :--- | :--- | :--- |
| **Baseline** | [`udx/reusable-workflows`](https://github.com/udx/reusable-workflows) | Validated automation and platform patterns. |
| **Governance** | [`udx/dev.kit`](https://github.com/udx/dev.kit) | Standardized CLI wrappers and compliance logic. |
| **Platform** | [`udx/worker`](https://github.com/udx/worker) | The deterministic runtime for all platform tasks. |

---

## 📚 Authoritative References

AOCA principles provide the baseline for cloud-native automation and governance:

- **[AOCA: The Book](https://udx.io/cloud-automation-book/)**: Comprehensive guidance on automation, quality, and leadership.
- **[Automation Best Practices](https://udx.io/cloud-automation-book/automation-best-practices)**: Systematic approaches to reducing operational variance.
- **[Cybersecurity & Standards](https://udx.io/cloud-automation-book/cybersecurity)**: Aligning security protocols with automated engineering flows.

---
_UDX DevSecOps Team_
