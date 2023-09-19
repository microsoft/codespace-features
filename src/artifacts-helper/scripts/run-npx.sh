#!/bin/bash

if [ -f "${HOME}/ado-auth-helper" ]; then
  export ARTIFACTS_ACCESSTOKEN=$(${HOME}/ado-auth-helper get-access-token)
fi

# Find the npm executable so we do not run the bash alias again
NPX_EXE=$(which npx)

${NPX_EXE} "$@"
EXIT_CODE=$?
unset NPX_EXE

if [ -f "${HOME}/ado-auth-helper" ]; then
    unset ARTIFACTS_ACCESSTOKEN
fi

exit $EXIT_CODE