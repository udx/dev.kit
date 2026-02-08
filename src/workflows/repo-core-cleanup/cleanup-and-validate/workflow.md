# Workflow: Cleanup and Validate

Task ID: repo-core-cleanup/cleanup-and-validate

Scope:
- Compute the removal list from the keep list.
- Remove non-core files and update entry-point docs.
- Validate the cleaned repo against the core scope.

Inputs:
- `src/workflows/repo-core-cleanup/keep-list.txt`
- Repo file tree (`rg --files`)
- `README.md`
- `docs/index.md`

Intended file edits (proposed only):
- Create `src/workflows/repo-core-cleanup/remove-list.txt`.
- Create `src/workflows/repo-core-cleanup/cleanup-log.md`.
- Update `README.md` and `docs/index.md`.
- Create `src/workflows/repo-core-cleanup/validation-checklist.md`.
- Remove files/dirs not in `src/workflows/repo-core-cleanup/keep-list.txt`.

Validation checks:
- `src/workflows/repo-core-cleanup/keep-list.txt` paths all exist.
- `README.md` and `docs/index.md` do not reference removed paths.
- `src/workflows/repo-core-cleanup/validation-checklist.md` is complete.

## Steps

### Step 1
Task: Generate removal list
Input:
- `src/workflows/repo-core-cleanup/keep-list.txt`
Logic/Tooling:
- `codex exec "rg --files | sort > /tmp/repo-core-cleanup-files.txt"`
- `codex exec "sort src/workflows/repo-core-cleanup/keep-list.txt > /tmp/repo-core-cleanup-keep.txt"`
- `codex exec "comm -23 /tmp/repo-core-cleanup-files.txt /tmp/repo-core-cleanup-keep.txt > src/workflows/repo-core-cleanup/remove-list.txt"`
Expected output/result:
- `src/workflows/repo-core-cleanup/remove-list.txt` listing non-core paths.
Done: false

### Step 2
Task: Review removals and update entry-point docs
Input:
- `src/workflows/repo-core-cleanup/remove-list.txt`
- `README.md`
- `docs/index.md`
Logic/Tooling:
- `codex exec "rg -n -f src/workflows/repo-core-cleanup/remove-list.txt README.md docs/index.md"` to find references.
- `codex exec "$EDITOR src/workflows/repo-core-cleanup/cleanup-log.md"` to record removal decisions.
- `codex exec "$EDITOR README.md"` and `codex exec "$EDITOR docs/index.md"` to update entry points.
Expected output/result:
- `src/workflows/repo-core-cleanup/cleanup-log.md` with rationale.
- Updated `README.md` and `docs/index.md`.
Done: false

### Step 3
Task: Remove non-core files
Input:
- `src/workflows/repo-core-cleanup/remove-list.txt`
Logic/Tooling:
- `codex exec "cat src/workflows/repo-core-cleanup/remove-list.txt"` to confirm the final removal set.
- `codex exec "xargs -d '\n' rm -rf -- < src/workflows/repo-core-cleanup/remove-list.txt"` (manual confirmation required before execution).
Expected output/result:
- Repo contains only keep-list paths plus workflow artifacts.
Done: false

### Step 4
Task: Validate cleanup and log resolution
Input:
- `src/workflows/repo-core-cleanup/keep-list.txt`
- `README.md`
- `docs/index.md`
Logic/Tooling:
- `codex exec "xargs -d '\n' test -e < src/workflows/repo-core-cleanup/keep-list.txt"` to confirm keep-list paths exist.
- `codex exec "rg -n -f src/workflows/repo-core-cleanup/remove-list.txt README.md docs/index.md"` to confirm no removed references remain.
- `codex exec "$EDITOR src/workflows/repo-core-cleanup/validation-checklist.md"` to record validation.
- `codex exec "$EDITOR docs/_feedback.md"` to append a resolution entry if this cleanup is tracked there.
Expected output/result:
- `src/workflows/repo-core-cleanup/validation-checklist.md` complete.
- Resolution log updated when applicable.
Done: false
