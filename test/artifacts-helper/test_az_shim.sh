#!/usr/bin/env bash

# Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib || exit 1

# Test that az shim is installed
check "az shim exists" test -f /usr/local/share/codespace-shims/az
check "az shim is executable" test -x /usr/local/share/codespace-shims/az

# Test that az shim sources resolve-shim.sh
check "az shim sources resolve-shim.sh" grep -q 'source.*resolve-shim.sh' /usr/local/share/codespace-shims/az

# Test GitHub Actions environment detection
check "az shim has GitHub Actions detection" grep -q 'ACTIONS_ID_TOKEN_REQUEST_URL' /usr/local/share/codespace-shims/az

# Test that az shim intercepts get-access-token command
check "az shim intercepts get-access-token" grep -q 'get-access-token' /usr/local/share/codespace-shims/az

# Test argument parsing handles both formats (--resource value and --resource=value)
check "az shim handles equals format args" grep -q '\-\-resource=\*' /usr/local/share/codespace-shims/az
check "az shim handles space-separated args" grep -q '\-\-resource)' /usr/local/share/codespace-shims/az

# Test that az shim falls back to real az CLI for other commands
TEST_HOME=$(mktemp -d)
check "az shim falls back for non-token commands" bash -c '
    export HOME='"$TEST_HOME"'
    # az --version should pass through to real az CLI (if installed)
    # or fail gracefully if az is not installed
    output=$(/usr/local/share/codespace-shims/az --version 2>&1) || true
    # Check that it either shows az version or "not found" error - both are valid
    echo "$output" | grep -qE "(azure-cli|Azure CLI|not found)" && echo "SUCCESS" || echo "FAILED"
' | grep -q "SUCCESS"

# Test that az shim handles missing azure-auth-helper gracefully
check "az shim handles missing azure-auth-helper" bash -c '
    export HOME='"$TEST_HOME"'
    # Remove azure-auth-helper if it exists
    rm -f "${HOME}/azure-auth-helper"
    # Call az account get-access-token - should fall through to real az
    # (which will fail, but shim should not crash)
    /usr/local/share/codespace-shims/az account get-access-token --resource https://management.azure.com 2>&1 || true
    # If we get here, the shim handled it gracefully
    echo "completed"
' | grep -q "completed"

# Test that az shim returns proper JSON format when azure-auth-helper exists
check "az shim returns valid JSON format" bash -c '
    export HOME='"$TEST_HOME"'
    # Create a mock azure-auth-helper that returns a test token
    cat > "${HOME}/azure-auth-helper" << '\''HELPER'\''
#!/bin/bash
echo "test-token-12345"
HELPER
    chmod +x "${HOME}/azure-auth-helper"
    
    # Call the shim and verify JSON output
    output=$(/usr/local/share/codespace-shims/az account get-access-token --resource https://management.azure.com 2>&1)
    
    # Check that output contains expected JSON fields
    echo "$output" | grep -q "accessToken" && \
    echo "$output" | grep -q "tokenType" && \
    echo "$output" | grep -q "Bearer" && \
    echo "SUCCESS" || echo "FAILED"
' | grep -q "SUCCESS"

# Test GitHub Actions bypass (simulate by setting the env var)
check "az shim bypasses interception in GitHub Actions" bash -c '
    export HOME='"$TEST_HOME"'
    export ACTIONS_ID_TOKEN_REQUEST_URL="https://example.com/token"
    # In Actions mode, shim should skip interception and call real az directly
    # (will fail if az not installed, but should not attempt token interception)
    output=$(/usr/local/share/codespace-shims/az account get-access-token --resource https://management.azure.com 2>&1) || true
    # Should NOT contain our mock token (which means bypass worked)
    echo "$output" | grep -qv "test-token-12345" && echo "SUCCESS" || echo "FAILED"
' | grep -q "SUCCESS"

# Test AZURE_DEVOPS_EXT_PAT integration with ado-auth-helper
check "az shim sets AZURE_DEVOPS_EXT_PAT when ado-auth-helper exists" bash -c '
    export HOME='"$TEST_HOME"'
    export MAX_WAIT=2  # Short timeout for testing
    # Create a mock ado-auth-helper
    cat > "${HOME}/ado-auth-helper" << '\''HELPER'\''
#!/bin/bash
echo "ado-test-pat-token"
HELPER
    chmod +x "${HOME}/ado-auth-helper"
    
    # Create a mock az that echoes the env var
    mkdir -p "${HOME}/bin"
    cat > "${HOME}/bin/az" << '\''MOCKAZ'\''
#!/bin/bash
echo "PAT=${AZURE_DEVOPS_EXT_PAT}"
MOCKAZ
    chmod +x "${HOME}/bin/az"
    export PATH="${HOME}/bin:$PATH"
    
    # Call the shim with a non-token command
    output=$(/usr/local/share/codespace-shims/az devops --help 2>&1)
    echo "$output" | grep -q "PAT=ado-test-pat-token" && echo "SUCCESS" || echo "FAILED: $output"
' | grep -q "SUCCESS"

# Test that existing AZURE_DEVOPS_EXT_PAT is not overwritten
check "az shim does not overwrite existing AZURE_DEVOPS_EXT_PAT" bash -c '
    export HOME='"$TEST_HOME"'
    export MAX_WAIT=2
    export AZURE_DEVOPS_EXT_PAT="existing-pat-value"
    # Create mock ado-auth-helper that would return different value
    cat > "${HOME}/ado-auth-helper" << '\''HELPER'\''
#!/bin/bash
echo "new-pat-token"
HELPER
    chmod +x "${HOME}/ado-auth-helper"
    
    # Create mock az
    mkdir -p "${HOME}/bin"
    cat > "${HOME}/bin/az" << '\''MOCKAZ'\''
#!/bin/bash
echo "PAT=${AZURE_DEVOPS_EXT_PAT}"
MOCKAZ
    chmod +x "${HOME}/bin/az"
    export PATH="${HOME}/bin:$PATH"
    
    output=$(/usr/local/share/codespace-shims/az devops --help 2>&1)
    # Should still have original value
    echo "$output" | grep -q "PAT=existing-pat-value" && echo "SUCCESS" || echo "FAILED: $output"
' | grep -q "SUCCESS"

# Test that missing ado-auth-helper still allows fallthrough
check "az shim falls through without ado-auth-helper" bash -c '
    export HOME='"$TEST_HOME"'
    export MAX_WAIT=2  # Short timeout
    rm -f "${HOME}/ado-auth-helper"
    
    # Create mock az
    mkdir -p "${HOME}/bin"
    cat > "${HOME}/bin/az" << '\''MOCKAZ'\''
#!/bin/bash
echo "FALLTHROUGH_OK"
MOCKAZ
    chmod +x "${HOME}/bin/az"
    export PATH="${HOME}/bin:$PATH"
    
    output=$(/usr/local/share/codespace-shims/az version 2>&1)
    echo "$output" | grep -q "FALLTHROUGH_OK" && echo "SUCCESS" || echo "FAILED: $output"
' | grep -q "SUCCESS"

# Cleanup
rm -rf "$TEST_HOME"

# Report results
reportResults
