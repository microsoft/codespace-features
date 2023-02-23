#!/bin/bash

if [ -f "${HOME}/ado-auth-helper" ]; then
  export VSS_NUGET_ACCESSTOKEN=$(${HOME}/ado-auth-helper get-access-token)
  export VSS_NUGET_URI_PREFIXES=REPLACE_WITH_AZURE_DEVOPS_NUGET_FEED_URL_PREFIX
fi

# Find the dotnet executable so we do not run the bash alias again
DOTNET_EXE=$(which dotnet)

${DOTNET_EXE} "$@"
EXIT_CODE=$?
unset DOTNET_EXE

if [ -f "${HOME}/ado-auth-helper" ]; then
    unset VSS_NUGET_ACCESSTOKEN
    unset VSS_NUGET_URI_PREFIXES
fi

exit $EXIT_CODE