#!/bin/bash

set -e

source dev-container-features-test-lib

EXPECTED_VERSION="2.55.0-rc1.vfs.0.0"

check "git version" bash -c "git --version | grep '${EXPECTED_VERSION}'"
check "scalar available" bash -c "command -v scalar && scalar version"

reportResults
