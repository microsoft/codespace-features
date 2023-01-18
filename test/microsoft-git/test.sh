#!/bin/bash

set -e

source dev-container-features-test-lib

check "version" bash -c "git --version | grep 'vfs'"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults