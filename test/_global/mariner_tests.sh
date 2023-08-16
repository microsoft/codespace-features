#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

check "git-version" bash -c "git --version | grep 'vfs'"
check "gcm-version" grep "2.0\." <(git-credential-manager --version)
check "no-dirs"  grep -v "drwxr" <(ls -l /tmp/mariner_tests)
check "git-config" grep "ado-auth-helper" <(cat /tmp/mariner_tests/.git/config)
check "dotnet" grep "pkgs.dev.azure.com" <(cat /usr/local/bin/run-dotnet.sh)
check "nuget" grep "pkgs.dev.azure.com" <(cat /usr/local/bin/run-nuget.sh)
check "docfx-version" bash -c "docfx --version"

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults