# YAML Standards: Configuration-as-Code

**Domain:** Reference / Standards  
**Status:** Canonical

## Summary

YAML is the primary format for environment orchestration and configuration. In **dev.kit**, consistent YAML structure ensures that the **Dynamic Discovery Engine** can reliably map repository capabilities and variables across diverse environments.

---

## 🛠 dev.kit Grounding: Standard-to-Action

| YAML Practice | dev.kit Implementation | Primitive / Command |
| :--- | :--- | :--- |
| **Explicit Defaults** | Pre-hydrated variables in templates. | `default.env` |
| **Schema Validation** | Deterministic parsing of orchestrators. | `environment.yaml` |
| **Scoped Overrides** | Repository-bound local configuration. | `.udx/dev.kit/config.env` |
| **Fidelity Mapping** | Intent-based metadata in manifests. | `dev.kit status` |

---

## 🏗 High-Fidelity Mandates

### 1. Human-Editable Intent
Only use YAML for configurations that require human or AI-agent oversight. Machine-only state should favor high-performance formats (e.g., JSON).
- **Action**: Use `environment.yaml` for high-level orchestration and `manifest.json` for internal mapping.

### 2. Zero-Implicit Logic
Favor explicit keys and allowed values over implicit behavior. A high-fidelity repository must be self-documenting through its configuration.
- **Action**: Document all custom YAML keys within the `docs/reference/` layer.

---

## Operational Cues

- **Unpredictable Config?** -> Enforce strict indentation and schema validation via CI/CD.
- **Ambiguous Variable?** -> Move it to `environment.yaml` with an explicit description.

## 📚 Authoritative References

Shared standards are critical for maintaining configuration sanity across teams:

- **[Creating YAML Standards](https://andypotanin.com/creating-yaml-standards-best-practices-for-teams/)**: Best practices for team-wide configuration consistency.
- **[Decentralized DevOps](https://andypotanin.com/how-decentralized-devops-can-help-your-organization/)**: Scaling systems through distributed configuration and architecture.

---
_UDX DevSecOps Team_
