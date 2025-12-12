# Testing Azure Artifacts Helper

This document describes how to test the artifacts-helper feature, particularly the authentication wait behavior and shim script resilience.

## Test Scenarios

### 1. Authentication Wait Test (`test_auth_wait`)

**Purpose**: Verify that the auth-ado.sh script can be sourced without terminating the parent shell.

**What it tests**:
- Shim scripts exist in `/usr/local/share/codespace-shims/`
- `auth-ado.sh` can be sourced multiple times without crashing
- Sourcing the script doesn't terminate the parent shell even on error

**Expected behavior**:
- Scripts are executable and in the correct location
- Sourcing auth-ado.sh returns control to the caller
- Parent shell continues executing after sourcing fails

### 2. Shim Integration Test (`test_shim_integration`)

**Purpose**: Test that shim scripts properly handle missing authentication helper.

**What it tests**:
- Shim scripts source auth-ado.sh correctly
- Scripts handle timeout gracefully when ado-auth-helper is missing
- Shim directory is in PATH
- Scripts don't crash when authentication fails

**Expected behavior**:
- Shims wait for up to 3 minutes for authentication
- Timeout error is returned but doesn't crash the script
- Calling scripts can continue or handle error appropriately

### 3. Python Keyring Tests

Multiple scenarios test Python integration:
- `python38_and_keyring_debian`: Python 3.8 on Debian with keyring
- `python38_and_keyring_ubuntu`: Python 3.8 on Ubuntu with keyring
- `python312_and_keyring_debian`: Python 3.12 on Debian with keyring
- `python_and_no_keyring`: Python without keyring helper

## Running Tests

### Run All Tests

```bash
cd /path/to/codespace-features
devcontainer features test -f artifacts-helper
```

### Run Specific Test Scenario

```bash
devcontainer features test -f artifacts-helper --scenario test_auth_wait
devcontainer features test -f artifacts-helper --scenario test_shim_integration
```

### Run Individual Test Script

If you want to test a specific script in an already-built container:

```bash
# Inside a devcontainer with artifacts-helper installed
bash /path/to/test/artifacts-helper/test_auth_wait.sh
```

## Manual Testing

### Test Authentication Wait Behavior

1. Create a test devcontainer with artifacts-helper feature
2. Remove or delay the ado-auth-helper installation
3. Try to run a package manager command (e.g., `dotnet restore`)
4. Observe that the script waits and shows progress
5. Verify the script eventually times out with error but doesn't crash

```bash
# Mock a scenario where ado-auth-helper is missing
rm -f ~/ado-auth-helper

# Try to run dotnet - should wait and timeout gracefully
timeout 10 dotnet --version
echo "Exit code: $?"  # Should be non-zero but script continues

# Verify we can still run commands
echo "Shell is still active"
```

### Test Shim Sourcing Behavior

```bash
# Test that sourcing doesn't exit the shell
bash -c '
    source /usr/local/share/codespace-shims/auth-ado.sh 2>/dev/null || echo "Returned with error"
    echo "Shell still running"
'
```

### Test with Actual Authentication

1. Set up a codespace with the ADO Codespaces Auth extension
2. Configure an Azure Artifacts feed
3. Wait for ado-auth-helper to be installed
4. Run package restore commands
5. Verify authentication succeeds

## What Changed in PR #85

The key changes improve resilience when the authentication helper isn't immediately available:

1. **Added wait loop**: Scripts now wait up to 3 minutes for ado-auth-helper
2. **Removed `set -e`**: Prevents sourced script from terminating parent shell
3. **Changed `exit` to `return`**: Allows error handling in calling scripts
4. **Added progress indicators**: Shows wait progress every 20 seconds
5. **Fixed PATH**: Uses hardcoded `/usr/local/share/codespace-shims` instead of variable

## Troubleshooting Test Failures

### "auth-ado.sh terminates shell"
- Check that `set -e` is removed from auth-ado.sh
- Verify `return 1` is used instead of `exit 1`

### "Shim scripts not found"
- Verify PATH includes `/usr/local/share/codespace-shims`
- Check that install.sh properly creates the shim scripts
- Ensure containerEnv in devcontainer-feature.json is correct

### "Tests timeout"
- Reduce MAX_WAIT in auth-ado.sh for faster testing
- Use `timeout` command to limit test duration
- Check that progress indicators are working

## CI/CD Integration

These tests are designed to work with the devcontainer features test framework and can be integrated into CI/CD pipelines:

```yaml
- name: Test artifacts-helper feature
  run: |
    devcontainer features test -f artifacts-helper
```
