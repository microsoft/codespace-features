#!/usr/bin/env bash

# Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib || exit 1

# Test that shims properly handle the case when ado-auth-helper is not available
# The shim should wait and eventually timeout, but not crash the script

# Test dotnet shim can be invoked (will timeout waiting for auth but shouldn't crash)
check "dotnet shim handles missing auth helper" bash -c '
    # Mock a quick timeout scenario
    export HOME=$(mktemp -d)
    timeout 5 /usr/local/share/codespace-shims/dotnet --version 2>&1 || exit_code=$?
    # Exit code 124 means timeout killed it, which is expected
    # Exit code 1 means it returned error but script continued
    # Exit code 0 means it succeeded (if auth helper was present)
    [[ $exit_code -eq 124 || $exit_code -eq 1 || $exit_code -eq 0 ]]
'

# Test that the shim scripts properly source auth-ado.sh
check "dotnet shim sources auth-ado.sh" grep -q "source.*auth-ado.sh" /usr/local/share/codespace-shims/dotnet
check "npm shim sources auth-ado.sh" grep -q "source.*auth-ado.sh" /usr/local/share/codespace-shims/npm

# Verify the shim directory is in PATH
check "shim directory in PATH" bash -c '[[ ":$PATH:" == *":/usr/local/share/codespace-shims:"* ]]'

# Report results
reportResults
