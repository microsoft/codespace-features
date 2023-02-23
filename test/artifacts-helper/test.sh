#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "dotnet" grep "pkgs.dev.azure.com" <(cat /usr/local/bin/run-dotnet.sh)
check "nuget" grep "pkgs.dev.azure.com" <(cat /usr/local/bin/run-nuget.sh)
/usr/local/bin/write-npm.sh pkgs.dev.azure.com
check "npm" grep "pkgs.dev.azure.com" <(cat ~/.npmrc)


# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults