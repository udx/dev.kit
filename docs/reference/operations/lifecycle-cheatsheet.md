# Operational Lifecycle: Release & Maintenance

**Domain:** Reference / Operations  
**Status:** Canonical

## Summary

Lifecycle practices focus on reducing production risk and maintaining predictable delivery. In **dev.kit**, these practices are codified within the **Drift Resolution Cycle** to ensure that every environment transition is deterministic and high-fidelity.

---

## 🛠 dev.kit Grounding: Principle-to-Primitive Mapping

| Lifecycle Practice | dev.kit Implementation | Primitive / Command |
| :--- | :--- | :--- |
| **Environment Alignment** | Unified runtime via the Worker Ecosystem. | `udx/worker` |
| **Step Sequencing** | Bounded, multi-step execution sequences. | `workflow.md` |
| **State Tracking** | Lifecycle visibility (planned -> in_progress -> done). | `dev.kit status` |
| **Pre-Deploy Readiness** | Preparation of feature branches and grounding. | `dev.kit sync prepare` |
| **Post-Deploy Verification** | Continuous diagnostic and compliance checks. | `dev.kit doctor` |

---

## 🏗 High-Fidelity Mandates

### 1. Unified Step Ownership
Never execute ad-hoc manual steps during a release. All operational actions must be captured as discrete workflow steps.
- **Action**: Use `dev.kit skills run` to orchestrate one-off maintenance tasks.

### 2. Migration-First Design
Plan migrations and rollbacks before implementation begins. Ground your execution in verified repository logic.
- **Action**: Document migration steps in the `plan.md` artifact before normalization.

### 3. Identity Verification
Ensure that the application and its automation know their environment identity at runtime.
- **Action**: Use `environment.yaml` to define scoped orchestration variables.

---

## Operational Cues

- **Release Blocked?** -> Check `workflow.md` status to identify the specific failure step.
- **Environment Drift?** -> Run `dev.kit doctor` to verify alignment with standard Worker runtimes.

## 📚 Authoritative References

Predictable delivery requires a commitment to planning and management:

- **[Developing Lifecycles Cheatsheet](https://andypotanin.com/developing-lifecycles-a-comprehensive-cheatsheet/)**: Essential practices for smooth production deployments.
- **[SDLC Breaking Points](https://andypotanin.com/wordpress-risks/)**: Identifying and mitigating vulnerabilities in the delivery lifecycle.
- **[Implementing a cATO System](https://andypotanin.com/implementing-a-continuous-authority-to-operate-cato-system/)**: Principles for automated compliance and authorization.

---
_UDX DevSecOps Team_
