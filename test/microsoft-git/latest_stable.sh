#!/bin/bash

set -e

source dev-container-features-test-lib

check "git version has vfs" bash -c "git --version | grep 'vfs'"
check "latest is stable" bash -c "! git --version | grep -E -- '-rc[0-9]+'"
check "scalar available" bash -c "command -v scalar && scalar version"

reportResults
