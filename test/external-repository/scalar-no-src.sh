#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests

check "git-config" grep "ado-auth-helper" <(cat /tmp/scalar-no-src/.git/config)
check "no-dirs"  grep -v "drwxr" <(ls -l /tmp/scalar-no-src)


# Report result
reportResults