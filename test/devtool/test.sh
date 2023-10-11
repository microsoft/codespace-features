#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "devtool" grep "DevTool" <(cat ~/.bashrc)

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults