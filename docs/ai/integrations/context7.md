# Context7 Integration: Smart Library Search

Domain: AI, Integration, Knowledge

## Summary

The Context7 integration provides **Smart Search** capabilities for libraries and engineering context. It enables **dev.kit** to resolve complex, library-specific tasks by fetching high-fidelity documentation and examples.

## 🛠 Integration Mechanism: Normalization Over MCP

Unlike standard AI agents that might use Context7 as a Model Context Protocol (MCP) tool, **dev.kit** integrates directly with the Context7 API (v2) and CLI. This architectural choice ensures that the **grounding layer** remains deterministic and repository-centric:

1.  **Normalization First**: When a user's intent involves an external library (e.g., "Use Next.js server actions"), `dev.kit` uses Context7 to find the exact library ID and its standard practices.
2.  **Unified Context**: The gathered data is packaged into the agent's context manifest, providing a single source of truth instead of disparate tool-calls.
3.  **Predictable Results**: By controlling the search parameters (`libraryName` + `query`), `dev.kit` ensures that the most relevant, trust-scored documentation is provided to the agent.

## 🏗 Features & Configuration

### 1. API-First Resolution
- **Endpoint**: `https://context7.com/api/v2/libs/search`
- **Mechanism**: Intelligent ranking based on trust and benchmark scores.
- **Trigger**: Intent resolution identifies a dependency or "Smart Search" requirement.

### 2. Multi-Modal Discovery
- **CLI Fallback**: If the `context7` CLI is installed (`npm install -g @upstash/context7`), `dev.kit` can use it for local resolution.
- **API Key Required**: Set `CONTEXT7_API_KEY` (prefix `ctx7sk`) for high-fidelity API search results.

---

## 🌊 Waterfall Progression (DOC-003)

Gemini and Codex are instructed to utilize Context7 through the `dev.kit` normalization layer whenever a task requires external library documentation or specialized engineering context.

**Progression**: `[context7-search-active]`
- [x] Step 1: Identify external library dependency (Done)
- [>] Step 2: Query Context7 for high-fidelity context (Active)
- [ ] Step 3: Inject documentation into agent grounding manifest (Planned)

---
_UDX DevSecOps Team_
