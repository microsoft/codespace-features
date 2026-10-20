#!/bin/bash

set -e

source dev-container-features-test-lib

check "git version" test "$(git --version)" = "git version 2.56.0.vfs.0.2"
check "scalar available" bash -c "command -v scalar && scalar version"

reportResults
