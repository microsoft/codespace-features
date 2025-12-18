#!/bin/bash

# Helper function to conditionally log messages
# Messages are only shown if ARTIFACTS_HELPER_VERBOSE is set to "true"
log_step() {
    if [ "${ARTIFACTS_HELPER_VERBOSE}" = "true" ]; then
        echo "::step::$1"
    fi
}

log_message() {
    if [ "${ARTIFACTS_HELPER_VERBOSE}" = "true" ]; then
        echo "$1"
    fi
}

# If ACTIONS_ID_TOKEN_REQUEST_URL is set, we're in a GitHub Actions environment
# Skip Azure DevOps authentication and just execute the real command
if [ -n "${ACTIONS_ID_TOKEN_REQUEST_URL}" ]; then
    log_step "GitHub Actions environment detected, skipping Azure DevOps authentication"
    return 0
fi

log_step "Waiting for AzDO Authentication Helper..."

# Wait up to 3 minutes for the ado-auth-helper to be installed
# Can be overridden via environment variable for testing
MAX_WAIT=${MAX_WAIT:-180}
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
    if [ -f "${HOME}/ado-auth-helper" ]; then
        log_step "Running ado-auth-helper get-access-token..."
        ARTIFACTS_ACCESSTOKEN=$(${HOME}/ado-auth-helper get-access-token)
        log_step "✓ Access token retrieved successfully"
        return 0
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))

    # Progress indicator every 20 seconds
    if [ $((ELAPSED % 20)) -eq 0 ]; then
        log_message "  Still waiting... (${ELAPSED}s elapsed)"
    fi
done

# Timeout reached - continue without authentication
# Always show warnings, even if verbose is disabled
echo "::warning::AzDO Authentication Helper not found after ${MAX_WAIT} seconds"
echo "Expected location: ${HOME}/ado-auth-helper"
echo "Continuing without Azure Artifacts authentication..."
return 1