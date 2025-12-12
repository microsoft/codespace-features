#!/bin/bash

echo "::step::Waiting for AzDO Authentication Helper..."

# Wait up to 3 minutes for the ado-auth-helper to be installed
MAX_WAIT=180
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
    if [ -f "${HOME}/ado-auth-helper" ]; then
        echo "::step::Running ado-auth-helper get-access-token..."
        ARTIFACTS_ACCESSTOKEN=$(${HOME}/ado-auth-helper get-access-token)
        echo "::step::✓ Access token retrieved successfully"
        return 0
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))

    # Progress indicator every 20 seconds
    if [ $((ELAPSED % 20)) -eq 0 ]; then
        echo "  Still waiting... (${ELAPSED}s elapsed)"
    fi
done

# Timeout reached
echo "::error::AzDO Authentication Helper not found after ${MAX_WAIT} seconds"
echo "Expected location: ${HOME}/ado-auth-helper"
echo "Restore cannot proceed without authentication"
return 1