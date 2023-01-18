#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

check "git-version" bash -c "git --version | grep 'vfs'"
check "gcm-version" grep "2.0\." <(git-credential-manager --version)
check "no-dirs"  grep -v "drwxr" <(ls -l /tmp/debian_tests)
check "git-config" grep "/usr/local/bin/git-credential-manager" <(cat /tmp/debian_tests/.git/config)


# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults