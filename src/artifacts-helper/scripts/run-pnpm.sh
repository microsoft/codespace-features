#!/bin/bash

if [ -f "${HOME}/ado-auth-helper" ]; then
  export ARTIFACTS_ACCESSTOKEN=$(${HOME}/ado-auth-helper get-access-token)
fi

# Find the pnpm executable so we do not run the bash alias again
PNPM_EXE=$(which pnpm)

${PNPM_EXE} "$@"
EXIT_CODE=$?
unset PNPM_EXE

if [ -f "${HOME}/ado-auth-helper" ]; then
    unset ARTIFACTS_ACCESSTOKEN
fi

exit $EXIT_CODE