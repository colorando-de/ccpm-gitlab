# Laravel Operations Rules

## MCP Integration
When working with Laravel projects, always check for and prefer laravel-boost MCP tools when available:
- Use `mcp__laravel-boost__*` tools for Laravel-specific operations
- Fallback to standard tools only when MCP is unavailable

## CLAUDE.md Loading
Always read configuration from TWO locations:
1. `.claude/CLAUDE.md` - Claude-specific configurations
2. `./CLAUDE.md` (project root) - Project-specific instructions

Merge both configurations, with project root taking precedence for conflicts.

## Testing Framework
For Laravel projects, use the following test execution hierarchy:
1. If MCP available: `mcp__laravel-boost__test`
2. Otherwise: `php artisan test`
3. For specific tests: `php artisan test --filter TestName`
4. For parallel execution: `php artisan test --parallel`

## Tinker Integration
Use Laravel Tinker for temporary code validation:
1. If MCP available: `mcp__laravel-boost__tinker`
2. Otherwise: `php artisan tinker` with heredoc input
3. For quick validation without creating test files

## Database Operations
- Always use migrations: `php artisan migrate`
- Never modify database directly
- Use seeders for test data: `php artisan db:seed`
- Rollback with: `php artisan migrate:rollback`

## Artisan Commands
Common operations to use:
- `php artisan cache:clear` - Clear application cache
- `php artisan config:clear` - Clear configuration cache
- `php artisan route:clear` - Clear route cache
- `php artisan view:clear` - Clear compiled views
- `php artisan optimize` - Cache everything for production

## File Structure
Laravel project detection markers:
- `artisan` file in root
- `composer.json` with "laravel/framework" dependency
- `app/`, `routes/`, `resources/` directories
- `.env` and `.env.example` files

## Error Handling
Laravel-specific error patterns to watch for:
- "Class not found" - Run `composer dump-autoload`
- "No application encryption key" - Run `php artisan key:generate`
- Migration errors - Check database connection in `.env`
- Permission errors - Check `storage/` and `bootstrap/cache/` permissions

## Best Practices
1. Always use Eloquent ORM instead of raw queries
2. Use Laravel's validation rules
3. Follow PSR-4 autoloading standards
4. Use Laravel's built-in helpers and facades
5. Implement tests using PHPUnit or Pest
6. Use database transactions in tests
7. Clear caches after configuration changes