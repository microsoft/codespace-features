#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "go-version" bash -c "go version"
check "golangci-lint version" bash -c "golangci-lint --version | grep 'golangci-lint has version 1.50.0'"

# Report result
reportResults