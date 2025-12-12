#!/bin/bash
# Quick test runner for artifacts-helper feature
# Usage: ./run-tests.sh [scenario-name]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "==================================="
echo "Testing artifacts-helper feature"
echo "==================================="
echo

if [ -n "$1" ]; then
    echo "Running scenario: $1"
    devcontainer features test -f artifacts-helper --scenario "$1"
else
    echo "Running all scenarios..."
    devcontainer features test -f artifacts-helper
fi

echo
echo "==================================="
echo "Tests completed!"
echo "==================================="
