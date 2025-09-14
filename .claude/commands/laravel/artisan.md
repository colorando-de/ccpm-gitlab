---
allowed-tools: Bash, Read, Write, LS, Task
---

# Laravel Artisan

Execute any Laravel Artisan command with automatic project detection.

## Usage
```
/laravel:artisan [command] [options]
```

## Instructions

### 1. Check Laravel Project
```bash
if [ ! -f "artisan" ]; then
    echo "❌ Not a Laravel project (artisan file not found)"
    exit 1
fi
```

### 2. Check for MCP
If laravel-boost MCP is available and has a matching command, prefer using it.

### 3. Execute Command

If no arguments provided, show available commands:
```bash
php artisan list
```

Otherwise execute the command:
```bash
php artisan $ARGUMENTS
```

## Common Commands

### Cache Management
```bash
php artisan cache:clear      # Clear application cache
php artisan config:clear     # Clear configuration cache
php artisan route:clear      # Clear route cache
php artisan view:clear       # Clear compiled views
php artisan optimize:clear   # Clear all caches

php artisan config:cache     # Cache configuration
php artisan route:cache      # Cache routes
php artisan view:cache       # Cache views
php artisan optimize         # Cache everything
```

### Database
```bash
php artisan migrate          # Run migrations
php artisan migrate:rollback # Rollback last batch
php artisan migrate:fresh    # Drop all tables and migrate
php artisan db:seed          # Run seeders
php artisan migrate:status   # Show migration status
```

### Development
```bash
php artisan serve            # Start development server
php artisan tinker           # Start REPL
php artisan make:model       # Create model
php artisan make:controller  # Create controller
php artisan make:migration   # Create migration
php artisan make:seeder      # Create seeder
php artisan make:test        # Create test
```

### Queue Management
```bash
php artisan queue:work       # Process queue jobs
php artisan queue:listen     # Listen for queue jobs
php artisan queue:failed     # List failed jobs
php artisan queue:retry      # Retry failed job
php artisan queue:flush      # Delete all failed jobs
```

### Maintenance
```bash
php artisan down             # Put application in maintenance mode
php artisan up               # Bring application out of maintenance
php artisan key:generate     # Generate application key
```

### Testing
```bash
php artisan test             # Run tests
php artisan test --parallel  # Run tests in parallel
php artisan test --filter    # Run specific tests
```

## Output Format

**Success:**
```
✅ Artisan command executed:
{command_output}
```

**Failure:**
```
❌ Artisan command failed:
{error_message}
```

## Error Handling

- Command not found → Check spelling, run `php artisan list`
- Database errors → Check .env configuration
- Permission errors → Check file permissions
- Class not found → Run `composer dump-autoload`

## Best Practices

1. Always clear caches after config changes
2. Use `--help` flag to see command options
3. Run migrations with `--pretend` first to preview
4. Use maintenance mode during deployments
5. Cache routes/config in production only