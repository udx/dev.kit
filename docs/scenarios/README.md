# Engineering Scenarios & Workflows

Standardized loops for common engineering tasks in the `dev.kit` ecosystem.

## 🚀 Scenario 1: New Feature Development
**Loop**: `feature`

This loop focuses on TDD-driven development with automated context capture.

### Steps
1. **Initiate**: `dev.kit task start "Implement user auth"`
   - Creates a task directory and context tracker.
2. **Design**: `dev.kit "Define test cases for auth"`
   - AI generates a test plan based on repo standards.
3. **Build**: `dev.kit "Implement auth logic and tests"`
   - AI implementation iteration.
4. **Audit**: `dev.kit doctor`
   - Verify health before merging.
5. **Sync**: `dev.kit "Resolve repo drift for task AUTH-001"`
   - Logical grouping of commits (Docs, AI, Core).
6. **Capture**: `dev.kit "Capture experience for task AUTH-001"`
   - Distill patterns into `docs/reference/foundations/knowledge.md`.

---

## 🐛 Scenario 2: Resilient Bugfixing
**Loop**: `bugfix`

A high-fidelity process for identifying and resolving regressions.

### Steps
1. **Track**: `dev.kit task start "Fix crash in sync script"`
2. **Reproduce**: `dev.kit "Reproduce the crash with a unit test"`
   - Ensures the fix is verifiable.
3. **Resolve**: `dev.kit "Apply fix for sync script crash"`
4. **Verify**: `dev.kit "Verify fix with the test suite"`
5. **Drift Resolution**: `dev.kit "Resolve repo drift for task FIX-123"`
6. **Capture**: `dev.kit "Capture experience for task FIX-123: Found race condition"`

---

## 🛠️ Scenario 3: Deployment Migration
**Loop**: `migration`
**Full Demo**: [Vercel to Worker-Engine Migration](./migration-demo.md)

### Steps
1. **Intent**: `dev.kit "migrate to worker-engine deployment"`
2. **Interactive Gate**: Agent asks for confirmation of strategy.
3. **Task Scaffolding**: `dev.kit task start "Migration to worker-engine"`
4. **Processing**: AI generates Dockerfiles, Makefiles, and env configs.
5. **Verification**: `dev.kit doctor` followed by `dev.kit "Resolve drift"`

---

## 📚 Scenario 4: Knowledge & Documentation Sync
**Loop**: `doc-sync`

Keeping the "Knowledge Layer" aligned with the source code.

### Steps
1. **Audit**: `dev.kit "Audit repo for documentation drift"`
2. **Visualize**: `dev.kit "Generate Mermaid diagrams for architecture updates"`
3. **Update**: `dev.kit "Update docs/reference and AI context"`
4. **Commit**: `dev.kit "Resolve repo drift --message 'Docs: Sync'"`
5. **Hydrate Agent**: `dev.kit ai sync`
   - Synchronizes new memories and skills with the AI agent.

---

## ⚠️ Interactive Scenarios (Confidence Gates)

### Ambiguous Intent
**User**: `dev.kit "Setup auth"`
**Agent**: "I found multiple auth patterns (OAuth2, Basic). Should I use the standard UDX OAuth2 template or something else? [SUGGESTED: OAuth2, Basic Auth]"

### Missing Context
**User**: `dev.kit "Sync my changes"`
**Agent**: "I detect uncommitted changes but no active task ID. Please provide a task ID (e.g., DOC-001) to group these changes logically."
