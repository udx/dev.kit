# Deterministic Prompting Methodology (CDE-Aligned)

## Purpose

Define a concise, reusable methodology for designing prompts that transform
**human-authored Markdown into machine artifacts**
(shell scripts, JSON, configs, pipelines, etc.)
in a **deterministic, round-trip-safe** way using LLMs.

This methodology is **Context Driven Engineering (CDE)–compliant**:
Markdown is the active context, the prompt is the compiler, and the output is a derived artifact.

---

## Core Tenets (CDE-Aligned)

1. **Context is authoritative**  
   - Markdown is configuration and source of truth.
   - Prompts must not contain domain configuration.
   - Missing context must result in missing output.

2. **Compiler mindset**  
   - The LLM acts as a compiler, not an author.
   - No creativity, no inference, no best practices.
   - Transform structure → emit artifact.

3. **Active context layer**  
   - The prompt is a stable execution layer.
   - All variability lives in Markdown (context assets).
   - Output is derived, never hand-edited.

4. **Round-trip safety**  
   - Markdown → Artifact → Markdown must preserve meaning.
   - Ordering, identifiers, and literals remain stable.

---

## Prompt Design Pattern

Every prompt should contain only **execution logic**, never configuration.

### 1. Role declaration
Explicitly define the compiler role.

> *“You are a deterministic compiler that transforms Markdown into \<target artifact\>.”*

---

### 2. Output contract
Eliminate ambiguity.

- Output only the target artifact.
- No prose, no markdown.
- Valid, executable, or machine-parseable output.

---

### 3. Structural mapping
Define how Markdown structure maps to output.

Examples:
- Headings → sections / comments
- Lists → ordered instructions
- Tables → structured records
- Code blocks → literal passthrough

No semantic guessing beyond structure.

---

### 4. Literal safety
- Preserve code blocks and inline code verbatim.
- Do not expand variables or tokens.
- Do not add defaults, flags, or tooling.

---

### 5. Error handling
- If context is incomplete or ambiguous:
  - Preserve it verbatim.
  - Do not guess or “fix”.

---

## Determinism Rules

- Same input → same output.
- Stable ordering is mandatory.
- Identifiers are derived from visible text only.
- Unknown content is preserved under extensions, never dropped.

---

## Applicability

This methodology applies to:

- Markdown → Shell scripts
- Markdown → JSON / YAML
- Markdown → CI pipelines
- Markdown → Infra definitions
- Markdown → Policy artifacts

Only the **structural mapping section** changes per target.

---

## CDE Mapping

| CDE Concept        | Methodology Role                         |
|--------------------|-------------------------------------------|
| Context layer      | Markdown directory                         |
| Context asset      | Markdown document                          |
| Context schema     | Output artifact format                     |
| Active context     | Prompt (compiler logic)                    |
| Artifact           | Generated shell / JSON / config            |

---

## Anti-Patterns

- Embedding defaults in prompts
- Allowing the model to “decide”
- Mixing config with execution logic
- Asking for explanations

---

## Guiding Rule

> **If changing output requires changing the prompt,  
> your configuration is in the wrong place.**

---

## Outcome

When applied correctly, LLMs behave as:
- Predictable build tools
- Context compilers
- Safe automation primitives

—not creative agents.

This makes LLMs usable inside CI, build systems, and CDE pipelines.
