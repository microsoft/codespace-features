#!/bin/bash

if [ -f "${HOME}/ado-auth-helper" ]; then
  export ARTIFACTS_ACCESSTOKEN=$(${HOME}/ado-auth-helper get-access-token)
fi

# Find the rush executable so we do not run the bash alias again
if [ -z "$RUSH_EXE" ]; then
  RUSH_EXE=$(which rush)
fi

${RUSH_EXE} "$@"
EXIT_CODE=$?
unset RUSH_EXE

if [ -f "${HOME}/ado-auth-helper" ]; then
    unset ARTIFACTS_ACCESSTOKEN
fi

exit $EXIT_CODE