#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "git-config-1" grep "ado-helper" <(cat /tmp/multi-repos/community/.git/config)
check "git-config-2" grep "ado-helper" <(cat /tmp/multi-repos/spec/.git/config)
check "git-config-3" grep "ado-helper" <(cat /tmp/multi-repos/devcontainers.github.io/.git/config)

# Report result
reportResults