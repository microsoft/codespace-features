#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
touch ${HOME}/ado-auth-helper
check "git-config" grep "ado-auth-helper" <(cat /tmp/branch-repos/.git/config)
check "branch" grep "joshaber/parallel-execution-schema" <(git -C /tmp/branch-repos branch --show-current)

# Report result
reportResults