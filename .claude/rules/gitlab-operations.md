# GitLab Operations Rule

Standard patterns for GitLab CLI operations across all commands.

## CRITICAL: Repository Protection

**Before ANY GitLab operation that creates/modifies issues or PRs:**

```bash
# Check if remote origin is the CCPM template repository
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$remote_url" == *"your-org/ccpm-gitlab"* ]] || [[ "$remote_url" == *"your-org/ccpm-gitlab.git"* ]]; then
  echo "❌ ERROR: You're trying to sync with the CCPM template repository!"
  echo ""
  echo "This repository (your-org/ccpm-gitlab) is a template for others to use."
  echo "You should NOT create issues or PRs here."
  echo ""
  echo "To fix this:"
  echo "1. Fork this repository to your own GitLab account"
  echo "2. Update your remote origin:"
  echo "   git remote set-url origin https://gitlab.com/YOUR_USERNAME/YOUR_REPO.git"
  echo ""
  echo "Or if this is a new project:"
  echo "1. Create a new repository on GitLab"
  echo "2. Update your remote origin:"
  echo "   git remote set-url origin https://gitlab.com/YOUR_USERNAME/YOUR_REPO.git"
  echo ""
  echo "Current remote: $remote_url"
  exit 1
fi
```

This check MUST be performed in ALL commands that:
- Create issues (`glab issue create`)
- Edit issues (`glab issue edit`)
- Comment on issues (`glab issue comment`)
- Create PRs (`glab pr create`)
- Any other operation that modifies the GitLab repository

## Authentication

**Don't pre-check authentication.** Just run the command and handle failure:

```bash
glab {command} || echo "❌ GitLab CLI failed. Run: glab auth login"
```

## Common Operations

### Get Issue Details
```bash
glab issue view {number} --json state,title,labels,body
```

### Create Issue
```bash
# ALWAYS check remote origin first!
glab issue create --title "{title}" --description-file {file} --label "{labels}"
```

### Update Issue
```bash
# ALWAYS check remote origin first!
glab issue edit {number} --add-label "{label}" --add-assignee @me
```

### Add Comment
```bash
# ALWAYS check remote origin first!
glab issue comment {number} --description-file {file}
```

## Error Handling

If any glab command fails:
1. Show clear error: "❌ GitLab operation failed: {command}"
2. Suggest fix: "Run: glab auth login" or check issue number
3. Don't retry automatically

## Important Notes

- **ALWAYS** check remote origin before ANY write operation to GitLab
- Trust that glab CLI is installed and authenticated
- Use --json for structured output when parsing
- Keep operations atomic - one glab command per action
- Don't check rate limits preemptively
