---
allowed-tools: Bash, Read, Write, LS, Task
---

# Laravel Tinker

Interactive Laravel REPL for testing code snippets and database queries.

## Usage
```
/laravel:tinker [code]
```

Where `code` can be:
- Empty (start interactive session - not recommended in Claude)
- PHP code snippet to execute
- File path containing PHP code

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
- `mcp__laravel-boost__tinker`

### 3. Execute Code

For code snippets:
```bash
# Single line
php artisan tinker --execute="$CODE"

# Multi-line using heredoc
php artisan tinker <<'EOF'
$user = User::first();
echo $user->email;
EOF
```

For testing:
```bash
# Quick model test
php artisan tinker --execute="User::count()"

# Test relationships
php artisan tinker <<'EOF'
$post = Post::with('comments')->first();
echo $post->comments->count();
EOF
```

### 4. Common Use Cases

**Test Database Queries:**
```php
// Count records
Model::count()

// Test scopes
User::active()->count()

// Test relationships
User::first()->posts()->count()
```

**Test Helpers:**
```php
// Test custom helpers
app('helper.name')->method()

// Test facades
Cache::get('key')
Storage::exists('file.txt')
```

**Quick Validation:**
```php
// Test validation rules
$validator = Validator::make(['email' => 'test'], ['email' => 'required|email']);
var_dump($validator->fails());
```

### 5. Output Handling

**Success:**
```
✅ Tinker output:
{result}
```

**Error:**
```
❌ Tinker error:
{error_message}

Check:
- Syntax errors in code
- Model/class exists
- Database connection
- Required use statements
```

## Best Practices

1. Use for quick validation, not complex logic
2. Prefer actual test files for persistent tests
3. Be careful with database modifications
4. Use transactions for testing:
   ```php
   DB::beginTransaction();
   // test code
   DB::rollBack();
   ```

## Common Commands

```bash
# Clear Laravel caches from tinker
php artisan tinker --execute="Artisan::call('cache:clear')"

# Get environment info
php artisan tinker --execute="echo app()->environment()"

# Test mail configuration
php artisan tinker --execute="Mail::raw('Test', fn(\$m) => \$m->to('test@example.com')->subject('Test'))"
```