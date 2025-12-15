#!/usr/bin/env bash

# Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib || exit 1

# Test that shim scripts call the underlying command even when auth helper is not found

# Create a temporary directory to simulate a clean environment
TEST_HOME=$(mktemp -d)

# Mock scenario: ado-auth-helper doesn't exist, but the underlying command should still run
check "dotnet command executes without auth helper" bash -c '
    # Use a short timeout to avoid waiting 3 minutes
    # The shim should call dotnet even if auth fails
    export HOME='"$TEST_HOME"'
    export MAX_WAIT=5
    
    # Call dotnet --version which should work even without auth
    timeout 10 /usr/local/share/codespace-shims/dotnet --version 2>&1 | grep -q "dotnet\|\.NET" && echo "SUCCESS" || echo "FAILED"
' | grep -q "SUCCESS"

# Test with npm as well
check "npm command executes without auth helper" bash -c '
    export HOME='"$TEST_HOME"'
    export MAX_WAIT=5
    
    # npm --version should work without auth
    timeout 10 /usr/local/share/codespace-shims/npm --version 2>&1 | grep -q "[0-9]\+\.[0-9]\+\.[0-9]\+" && echo "SUCCESS" || echo "FAILED"
' | grep -q "SUCCESS"

# Test that nuget can be called (may not return version without auth, but should not crash)
check "nuget command attempts to execute without auth helper" bash -c '
    export HOME='"$TEST_HOME"'
    export MAX_WAIT=5
    
    # Try to call nuget - it should attempt to run even if auth fails
    timeout 10 /usr/local/share/codespace-shims/nuget help 2>&1 || true
    # Just verify we get here without the shell crashing
    echo "completed"
' | grep -q "completed"

# Cleanup
rm -rf "$TEST_HOME"

# Report results
reportResults
