#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" grep "2.0\." <(git-credential-manager --version)
check "git-config" grep "/usr/local/bin/git-credential-manager" <(cat /tmp/scalar-basic/src/.git/config)
check "no-dirs"  grep -v "drwxr" <(ls -l /tmp/scalar-basic/src)

# Report result
reportResults