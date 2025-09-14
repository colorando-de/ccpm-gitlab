---
allowed-tools: Bash, Read, Write, LS, Task
---

# Laravel Migrate

Run Laravel database migrations with support for various options.

## Usage
```
/laravel:migrate [options]
```

Options:
- No arguments: Run pending migrations
- `--rollback`: Rollback the last migration batch
- `--fresh`: Drop all tables and re-run all migrations
- `--seed`: Run migrations and seed the database
- `--status`: Show migration status

## Instructions

### 1. Check Laravel Project
```bash
if [ ! -f "artisan" ]; then
    echo "❌ Not a Laravel project (artisan file not found)"
    exit 1
fi
```

### 2. Check for MCP
If laravel-boost MCP is available, prefer using:
- `mcp__laravel-boost__migrate`

### 3. Execute Migration

Based on arguments:

```bash
# Default - run pending migrations
php artisan migrate

# With rollback
php artisan migrate:rollback

# Fresh migration (drops all tables)
php artisan migrate:fresh

# With seeding
php artisan migrate --seed
# or
php artisan migrate:fresh --seed

# Check status
php artisan migrate:status
```

### 4. Handle Output

**Success:**
```
✅ Migrations completed successfully
{migration_output}
```

**Failure:**
```
❌ Migration failed:
{error_message}

Common fixes:
- Check database connection in .env
- Ensure database exists
- Check migration file syntax
- Run: composer dump-autoload
```

### 5. Post-Migration

After successful migration:
```bash
# Clear caches if needed
php artisan cache:clear
php artisan config:clear
```

## Error Handling

- Database connection error → Check .env DB_* settings
- Table already exists → Consider using migrate:fresh
- Class not found → Run composer dump-autoload
- Syntax error → Review migration file at line indicated