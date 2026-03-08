# DevOps Manual: Operational Controls

**Domain:** Reference / Operations  
**Status:** Canonical

## Summary

The **DevOps Manual** is the primary UDX source for operational controls, security, and delivery practices. In **dev.kit**, it defines the baseline for environment validation and the "Rules of Engagement" for all engineering tasks.

---

## 🛠 dev.kit Grounding: Manual-to-Action

| Control Area | dev.kit Implementation | Primitive / Command |
| :--- | :--- | :--- |
| **Operational Baseline** | Real-time environment and software audit. | `dev.kit doctor` |
| **Delivery Gates** | Compliance integrated into workflow verification. | `workflow.md` |
| **Observability** | Iterative logging and task-scoped feedback. | `feedback.md` |
| **Standardized Skills** | Logic encapsulated in validated CLI boundaries. | `dev.kit skills` |

---

## 🏗 High-Fidelity Mandates

### 1. Verification-as-Logic
Never assume a deployment or maintenance task is complete. All operational actions must include a verification step that confirms alignment with DevOps Manual standards.
- **Action**: Use `dev.kit doctor` to verify system state after complex iterations.

### 2. Observable Flow
All engineering momentum must be visible and audit-ready at the repository level.
- **Action**: Ensure all `workflow.md` artifacts reflect the current operational state.

---

## Operational Cues

- **Auditing Maturity?** -> Run `dev.kit doctor` to evaluate the repository against the high-fidelity baseline.
- **Defining Gates?** -> Use DevOps Manual patterns to define success criteria in your `plan.md`.

## 🏗 Manual Grounding

Operational controls are operationalized through canonical UDX resources:

| Control Area | Grounding Resource | Role |
| :--- | :--- | :--- |
| **Verification** | [`udx/dev.kit`](https://github.com/udx/dev.kit) | Standardized diagnostics and doctor audits. |
| **Gates** | [`udx/reusable-workflows`](https://github.com/udx/reusable-workflows) | Pattern baseline for CI/CD and delivery. |
| **Runtime** | [`udx/worker`](https://github.com/udx/worker) | Hardened environment for control stability. |

---

## 📚 Authoritative References

Operational controls are grounded in systematic delivery and security practices:

- **[DevOps Manual: Core Patterns](https://gist.github.com/fqjony/489fde2ea615b7558bbd407f8b9d97c7)**: Authoritative patterns for operational assurance and security.
- **[Predictable Delivery Flow](https://andypotanin.com/littles-law-applied-to-devops/)**: Managing risk and throughput in complex engineering cycles.
- **[Implementing a cATO System](https://andypotanin.com/implementing-a-continuous-authority-to-operate-cato-system/)**: Frameworks for automated security monitoring and authorization.
- **[SDLC Breaking Points](https://andypotanin.com/wordpress-risks/)**: Identifying and mitigating common failure points in the delivery chain.

---
_UDX DevSecOps Team_
