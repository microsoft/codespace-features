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
check "corepack shim sources auth-ado.sh" grep -q "source.*auth-ado.sh" /usr/local/share/codespace-shims/corepack

# Verify the shim directory is in PATH
check "shim directory in PATH" bash -c '[[ ":$PATH:" == *":/usr/local/share/codespace-shims:"* ]]'

# Verify that shell function shims are written to rc files (not just shim scripts)
check "npm shell function written to bash.bashrc" grep -q "npm()" /etc/bash.bashrc
check "corepack shell function written to bash.bashrc" grep -q "corepack()" /etc/bash.bashrc
check "dotnet shell function written to bash.bashrc" grep -q "dotnet()" /etc/bash.bashrc
check "npm shell function on its own line in bash.bashrc" grep -q "^npm()" /etc/bash.bashrc

# Verify aliases include proper quoting and argument passing ($@)
check "dotnet alias has quoted path and passes args" grep -q 'dotnet() { ".*/dotnet" "\$@"; }' /etc/bash.bashrc
check "npm alias has quoted path and passes args" grep -q 'npm() { ".*/npm" "\$@"; }' /etc/bash.bashrc
check "corepack alias has quoted path and passes args" grep -q 'corepack() { ".*/corepack" "\$@"; }' /etc/bash.bashrc

# Verify Corepack lifecycle commands target the real binary directory rather than the shim directory.
check "corepack enable targets the real binary directory" bash -c '
    TEST_DIR=$(mktemp -d)
    trap "rm -rf \"$TEST_DIR\"" EXIT
    mkdir -p "$TEST_DIR/bin"
    printf "#!/bin/bash\nprintf \"%%s\\n\" \"\$@\" > \"%s/args\"\n" "$TEST_DIR" > "$TEST_DIR/bin/corepack"
    chmod +x "$TEST_DIR/bin/corepack"

    PATH="/usr/local/share/codespace-shims:$TEST_DIR/bin:/usr/bin:/bin" \
      ACTIONS_ID_TOKEN_REQUEST_URL=test \
      /usr/local/share/codespace-shims/corepack enable pnpm

    diff -u <(printf "enable\n--install-directory\n%s/bin\npnpm\n" "$TEST_DIR") "$TEST_DIR/args"
'

check "corepack preserves an explicit install directory" bash -c '
    TEST_DIR=$(mktemp -d)
    trap "rm -rf \"$TEST_DIR\"" EXIT
    mkdir -p "$TEST_DIR/bin"
    printf "#!/bin/bash\nprintf \"%%s\\n\" \"\$@\" > \"%s/args\"\n" "$TEST_DIR" > "$TEST_DIR/bin/corepack"
    chmod +x "$TEST_DIR/bin/corepack"

    PATH="/usr/local/share/codespace-shims:$TEST_DIR/bin:/usr/bin:/bin" \
      ACTIONS_ID_TOKEN_REQUEST_URL=test \
      /usr/local/share/codespace-shims/corepack disable --install-directory /tmp/corepack yarn

    diff -u <(printf "disable\n--install-directory\n/tmp/corepack\nyarn\n") "$TEST_DIR/args"
'

# Verify newlines between shim definitions (each function should be on its own line)
check "each shim function is on its own line" bash -c '
    # Count function definitions at line starts - with proper newlines each will start at column 0
    # The test_shim_integration scenario enables dotnet, npm, and nuget aliases (3 shims)
    COUNT=$(grep -cE "^[a-z][-a-z]*\(\)" /etc/bash.bashrc)
    [[ "$COUNT" -ge 3 ]]
'

# Report results
reportResults
