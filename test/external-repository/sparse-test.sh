#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests

check "git-config" grep "ado-helper" <(cat /tmp/sparse-repos/src/.git/config)
check "dirs"  grep "drwxr" <(ls -l /tmp/sparse-repos/src)

# Report result
reportResults