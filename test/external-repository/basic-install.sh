#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "git-config" grep "ado-auth-helper" <(cat /tmp/basic-repos/.git/config)

# Report result
reportResults