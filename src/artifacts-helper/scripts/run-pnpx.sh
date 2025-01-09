#!/bin/bash

if [ -f "${HOME}/ado-auth-helper" ]; then
  export ARTIFACTS_ACCESSTOKEN=$(${HOME}/ado-auth-helper get-access-token)
fi

# Find the pnpx executable so we do not run the bash alias again
PNPX_EXE=$(which pnpx)

${PNPX_EXE} "$@"
EXIT_CODE=$?
unset PNPX_EXE

if [ -f "${HOME}/ado-auth-helper" ]; then
    unset ARTIFACTS_ACCESSTOKEN
fi

exit $EXIT_CODE