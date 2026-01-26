# Workflow: Repo Core Cleanup

Task ID: repo-core-cleanup

Scope:
- Reduce the repository to the minimal core mechanism described by `assets/flow.svg`.
- Remove non-core files and update entry-point docs to reflect the reduced scope.

Inputs:
- `assets/flow.svg`
- `README.md`
- `docs/index.md`
- Repo file tree (`rg --files`)
- Child workflow outputs:
  - `workflows/repo-core-cleanup/core-scope.md`
  - `workflows/repo-core-cleanup/keep-list.txt`
  - `workflows/repo-core-cleanup/remove-list.txt`

Intended file edits (proposed only):
- Remove files/directories not in `workflows/repo-core-cleanup/keep-list.txt`.
- Update `README.md` and `docs/index.md` to describe the reduced core.
- Add cleanup artifacts under `workflows/repo-core-cleanup/`.

Validation checks:
- `assets/flow.svg` remains present and referenced in core docs.
- All paths in `workflows/repo-core-cleanup/keep-list.txt` exist after cleanup.
- `README.md` and `docs/index.md` contain no references to removed paths.

## Steps

### Step 1
Task: Derive core scope and keep list (child workflow)
Input:
- `assets/flow.svg`
- Repo file tree
Logic/Tooling:
- `codex exec "cat workflows/repo-core-cleanup/derive-core-scope/workflow.md"` and follow the child steps.
Expected output/result:
- `workflows/repo-core-cleanup/core-scope.md`
- `workflows/repo-core-cleanup/keep-list.txt`
- `workflows/repo-core-cleanup/open-questions.md` (if any)
Done: false

### Step 2
Task: Cleanup and validate repository (child workflow)
Input:
- `workflows/repo-core-cleanup/core-scope.md`
- `workflows/repo-core-cleanup/keep-list.txt`
- `README.md`
- `docs/index.md`
Logic/Tooling:
- `codex exec "cat workflows/repo-core-cleanup/cleanup-and-validate/workflow.md"` and follow the child steps.
Expected output/result:
- `workflows/repo-core-cleanup/remove-list.txt`
- `workflows/repo-core-cleanup/cleanup-log.md`
- Updated `README.md` and `docs/index.md`
- `workflows/repo-core-cleanup/validation-checklist.md`
Done: false
