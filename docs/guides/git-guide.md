# Git Best Practices & Useful Commands

## Branch Management

### Creating & Switching Branches
```bash
# Create and switch to new branch
git checkout -b feature/my-feature

# Switch to existing branch
git checkout main

# Create branch from specific commit
git checkout -b hotfix/bug-123 abc1234
```

### Branch Cleanup
```bash
# Delete local branch
git branch -d feature/old-feature

# Force delete unmerged branch
git branch -D feature/abandoned

# Delete remote branch
git push origin --delete feature/old-feature

# Prune deleted remote branches
git fetch --prune
```

## Commit Best Practices

### Commit Messages
- **Format**: `<type>: <subject>` (max 50 chars)
- **Types**: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`
- **Example**: `fix: resolve authentication timeout issue`

### Useful Commit Commands
```bash
# Amend last commit message
git commit --amend -m "new message"

# Amend last commit (add files without changing message)
git commit --amend --no-edit

# Interactive rebase last 3 commits
git rebase -i HEAD~3

# Unstage last commit (keep changes)
git reset HEAD~1

# Discard last commit entirely
git reset --hard HEAD~1
```

## Stashing Work

```bash
# Stash current changes
git stash

# Stash with message
git stash save "WIP: feature implementation"

# List stashes
git stash list

# Apply latest stash (keep in stash list)
git stash apply

# Apply and remove latest stash
git stash pop

# Apply specific stash
git stash apply stash@{2}

# Drop specific stash
git stash drop stash@{0}

# Clear all stashes
git stash clear
```

## Viewing History

```bash
# Compact log (last 10 commits)
git log --oneline -n 10

# Graph view
git log --oneline --graph --all

# Show changes in commit
git show abc1234

# Show file history
git log --follow -- path/to/file

# Show who changed what
git blame path/to/file

# Search commits by message
git log --grep="keyword"

# Show commits by author
git log --author="name"
```

## Undoing Changes

```bash
# Discard changes in working directory
git checkout -- path/to/file

# Unstage file
git reset HEAD path/to/file

# Revert commit (creates new commit)
git revert abc1234

# Reset to specific commit (dangerous)
git reset --hard abc1234

# Restore file from specific commit
git checkout abc1234 -- path/to/file
```

## Remove Latest Unpushed Commits

Before doing this, confirm the commits are not pushed:
```bash
git log --oneline --decorate -n 5
git status -sb
```

Options:
```bash
# Remove last commit but keep changes staged
git reset --soft HEAD~1

# Remove last commit and unstage changes (keep in working tree)
git reset --mixed HEAD~1

# Remove last commit and discard changes (dangerous)
git reset --hard HEAD~1
```

Remove multiple commits (N commits):
```bash
git reset --soft HEAD~N
git reset --mixed HEAD~N
git reset --hard HEAD~N
```

## Cleanup/Override History (Before PR)

Goal: clean, readable history before opening a PR. Keep backups and use
`--force-with-lease` when rewriting a shared branch.

Recommended flow:
```bash
# Create a safety branch
git branch backup/cleanup-$(date +%Y%m%d)

# Rebase your branch onto main (or target base)
git fetch origin
git rebase -i origin/main
```

During interactive rebase:
- `pick` to keep a commit as-is
- `reword` to edit message
- `squash` or `fixup` to combine commits
- `drop` to remove a commit

After rebase:
```bash
# Push rewritten history safely
git push --force-with-lease
```

Preview before pushing:
```bash
git push --force-with-lease --dry-run
```

## Remote Operations

```bash
# Add remote
git remote add origin https://github.com/user/repo.git

# View remotes
git remote -v

# Fetch without merge
git fetch origin

# Pull with rebase
git pull --rebase origin main

# Push and set upstream
git push -u origin feature/my-feature

# Force push (use with caution)
git push --force-with-lease

# Update local branch list from remote
git fetch --prune
```

## Merging & Rebasing

### Merge
```bash
# Merge branch into current
git merge feature/my-feature

# Merge with no fast-forward
git merge --no-ff feature/my-feature

# Abort merge
git merge --abort
```

### Rebase
```bash
# Rebase current branch onto main
git rebase main

# Interactive rebase
git rebase -i HEAD~3

# Continue after resolving conflicts
git rebase --continue

# Abort rebase
git rebase --abort
```

## Conflict Resolution

```bash
# Show conflicts
git diff

# Use theirs for conflict
git checkout --theirs path/to/file

# Use ours for conflict
git checkout --ours path/to/file

# After resolving
git add path/to/file
git commit
```

## Tags

```bash
# Create lightweight tag
git tag v1.0.0

# Create annotated tag
git tag -a v1.0.0 -m "Release version 1.0.0"

# Push tag to remote
git push origin v1.0.0

# Push all tags
git push --tags

# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin --delete v1.0.0
```

## Useful Aliases

Add to `~/.gitconfig`:
```ini
[alias]
    st = status -sb
    co = checkout
    br = branch
    ci = commit
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = log --oneline --graph --all --decorate
    amend = commit --amend --no-edit
    undo = reset HEAD~1
    sync = !git fetch --prune && git pull --rebase
```

## Workflow Best Practices

### Feature Branch Workflow
1. Create feature branch from `main`
2. Make commits with clear messages
3. Push to remote regularly
4. Create PR/MR for review
5. Merge after approval
6. Delete feature branch

### Commit Frequency
- Commit often, push when stable
- Each commit should be atomic (one logical change)
- Don't commit broken code to shared branches

### Before Pushing
```bash
# Review changes
git diff origin/main

# Check status
git status

# Run tests
npm test  # or your test command

# Lint/format code
npm run lint
```

## Emergency Commands

```bash
# Find lost commits
git reflog

# Recover deleted branch
git checkout -b recovered-branch abc1234

# Undo last push (if no one pulled)
git push --force-with-lease origin main

# Clean untracked files (dry run first)
git clean -n
git clean -fd
```

## Configuration

```bash
# Set user info
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set default editor
git config --global core.editor "vim"

# Enable color
git config --global color.ui auto

# Set default branch name
git config --global init.defaultBranch main

# View all config
git config --list
```

## Tips

- **Use `.gitignore`**: Keep generated files out of version control
- **Commit messages matter**: Future you will thank present you
- **Pull before push**: Avoid conflicts
- **Branch naming**: Use prefixes like `feature/`, `fix/`, `hotfix/`
- **Keep commits small**: Easier to review and revert
- **Test before commit**: Don't break the build
- **Use `--force-with-lease`**: Safer than `--force`
- **Regular backups**: Push to remote frequently
