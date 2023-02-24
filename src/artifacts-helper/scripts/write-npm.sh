#!/bin/bash

ARTIFACTS_FEED=${1:-"required"}
FEED_USER="${2:-"codespaces"}"
FEED_EMAIL="${3:-"codespaces@github.com"}"

# If ARTIFACTS_FEED equals "required" then exit with error message
if [ "${ARTIFACTS_FEED}" = "required" ]; then
    echo "  Usage: write-npm.sh <ARTIFACTS_FEED> <FEED_USER>(optional) <FEED_EMAIL>(optional)"
    echo "example: write-npm.sh pkgs.dev.azure.com/orgname/projectname/_packaging/feedname/npm"
    exit 1
fi

echo "//${ARTIFACTS_FEED}/registry/:username=${FEED_USER}" >> ${HOME}/.npmrc
echo "//${ARTIFACTS_FEED}/registry/:_authToken=\${ARTIFACTS_ACCESSTOKEN}" >> ${HOME}/.npmrc
echo "//${ARTIFACTS_FEED}/registry/:email=${FEED_EMAIL}" >> ${HOME}/.npmrc
echo "//${ARTIFACTS_FEED}/:username=${FEED_USER}"  >> ${HOME}/.npmrc
echo "//${ARTIFACTS_FEED}/:_authToken=\${ARTIFACTS_ACCESSTOKEN}" >> ${HOME}/.npmrc
echo "//${ARTIFACTS_FEED}/:email=${FEED_EMAIL}" >> ${HOME}/.npmrc