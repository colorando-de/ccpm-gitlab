---
allowed-tools: Bash, Read, Write
---

# Epic Merge

Merge completed epic from worktree back to main branch.

## Usage
```
/pm:epic-merge <epic_name>
```

## Quick Check

1. **Verify worktree exists:**
   ```bash
   git worktree list | grep "epic-$ARGUMENTS" || echo "❌ No worktree for epic: $ARGUMENTS"
   ```

2. **Check for active agents:**
   Read `.claude/epics/$ARGUMENTS/execution-status.md`
   If active agents exist: "⚠️ Active agents detected. Stop them first with: /pm:epic-stop $ARGUMENTS"

## Instructions

### 1. Check for Existing Merge Request

Check if an MR exists for this epic:
```bash
# Check for open MR
existing_mr=$(glab mr list --source-branch="epic/$ARGUMENTS" --state=opened --json | grep -o '"iid":[0-9]*' | head -1 | cut -d: -f2)

if [ ! -z "$existing_mr" ]; then
  echo "ℹ️ Open merge request found: !$existing_mr"
  echo ""
  echo "Options:"
  echo "1. Merge the MR through GitLab UI first, then run this command for cleanup"
  echo "2. Close the MR and proceed with direct merge (not recommended)"
  echo ""
  echo "To view MR: glab mr view $existing_mr"
  echo ""
  read -p "Continue with direct merge anyway? (yes/no): " response
  if [ "$response" != "yes" ]; then
    echo "Aborted. Please handle the MR first."
    exit 0
  fi
fi

# Check for merged MR
merged_mr=$(glab mr list --source-branch="epic/$ARGUMENTS" --state=merged --json | grep -o '"iid":[0-9]*' | head -1 | cut -d: -f2)

if [ ! -z "$merged_mr" ]; then
  echo "✅ Merge request !$merged_mr was already merged"
  echo "Proceeding with local cleanup..."
  # Skip to cleanup section
  SKIP_MERGE=true
fi
```

### 2. Pre-Merge Validation

Navigate to worktree and check status:
```bash
cd ../epic-$ARGUMENTS

# Check for uncommitted changes
if [[ $(git status --porcelain) ]]; then
  echo "⚠️ Uncommitted changes in worktree:"
  git status --short
  echo "Commit or stash changes before merging"
  exit 1
fi

# Check branch status
git fetch origin
git status -sb
```

### 3. Run Tests (Optional but Recommended)

```bash
# Look for test commands
if [ -f package.json ]; then
  npm test || echo "⚠️ Tests failed. Continue anyway? (yes/no)"
elif [ -f Makefile ]; then
  make test || echo "⚠️ Tests failed. Continue anyway? (yes/no)"
fi
```

### 4. Update Epic Documentation

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update `.claude/epics/$ARGUMENTS/epic.md`:
- Set status to "completed"
- Update completion date
- Add final summary

### 5. Attempt Merge

```bash
# Skip if MR was already merged
if [ "$SKIP_MERGE" != "true" ]; then
  # Return to main repository
  cd {main-repo-path}

  # Ensure main is up to date
  git checkout main
  git pull origin main

  # Attempt merge
  echo "Merging epic/$ARGUMENTS to main..."
  git merge epic/$ARGUMENTS --no-ff -m "Merge epic: $ARGUMENTS

Completed features:
$(cd .claude/epics/$ARGUMENTS && ls *.md | grep -E '^[0-9]+' | while read f; do
  echo "- $(grep '^name:' $f | cut -d: -f2)"
done)

Closes epic #$(grep 'github:' .claude/epics/$ARGUMENTS/epic.md | grep -oE '#[0-9]+')"
else
  echo "✅ Skipping merge (already merged via MR)"
fi
```

### 6. Handle Merge Conflicts

If merge fails with conflicts:
```bash
# Check conflict status
git status

echo "
❌ Merge conflicts detected!

Conflicts in:
$(git diff --name-only --diff-filter=U)

Options:
1. Resolve manually:
   - Edit conflicted files
   - git add {files}
   - git commit
   
2. Abort merge:
   git merge --abort
   
3. Get help:
   /pm:epic-resolve $ARGUMENTS

Worktree preserved at: ../epic-$ARGUMENTS
"
exit 1
```

### 7. Post-Merge Cleanup

If merge succeeds or MR was merged:
```bash
# Push to remote (only if we did a local merge)
if [ "$SKIP_MERGE" != "true" ]; then
  git push origin main
fi

# Clean up worktree
git worktree remove ../epic-$ARGUMENTS
echo "✅ Worktree removed: ../epic-$ARGUMENTS"

# Delete branch
git branch -d epic/$ARGUMENTS
git push origin --delete epic/$ARGUMENTS 2>/dev/null || true

# Archive epic locally
mkdir -p .claude/epics/archived/
mv .claude/epics/$ARGUMENTS .claude/epics/archived/
echo "✅ Epic archived: .claude/epics/archived/$ARGUMENTS"
```

### 8. Update GitLab Issues

Close related issues:
```bash
# Get issue numbers from epic
epic_issue=$(grep 'github:' .claude/epics/archived/$ARGUMENTS/epic.md | grep -oE '[0-9]+$')

# Close epic issue
glab issue close $epic_issue -c "Epic completed and merged to main"

# Close task issues
for task_file in .claude/epics/archived/$ARGUMENTS/[0-9]*.md; do
  issue_num=$(grep 'github:' $task_file | grep -oE '[0-9]+$')
  if [ ! -z "$issue_num" ]; then
    glab issue close $issue_num -c "Completed in epic merge"
  fi
done
```

### 9. Final Output

```
✅ Epic Merged Successfully: $ARGUMENTS

Summary:
  Branch: epic/$ARGUMENTS → main
  Commits merged: {count}
  Files changed: {count}
  Issues closed: {count}
  
Cleanup completed:
  ✓ Worktree removed
  ✓ Branch deleted
  ✓ Epic archived
  ✓ GitLab issues closed
  
Next steps:
  - Deploy changes if needed
  - Start new epic: /pm:prd-new {feature}
  - View completed work: git log --oneline -20
```

## Conflict Resolution Help

If conflicts need resolution:
```
The epic branch has conflicts with main.

This typically happens when:
- Main has changed since epic started
- Multiple epics modified same files
- Dependencies were updated

To resolve:
1. Open conflicted files
2. Look for <<<<<<< markers
3. Choose correct version or combine
4. Remove conflict markers
5. git add {resolved files}
6. git commit
7. git push

Or abort and try later:
  git merge --abort
```

## Important Notes

- Always check for uncommitted changes first
- Check for existing merge requests before direct merge
- Prefer using `/pm:epic-mr` to create an MR first
- Run tests before merging when possible
- Use --no-ff to preserve epic history
- Archive epic data instead of deleting
- Close GitLab issues to maintain sync