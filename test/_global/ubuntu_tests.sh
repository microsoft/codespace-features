#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

check "git-version" bash -c "git --version | grep 'vfs'"
check "no-dirs"  grep -v "drwxr" <(ls -l /tmp/debian_tests)
check "git-config" grep "ado-helper" <(cat /tmp/debian_tests/.git/config)
check "dotnet" grep "pkgs.dev.azure.com" <(cat /usr/local/bin/run-dotnet.sh)
check "nuget" grep "pkgs.dev.azure.com" <(cat /usr/local/bin/run-nuget.sh)

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults