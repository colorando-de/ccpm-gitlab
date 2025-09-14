#!/bin/bash

echo "Initializing..."
echo ""
echo ""

echo " ██████╗ ██████╗██████╗ ███╗   ███╗"
echo "██╔════╝██╔════╝██╔══██╗████╗ ████║"
echo "██║     ██║     ██████╔╝██╔████╔██║"
echo "╚██████╗╚██████╗██║     ██║ ╚═╝ ██║"
echo " ╚═════╝ ╚═════╝╚═╝     ╚═╝     ╚═╝"

echo "┌─────────────────────────────────┐"
echo "│ Claude Code Project Management  │"
echo "│ by https://x.com/aroussi        │"
echo "└─────────────────────────────────┘"
echo "https://github.com/colorando-de/ccpm-gitlab"
echo ""
echo ""

echo "🚀 Initializing Claude Code PM System"
echo "======================================"
echo ""

# Check for required tools
echo "🔍 Checking dependencies..."

# Check glab CLI
if command -v glab &> /dev/null; then
  echo "  ✅ GitLab CLI (glab) installed"
else
  echo "  ❌ GitLab CLI (glab) not found"
  echo ""
  echo "  Installing glab..."
  if command -v brew &> /dev/null; then
    brew install glab
  elif command -v apt-get &> /dev/null; then
    # For Debian/Ubuntu based systems
    curl -s https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest/downloads/glab_amd64.deb -L -o glab.deb
    sudo dpkg -i glab.deb
    rm glab.deb
  else
    echo "  Please install GitLab CLI manually: https://gitlab.com/gitlab-org/cli"
    exit 1
  fi
fi

# Check glab auth status
echo ""
echo "🔐 Checking GitLab authentication..."
if glab auth status &> /dev/null; then
  echo "  ✅ GitLab authenticated"
else
  echo "  ⚠️ GitLab not authenticated"
  echo "  Running: glab auth login"
  glab auth login
fi

# Note: GitLab uses native issue relationships instead of extensions
echo ""
echo "📦 Configuring GitLab issue relationships..."
echo "  ℹ️ GitLab uses native issue linking (e.g., #123, !456)"
echo "  ✅ No additional extensions needed"

# Create directory structure
echo ""
echo "📁 Creating directory structure..."
mkdir -p .claude/prds
mkdir -p .claude/epics
mkdir -p .claude/rules
mkdir -p .claude/agents
mkdir -p .claude/scripts/pm
echo "  ✅ Directories created"

# Copy scripts if in main repo
if [ -d "scripts/pm" ] && [ ! "$(pwd)" = *"/.claude"* ]; then
  echo ""
  echo "📝 Copying PM scripts..."
  cp -r scripts/pm/* .claude/scripts/pm/
  chmod +x .claude/scripts/pm/*.sh
  echo "  ✅ Scripts copied and made executable"
fi

# Check for git
echo ""
echo "🔗 Checking Git configuration..."
if git rev-parse --git-dir > /dev/null 2>&1; then
  echo "  ✅ Git repository detected"

  # Check remote
  if git remote -v | grep -q origin; then
    remote_url=$(git remote get-url origin)
    echo "  ✅ Remote configured: $remote_url"
    
    # Check if remote is the CCPM-GitLab template repository
    if [[ "$remote_url" == *"your-org/ccpm-gitlab"* ]] || [[ "$remote_url" == *"your-org/ccpm-gitlab.git"* ]]; then
      echo ""
      echo "  ⚠️ WARNING: Your remote origin points to the CCPM-GitLab template repository!"
      echo "  This means any issues you create will go to the template repo, not your project."
      echo ""
      echo "  To fix this:"
      echo "  1. Fork the repository or create your own on GitLab"
      echo "  2. Update your remote:"
      echo "     git remote set-url origin https://gitlab.com/YOUR_GROUP/YOUR_PROJECT.git"
      echo ""
    fi
  else
    echo "  ⚠️ No remote configured"
    echo "  Add with: git remote add origin <url>"
  fi
else
  echo "  ⚠️ Not a git repository"
  echo "  Initialize with: git init"
fi

# Detect project type
PROJECT_TYPE="generic"
if [ -f "artisan" ] && [ -f "composer.json" ]; then
  if grep -q "laravel/framework" composer.json 2>/dev/null; then
    PROJECT_TYPE="laravel"
    echo ""
    echo "🎼 Laravel project detected!"
  fi
fi

# Create CLAUDE.md if it doesn't exist
if [ ! -f "CLAUDE.md" ]; then
  echo ""
  echo "📄 Creating CLAUDE.md..."

  if [ "$PROJECT_TYPE" = "laravel" ]; then
    cat > CLAUDE.md << 'EOF'
# CLAUDE.md

> Think carefully and implement the most concise solution that changes as little code as possible.

## Project-Specific Instructions

This is a Laravel project. Always check for laravel-boost MCP tools when available.

## Testing

Always run tests before committing:
- `php artisan test` for PHPUnit tests
- `php artisan test --parallel` for faster execution
- Use `php artisan tinker` for quick validation

## Database

- Use migrations: `php artisan migrate`
- Never modify database directly
- Use seeders for test data: `php artisan db:seed`

## Code Style

- Follow PSR-12 coding standards
- Use Laravel's built-in helpers and facades
- Implement repository pattern for complex queries
- Use form requests for validation
- Follow existing patterns in the codebase

## Cache Management

After configuration changes:
- `php artisan config:clear`
- `php artisan cache:clear`
- `php artisan route:clear`
- `php artisan view:clear`
EOF
  else
    cat > CLAUDE.md << 'EOF'
# CLAUDE.md

> Think carefully and implement the most concise solution that changes as little code as possible.

## Project-Specific Instructions

Add your project-specific instructions here.

## Testing

Always run tests before committing:
- `npm test` or equivalent for your stack

## Code Style

Follow existing patterns in the codebase.
EOF
  fi
  echo "  ✅ CLAUDE.md created"
fi

# Summary
echo ""
echo "✅ Initialization Complete!"
echo "=========================="
echo ""
echo "📊 System Status:"
glab --version | head -1
echo "  Auth: $(glab auth status 2>&1 | grep -o 'Logged in to [^ ]*' || echo 'Not authenticated')"
echo ""
echo "🎯 Next Steps:"
echo "  1. Create your first PRD: /pm:prd-new <feature-name>"
echo "  2. View help: /pm:help"
echo "  3. Check status: /pm:status"
echo ""
echo "📚 Documentation: README.md"

exit 0
