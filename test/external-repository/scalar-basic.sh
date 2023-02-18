#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests

check "git-config" grep "ado-auth-helper" <(cat /tmp/scalar-basic/src/.git/config)
check "no-dirs"  grep -v "drwxr" <(ls -l /tmp/scalar-basic/src)

# Report result
reportResults