#!/bin/bash

# Script to run tests with automatic log redirection
# Supports both Laravel and Python projects
# Usage: ./claude/scripts/test-and-log.sh [test_path] [optional_log_name.log]

# Detect if this is a Laravel project
IS_LARAVEL=false
if [ -f "artisan" ]; then
    IS_LARAVEL=true
fi

# Laravel project handling
if [ "$IS_LARAVEL" = true ]; then
    # Create logs directory if it doesn't exist
    mkdir -p storage/logs/tests

    # For Laravel, first argument is optional (filter or test path)
    if [ $# -eq 0 ]; then
        # Run all tests
        echo "Running all Laravel tests..."
        LOG_FILE="storage/logs/tests/test_$(date +%Y%m%d_%H%M%S).log"
        php artisan test > "$LOG_FILE" 2>&1
    elif [ $# -eq 1 ]; then
        TEST_FILTER="$1"
        LOG_FILE="storage/logs/tests/test_$(date +%Y%m%d_%H%M%S).log"

        # Check if it's a file path or a filter
        if [ -f "$TEST_FILTER" ]; then
            echo "Running Laravel test file: $TEST_FILTER"
            php artisan test "$TEST_FILTER" > "$LOG_FILE" 2>&1
        else
            echo "Running Laravel tests with filter: $TEST_FILTER"
            php artisan test --filter "$TEST_FILTER" > "$LOG_FILE" 2>&1
        fi
    else
        # Custom log name provided
        TEST_FILTER="$1"
        LOG_NAME="$2"
        if [[ ! "$LOG_NAME" == *.log ]]; then
            LOG_NAME="${LOG_NAME}.log"
        fi
        LOG_FILE="storage/logs/tests/${LOG_NAME}"

        if [ -f "$TEST_FILTER" ]; then
            echo "Running Laravel test file: $TEST_FILTER"
            php artisan test "$TEST_FILTER" > "$LOG_FILE" 2>&1
        else
            echo "Running Laravel tests with filter: $TEST_FILTER"
            php artisan test --filter "$TEST_FILTER" > "$LOG_FILE" 2>&1
        fi
    fi

    echo "Logging to: $LOG_FILE"

# Python/other project handling
else
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <test_file_path> [log_filename]"
        echo "Example: $0 tests/e2e/my_test_name.py"
        echo "Example: $0 tests/e2e/my_test_name.py my_test_name_v2.log"
        exit 1
    fi

    TEST_PATH="$1"

    # Create logs directory if it doesn't exist
    mkdir -p tests/logs

    # Determine log file name
    if [ $# -ge 2 ]; then
        # Use provided log filename (second parameter)
        LOG_NAME="$2"
        # Ensure it ends with .log
        if [[ ! "$LOG_NAME" == *.log ]]; then
            LOG_NAME="${LOG_NAME}.log"
        fi
        LOG_FILE="tests/logs/${LOG_NAME}"
    else
        # Extract the test filename without extension for the log name
        TEST_NAME=$(basename "$TEST_PATH" .py)
        LOG_FILE="tests/logs/${TEST_NAME}.log"
    fi

    # Run the test with output redirection
    echo "Running test: $TEST_PATH"
    echo "Logging to: $LOG_FILE"
    python "$TEST_PATH" > "$LOG_FILE" 2>&1
fi

# Check exit code
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Test completed successfully. Log saved to $LOG_FILE"
else
    echo "❌ Test failed with exit code $EXIT_CODE. Check $LOG_FILE for details"
fi

exit $EXIT_CODE
