#!/usr/bin/env bash

# Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib || exit 1

# Test that the shim scripts exist and can be sourced
check "dotnet shim exists" test -f /usr/local/share/codespace-shims/dotnet
check "npm shim exists" test -f /usr/local/share/codespace-shims/npm
check "nuget shim exists" test -f /usr/local/share/codespace-shims/nuget

# Test that auth-ado.sh can be sourced without exiting the shell
check "auth-ado.sh can be sourced" bash -c 'source /usr/local/share/codespace-shims/auth-ado.sh 2>/dev/null || true; echo "still running"'

# Test that sourcing auth-ado.sh doesn't terminate the parent shell
check "sourcing auth-ado.sh preserves shell" bash -c '
    source /usr/local/share/codespace-shims/auth-ado.sh 2>/dev/null || true
    echo "completed"
' | grep -q "completed"

# Test that the shim scripts can be executed
check "dotnet shim is executable" test -x /usr/local/share/codespace-shims/dotnet
check "npm shim is executable" test -x /usr/local/share/codespace-shims/npm

# Report results
reportResults
