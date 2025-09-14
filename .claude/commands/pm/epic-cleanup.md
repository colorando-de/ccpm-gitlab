---
allowed-tools: Bash, Read, Write
---

# Epic Cleanup

Clean up epic worktree and branches after merge request has been merged.

## Usage
```
/pm:epic-cleanup <epic_name>
```

## Quick Check

1. **Verify worktree exists:**
   ```bash
   git worktree list | grep "epic-$ARGUMENTS" || echo "❌ No worktree for epic: $ARGUMENTS"
   ```

2. **Check MR status:**
   ```bash
   # Check if MR was merged
   merged_mr=$(glab mr list --source-branch="epic/$ARGUMENTS" --state=merged --json | grep -o '"iid":[0-9]*' | head -1 | cut -d: -f2)
   
   if [ -z "$merged_mr" ]; then
     echo "⚠️ No merged MR found for epic/$ARGUMENTS"
     echo "Run /pm:epic-mr to create one, or /pm:epic-merge for direct merge"
     exit 1
   fi
   
   echo "✅ Found merged MR: !$merged_mr"
   ```

## Instructions

### 1. Verify Main Branch is Updated

Ensure main branch has the merged changes:
```bash
cd {main-repo-path}

# Update main branch
git checkout main
git pull origin main

# Verify epic commits are in main
if git log --oneline -20 | grep -q "epic/$ARGUMENTS"; then
  echo "✅ Epic changes are in main branch"
else
  echo "⚠️ Epic changes not found in main. Pull latest changes:"
  echo "   git pull origin main"
fi
```

### 2. Clean Up Worktree

Remove the epic worktree:
```bash
# Check for uncommitted changes
cd ../epic-$ARGUMENTS 2>/dev/null && {
  if [[ $(git status --porcelain) ]]; then
    echo "⚠️ Uncommitted changes in worktree:"
    git status --short
    echo ""
    read -p "Discard changes and continue? (yes/no): " response
    if [ "$response" != "yes" ]; then
      echo "Cleanup aborted. Commit or stash changes first."
      exit 1
    fi
  fi
}

# Return to main repo
cd {main-repo-path}

# Remove worktree
git worktree remove ../epic-$ARGUMENTS --force
echo "✅ Worktree removed: ../epic-$ARGUMENTS"
```

### 3. Delete Local and Remote Branches

Clean up git branches:
```bash
# Delete local branch
git branch -d epic/$ARGUMENTS 2>/dev/null || git branch -D epic/$ARGUMENTS
echo "✅ Local branch deleted: epic/$ARGUMENTS"

# Delete remote branch (if exists)
if git ls-remote --heads origin epic/$ARGUMENTS | grep -q .; then
  git push origin --delete epic/$ARGUMENTS
  echo "✅ Remote branch deleted: origin/epic/$ARGUMENTS"
else
  echo "ℹ️ Remote branch already deleted or doesn't exist"
fi
```

### 4. Archive Epic Documentation

Move epic docs to archive:
```bash
# Create archive directory if needed
mkdir -p .claude/epics/archived/

# Check if epic directory exists
if [ -d ".claude/epics/$ARGUMENTS" ]; then
  # Update completion status and date
  current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # Update epic.md with completion info
  if [ -f ".claude/epics/$ARGUMENTS/epic.md" ]; then
    # Add completion metadata if not already present
    if ! grep -q "^completed:" .claude/epics/$ARGUMENTS/epic.md; then
      echo "" >> .claude/epics/$ARGUMENTS/epic.md
      echo "## Completion" >> .claude/epics/$ARGUMENTS/epic.md
      echo "completed: $current_date" >> .claude/epics/$ARGUMENTS/epic.md
      echo "merged_mr: !$merged_mr" >> .claude/epics/$ARGUMENTS/epic.md
    fi
  fi
  
  # Move to archive
  mv .claude/epics/$ARGUMENTS .claude/epics/archived/
  echo "✅ Epic archived: .claude/epics/archived/$ARGUMENTS"
else
  echo "⚠️ Epic directory not found: .claude/epics/$ARGUMENTS"
fi
```

### 5. Update GitLab Issues

Close related issues if not already closed:
```bash
# Get issue numbers from archived epic
if [ -f ".claude/epics/archived/$ARGUMENTS/epic.md" ]; then
  epic_issue=$(grep 'gitlab:' .claude/epics/archived/$ARGUMENTS/epic.md | grep -oE '[0-9]+$')
  
  if [ ! -z "$epic_issue" ]; then
    # Check if issue is still open
    issue_state=$(glab issue view $epic_issue --json | grep '"state"' | cut -d'"' -f4)
    
    if [ "$issue_state" = "opened" ]; then
      glab issue close $epic_issue -c "Epic completed and merged via MR !$merged_mr"
      echo "✅ Closed epic issue: #$epic_issue"
    else
      echo "ℹ️ Epic issue #$epic_issue already closed"
    fi
  fi
  
  # Close task issues
  for task_file in .claude/epics/archived/$ARGUMENTS/[0-9]*.md; do
    if [ -f "$task_file" ]; then
      issue_num=$(grep 'gitlab:' $task_file | grep -oE '[0-9]+$')
      if [ ! -z "$issue_num" ]; then
        issue_state=$(glab issue view $issue_num --json 2>/dev/null | grep '"state"' | cut -d'"' -f4)
        
        if [ "$issue_state" = "opened" ]; then
          glab issue close $issue_num -c "Completed in epic MR !$merged_mr"
          echo "✅ Closed task issue: #$issue_num"
        fi
      fi
    fi
  done
fi
```

### 6. Final Summary

```
✅ Epic Cleanup Complete: $ARGUMENTS

Cleaned up:
  ✓ Worktree removed: ../epic-$ARGUMENTS
  ✓ Local branch deleted: epic/$ARGUMENTS
  ✓ Remote branch deleted: origin/epic/$ARGUMENTS
  ✓ Epic archived to: .claude/epics/archived/$ARGUMENTS
  ✓ GitLab issues closed

The epic was merged via MR !$merged_mr

Next steps:
  - Deploy changes if needed
  - Start new epic: /pm:prd-new {feature}
  - View merged work: git log --oneline -10
```

## Error Handling

If cleanup fails at any step:
```
❌ Cleanup failed at: {step}

Manual cleanup steps:
1. Remove worktree: git worktree remove ../epic-$ARGUMENTS --force
2. Delete local branch: git branch -D epic/$ARGUMENTS
3. Delete remote branch: git push origin --delete epic/$ARGUMENTS
4. Archive epic: mv .claude/epics/$ARGUMENTS .claude/epics/archived/

For help: /pm:help
```

## Important Notes

- This command is meant to be run AFTER the MR is merged
- It will force-remove worktrees with uncommitted changes if confirmed
- Archives epic data instead of deleting for future reference
- Closes GitLab issues to maintain synchronization
- Safe to run multiple times (idempotent)