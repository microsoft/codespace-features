#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "git-config" grep "external-git helper" <(cat /tmp/options-repos/.git/config)

# Report result
reportResults