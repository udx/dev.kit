# NPM Integration: Runtime Hydration

**Domain:** AI / Runtime Health  
**Status:** Canonical

## Summary

The NPM integration ensures that the local engineering environment is **Hydrated** with the necessary CLI tools. It provides deterministic health checks and proactive installation guidance for `@udx` scoped packages.

---

## 🛠 Features & Capabilities

### 1. Proactive Hydration
When the **Dynamic Discovery Engine** identifies an intent requiring a specific tool (e.g., `@udx/mcurl`), the NPM module verifies its availability.
- **Advice**: If missing, the CLI provides the exact `npm install -g` command to empower the user or agent.

### 2. Runtime Verification
- **Trigger**: `dev.kit doctor` or system bootstrap.
- **Outcome**: Ensures that the `node` and `npm` environments are healthy enough to support high-fidelity engineering tasks.

---

## 🏗 Supported Tools

### 🌐 `@udx/mcurl`
A high-fidelity API client designed for deterministic interaction with complex web services. It provides standardized logging and error handling that is easily consumable by the **Drift Resolution Cycle**.

### 🔐 `@udx/mysec`
A proactive security scanner used to identify secrets, API keys, and sensitive credentials within the repository. It is integrated into the `dev.kit doctor` diagnostic flow to ensure **Credential Protection**.

### 📄 `@udx/md.view`
A Markdown rendering engine that allows for high-fidelity documentation previews directly from the CLI, ensuring that repository context is always legible and accessible.

---

## 🌊 Waterfall Progression (DOC-003)

**Progression**: `[npm-mesh-active]`
- [x] Step 1: Detect and verify `npm` runtime (Done)
- [>] Step 2: Check health of core `@udx` tools (Active)
- [ ] Step 3: Proactively advise on environment hydration (Planned)

---
_UDX DevSecOps Team_
