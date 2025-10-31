#!/bin/bash

if [ -f "${HOME}/ado-auth-helper" ]; then
  export ARTIFACTS_ACCESSTOKEN=$(${HOME}/ado-auth-helper get-access-token)
fi

# Find the yarn executable so we do not run the bash alias again
if [ -z "$YARN_EXE" ]; then
  YARN_EXE=$(which yarn)
fi

${YARN_EXE} "$@"
EXIT_CODE=$?
unset YARN_EXE

if [ -f "${HOME}/ado-auth-helper" ]; then
    unset ARTIFACTS_ACCESSTOKEN
fi

exit $EXIT_CODE