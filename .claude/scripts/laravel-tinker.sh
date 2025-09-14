#!/bin/bash

# Laravel Tinker execution script
# Usage: ./claude/scripts/laravel-tinker.sh "code" [log_filename]

# Check if this is a Laravel project
if [ ! -f "artisan" ]; then
    echo "❌ Not a Laravel project (artisan file not found)"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "Usage: $0 \"<php_code>\" [log_filename]"
    echo "Example: $0 \"User::count()\""
    echo "Example: $0 \"User::first()->email\" user_check.log"
    exit 1
fi

CODE="$1"

# Create logs directory if it doesn't exist
mkdir -p storage/logs/tinker

# Determine log file name
if [ $# -ge 2 ]; then
    LOG_NAME="$2"
    if [[ ! "$LOG_NAME" == *.log ]]; then
        LOG_NAME="${LOG_NAME}.log"
    fi
    LOG_FILE="storage/logs/tinker/${LOG_NAME}"
else
    LOG_FILE="storage/logs/tinker/tinker_$(date +%Y%m%d_%H%M%S).log"
fi

echo "🎹 Running Laravel Tinker..."
echo "Code: $CODE"
echo "Logging to: $LOG_FILE"

# Execute code with tinker
if [[ "$CODE" == *$'\n'* ]]; then
    # Multi-line code - use heredoc
    php artisan tinker <<EOF > "$LOG_FILE" 2>&1
$CODE
exit
EOF
else
    # Single line - use --execute
    php artisan tinker --execute="$CODE" > "$LOG_FILE" 2>&1
fi

EXIT_CODE=$?

# Display output
if [ -f "$LOG_FILE" ]; then
    echo ""
    echo "Output:"
    echo "-------"
    cat "$LOG_FILE"
    echo "-------"
fi

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Tinker execution completed successfully"
else
    echo "❌ Tinker execution failed with exit code $EXIT_CODE"
fi

exit $EXIT_CODE