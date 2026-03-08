# External Standards: Tool-Specific Behavior

**Domain:** Reference / Standards  
**Status:** Canonical

## Summary

External standards are utilized only for tool-specific behavior and syntax. In **dev.kit**, these standards provide the technical constraints for specialized skills while the UDX Foundations remain the primary source of operational truth.

---

## 🛠 dev.kit Grounding: Reference-to-Action

| Standard Source | Role | dev.kit Implementation |
| :--- | :--- | :--- |
| **GitHub Actions** | CI/CD | Validated via `gh` CLI mesh. |
| **Docker / OCI** | Runtime | Verified via the Worker Ecosystem. |
| **OpenTelemetry** | Observability | Integrated into `feedback.md` logs. |
| **POSIX / Shell** | Execution | Guaranteed by the deterministic CLI. |

---

## 🏗 High-Fidelity Mandates

### 1. Narrow Scope
Never allow an external standard to replace a core UDX principle. Use external references only when UDX guidance is insufficient for a specific technical implementation.
- **Action**: Link to exact documentation sections rather than generic homepages.

### 2. Resilience Fallback
When an external tool or standard encounters an edge case, always trigger the **Fail-Open Path**. Ensure the loop continues with standard Markdown or text reasoning.
- **Action**: Document exact external dependencies in `environment.yaml`.

---

## Operational Cues

- **Ambiguous Syntax?** -> Consult the official external reference linked in the module.
- **Edge Case Detected?** -> Fallback to the **Resilient Waterfall** and resolve the drift manually.
## 🏗 External Grounding

External standards are integrated through canonical UDX resources:

| Standard | Grounding Resource | Role |
| :--- | :--- | :--- |
| **Workflow** | [`udx/reusable-workflows`](https://github.com/udx/reusable-workflows) | Pattern baseline for GitHub Actions and pipelines. |
| **Container** | [`udx/worker`](https://github.com/udx/worker) | Host-level parity for Docker/OCI standards. |

---

## 📚 Authoritative References

External standards are integrated within a systematic engineering flow:

- **[Creating YAML Standards](https://andypotanin.com/creating-yaml-standards-best-practices-for-teams/)**: Reducing friction and preventing errors through shared standards.
- **[Digital Rails & Logistics](https://andypotanin.com/digital-rails-and-logistics/)**: Understanding the evolution of software standards through automotive history.

---
_UDX DevSecOps Team_
