#!/bin/bash

set -e

source dev-container-features-test-lib

check "version" bash -c "git --version | grep 'vfs'"
check "clone" scalar clone --single-branch https://github.com/devcontainers/features /tmp/scalar-clone

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults