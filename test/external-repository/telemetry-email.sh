#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" grep "2.0\." <(git-credential-manager --version)
check "git-config" grep "/usr/local/bin/git-credential-manager" <(cat /tmp/basic-repos/.git/config)

cd /tmp/telemetry-email
export CODESPACE_NAME="commit.hooks-testing"
echo "Make changes to README.md" >> README.md
git add README.md
git commit -m "Change the README.md file"

check "hook" grep "+codespaces" <(git log -1)

# Report result
reportResults