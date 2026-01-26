# Review Docs Prompt

You are reviewing repository documentation for gaps, inconsistencies, or
missing contract artifacts. Use `docs/_tree.txt` as the input
inventory and limit your review to `docs/`.

Output a concise report formatted to append to `docs/_feedback.md`.

Required format:

## Review Run
- date: <UTC ISO-8601>
- scope: docs

### Findings
- <ID>: <title> — <one-line description>

### Proposed Tasks
- <ID>: <short title>
  - scope: <bounded scope>
  - inputs: <files or artifacts>
  - expected outputs: <files or artifacts>
  - constraints: <determinism, tool-neutrality, no execution>

### Notes
- <optional clarifications or questions>
