#!/bin/bash

if [ -f "${HOME}/ado-auth-helper" ]; then
  export ARTIFACTS_ACCESSTOKEN=$(${HOME}/ado-auth-helper get-access-token)
fi

# Find the npx executable so we do not run the bash alias again
if [ -z "$NPX_EXE" ]; then
  NPX_EXE=$(which npx)
fi

${NPX_EXE} "$@"
EXIT_CODE=$?
unset NPX_EXE

if [ -f "${HOME}/ado-auth-helper" ]; then
    unset ARTIFACTS_ACCESSTOKEN
fi

exit $EXIT_CODE