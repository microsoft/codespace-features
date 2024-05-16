#!/usr/bin/env bash

# Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib || exit 1

# Confidence check for prerequisites
check 'pip should be installed' python3 -m pip --version

check 'keyring should be installed' python3 -m pip show keyring
check 'codespaces_artifacts_helper_keyring should be installed' python3 -m pip show codespaces_artifacts_helper_keyring

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
