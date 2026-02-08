# Workflow: Derive Core Scope

Task ID: repo-core-cleanup/derive-core-scope

Scope:
- Extract the core mechanism described in `assets/flow.svg`.
- Produce a keep list that maps the mechanism to concrete repo files.

Inputs:
- `assets/flow.svg`
- Repo file tree (`rg --files`)
- `README.md`
- `docs/index.md`

Intended file edits (proposed only):
- Create `src/workflows/repo-core-cleanup/flow-notes.md`.
- Create `src/workflows/repo-core-cleanup/core-scope.md`.
- Create `src/workflows/repo-core-cleanup/keep-list.txt`.
- Create `src/workflows/repo-core-cleanup/open-questions.md` when needed.

Validation checks:
- Core scope summary is traceable to labels in `assets/flow.svg`.
- Every keep-list entry is justified by the core scope.

## Steps

### Step 1
Task: Extract mechanism cues from `assets/flow.svg`
Input:
- `assets/flow.svg`
Logic/Tooling:
- `codex exec "rg -n '<text|<tspan|<title' assets/flow.svg"`
- `codex exec "sed -n '1,200p' assets/flow.svg"`
- `codex exec "$EDITOR src/workflows/repo-core-cleanup/flow-notes.md"` to capture the mechanism labels and relationships.
Expected output/result:
- `src/workflows/repo-core-cleanup/flow-notes.md` with a concise mechanism outline.
Done: false

### Step 2
Task: Inventory repo files against mechanism cues
Input:
- `src/workflows/repo-core-cleanup/flow-notes.md`
- Repo file tree
Logic/Tooling:
- `codex exec "rg --files > /tmp/repo-core-cleanup-files.txt"`
- `codex exec "rg -n '' README.md docs/index.md"` to locate current entry points.
- `codex exec "$EDITOR src/workflows/repo-core-cleanup/core-scope.md"` to map mechanism cues to required files.
Expected output/result:
- `src/workflows/repo-core-cleanup/core-scope.md` mapping mechanism elements to files/dirs.
Done: false

### Step 3
Task: Produce keep list and open questions
Input:
- `src/workflows/repo-core-cleanup/core-scope.md`
- `/tmp/repo-core-cleanup-files.txt`
Logic/Tooling:
- `codex exec "$EDITOR src/workflows/repo-core-cleanup/keep-list.txt"` to list required paths (one per line).
- `codex exec "$EDITOR src/workflows/repo-core-cleanup/open-questions.md"` for any ambiguous mappings.
Expected output/result:
- `src/workflows/repo-core-cleanup/keep-list.txt` containing the minimal core set.
- `src/workflows/repo-core-cleanup/open-questions.md` (optional).
Done: false
