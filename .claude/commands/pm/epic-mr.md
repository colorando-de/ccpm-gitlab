---
allowed-tools: Bash, Read, Write
---

# Epic Merge Request

Create a GitLab merge request for an epic branch without merging locally.

## Usage
```
/pm:epic-mr <epic_name>
```

## Quick Check

1. **Verify worktree exists:**
   ```bash
   git worktree list | grep "epic-$ARGUMENTS" || echo "❌ No worktree for epic: $ARGUMENTS"
   ```

2. **Check for active agents:**
   Read `.claude/epics/$ARGUMENTS/execution-status.md`
   If active agents exist: "⚠️ Active agents detected. Consider stopping them first with: /pm:epic-stop $ARGUMENTS"

## Instructions

### 1. Pre-MR Validation

Navigate to worktree and check status:
```bash
cd ../epic-$ARGUMENTS

# Check for uncommitted changes
if [[ $(git status --porcelain) ]]; then
  echo "⚠️ Uncommitted changes in worktree:"
  git status --short
  echo ""
  echo "Please commit or stash changes before creating MR"
  echo "To commit: git add . && git commit -m 'Your message'"
  exit 1
fi

# Check branch status
git fetch origin
git status -sb
```

### 2. Push Branch to Origin

Ensure the branch is pushed to GitLab:
```bash
# Check if branch exists on remote
if ! git ls-remote --heads origin epic/$ARGUMENTS | grep -q .; then
  echo "📤 Pushing epic branch to origin..."
  git push -u origin epic/$ARGUMENTS
else
  echo "✅ Branch already exists on origin"
  # Push any new commits
  git push origin epic/$ARGUMENTS
fi
```

### 3. Check for Existing MR

Check if an MR already exists:
```bash
# Check for existing open MR
existing_mr=$(glab mr list --source-branch="epic/$ARGUMENTS" --state=opened --json | grep -o '"iid":[0-9]*' | head -1 | cut -d: -f2)

if [ ! -z "$existing_mr" ]; then
  echo "ℹ️ Merge request already exists: !$existing_mr"
  glab mr view $existing_mr
  echo ""
  echo "To update the existing MR, push new commits to the branch"
  exit 0
fi
```

### 4. Prepare MR Description

Read epic details and create description:
```bash
# Return to main repo for file access
cd {main-repo-path}

# Create MR description file
cat > /tmp/epic-mr-description.md << 'EOF'
## Epic: $ARGUMENTS

### Summary
$(grep '^description:' .claude/epics/$ARGUMENTS/epic.md | cut -d: -f2-)

### Completed Tasks
$(ls .claude/epics/$ARGUMENTS/[0-9]*.md 2>/dev/null | while read task_file; do
  task_name=$(grep '^name:' "$task_file" | cut -d: -f2- | sed 's/^ *//')
  task_status=$(grep '^status:' "$task_file" | cut -d: -f2- | sed 's/^ *//')
  if [ "$task_status" = "completed" ]; then
    echo "- ✅ $task_name"
  else
    echo "- ⏳ $task_name"
  fi
done)

### Related Issues
$(grep 'gitlab:' .claude/epics/$ARGUMENTS/epic.md | grep -oE '#[0-9]+' || echo "None")

### Testing
- [ ] All tests pass
- [ ] Code review completed
- [ ] Documentation updated

### Notes
This MR was created from the epic worktree at `../epic-$ARGUMENTS`
EOF

# Replace variables in the description
epic_name="$ARGUMENTS"
sed -i.bak "s/\$ARGUMENTS/$epic_name/g" /tmp/epic-mr-description.md
```

### 5. Create Merge Request

Create the MR using GitLab CLI:
```bash
# Navigate back to worktree for glab context
cd ../epic-$ARGUMENTS

# Create the merge request
echo "🔄 Creating merge request..."
mr_output=$(glab mr create \
  --title "Epic: $ARGUMENTS" \
  --description "$(cat /tmp/epic-mr-description.md)" \
  --source-branch "epic/$ARGUMENTS" \
  --target-branch "main" \
  --remove-source-branch \
  --squash-before-merge=false \
  --json 2>&1)

# Extract MR number
mr_number=$(echo "$mr_output" | grep -o '"iid":[0-9]*' | head -1 | cut -d: -f2)

if [ ! -z "$mr_number" ]; then
  echo "✅ Merge request created: !$mr_number"
  echo ""
  # Show MR URL
  glab mr view $mr_number --json | grep '"web_url"' | cut -d'"' -f4
else
  echo "❌ Failed to create merge request"
  echo "$mr_output"
  exit 1
fi
```

### 6. Update Epic Documentation

Update the epic status with MR information:
```bash
cd {main-repo-path}

# Add MR reference to epic.md
current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat >> .claude/epics/$ARGUMENTS/epic.md << EOF

## Merge Request
- MR: !$mr_number
- Created: $current_date
- Status: pending review
EOF

echo "📝 Updated epic documentation with MR reference"
```

### 7. Link Issues to MR (Optional)

If there are related issues, link them:
```bash
# Get epic issue number
epic_issue=$(grep 'gitlab:' .claude/epics/$ARGUMENTS/epic.md | grep -oE '[0-9]+$')

if [ ! -z "$epic_issue" ]; then
  cd ../epic-$ARGUMENTS
  glab mr update $mr_number --description "$(cat /tmp/epic-mr-description.md)

Closes #$epic_issue"
  echo "🔗 Linked issue #$epic_issue to MR"
fi
```

### 8. Final Output

```
✅ Merge Request Created Successfully: !$mr_number

Epic: $ARGUMENTS
Branch: epic/$ARGUMENTS → main
Status: Ready for review

Next steps:
  1. Review the MR in GitLab
  2. Run CI/CD pipelines
  3. Get approvals from team
  4. Merge via GitLab UI
  5. Run: /pm:epic-cleanup $ARGUMENTS (after merge)

View MR: glab mr view $mr_number
Open in browser: glab mr view $mr_number --web

The worktree remains active at: ../epic-$ARGUMENTS
You can continue making changes and push updates to the MR.
```

## Important Notes

- Always ensure all changes are committed before creating MR
- The branch must be pushed to origin before creating MR
- MR description is auto-generated from epic documentation
- Source branch will be deleted after merge (--remove-source-branch flag)
- Worktree is preserved for continued work until cleanup
- Use `/pm:epic-cleanup` after MR is merged to remove worktree