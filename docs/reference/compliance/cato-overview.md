# cATO (Continuous Authorization): Automated Compliance

**Domain:** Reference / Compliance  
**Status:** Canonical

## Summary

Continuous Authorization to Operate (cATO) replaces point-in-time approvals with automated, real-time evidence. In **dev.kit**, cATO is achieved by integrating compliance checks directly into the **Drift Resolution Cycle**.

---

## 🛠 dev.kit Grounding: Principle-to-Primitive Mapping

| cATO Requirement | dev.kit Implementation | Primitive / Command |
| :--- | :--- | :--- |
| **Continuous Monitoring** | Real-time environment and dependency audit. | `dev.kit doctor` |
| **Automated Evidence** | Iterative engineering logs and atomic commits. | `dev.kit sync run` |
| **Drift Remediation** | Identification and resolution of intent divergence. | `dev.kit skills run` |
| **Traceable Workflows** | Bounded, versioned execution plans. | `workflow.md` |
| **Validated Supply Chain** | Verification of authorized mesh providers. | `dev.kit ai status` |

---

## 🏗 High-Fidelity Mandates

### 1. Compliance-as-Artifact
Never treat compliance as a post-work activity. All evidence must be captured during the implementation phase.
- **Action**: Ensure every task includes a **Verification** step in its `workflow.md`.

### 2. Observable Controls
Repository controls must be measurable and discoverable by the **Dynamic Discovery Engine**.
- **Action**: Keep `environment.yaml` and script headers updated to reflect security and compliance intents.

### 3. State-Based Evidence
Store all generated evidence, reports, and security scans in the hidden **State Hub** to avoid source clutter.
- **Action**: Use `.udx/dev.kit/` for ephemeral compliance artifacts.

---

## Operational Cues

- **Security Gap?** -> Run `dev.kit doctor` to identify missing scanners (e.g., `mysec`).
- **Audit Required?** -> Use `dev.kit sync run` to generate a high-signal commit history.

## 📚 Authoritative References

Modern compliance strategies prioritize continuous evidence over static approvals:

- **[Implementing a cATO System](https://andypotanin.com/implementing-a-continuous-authority-to-operate-cato-system/)**: A framework for automated security monitoring and assessment.
- **[SDLC Breaking Points](https://andypotanin.com/wordpress-risks/)**: Principles for identifying vulnerabilities in the delivery chain.
- **[Little's Law for Flow](https://andypotanin.com/littles-law-applied-to-devops/)**: Managing cycle time through automated compliance and throughput.

---
_UDX DevSecOps Team_
