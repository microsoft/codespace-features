#!/bin/bash

set -e

source dev-container-features-test-lib

check "git version uses requested series" bash -c "git --version | grep '2.53.0.vfs.0'"
check "git version has multi-digit vfs revision" bash -c "git --version | grep -E '2\\.53\\.0\\.vfs\\.0\\.[0-9]{2,}'"
check "scalar available" bash -c "command -v scalar && scalar version"

reportResults
