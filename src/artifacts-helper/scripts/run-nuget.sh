#!/bin/bash

# Install artifact credential provider if it is not already installed
if [ ! -d "${HOME}/.nuget/plugins/netcore" ]; then
  wget -qO- https://aka.ms/install-artifacts-credprovider.sh | bash
fi

if [ -f "${HOME}/ado-auth-helper" ]; then
  export VSS_NUGET_ACCESSTOKEN=$(${HOME}/ado-auth-helper get-access-token)
  export VSS_NUGET_URI_PREFIXES=REPLACE_WITH_AZURE_DEVOPS_NUGET_FEED_URL_PREFIX
fi

# Find the nuget executable so we do not run the bash alias again
if [ -z "$NUGET_EXE" ]; then
  NUGET_EXE=$(which nuget)
fi

${NUGET_EXE} "$@"
EXIT_CODE=$?
unset NUGET_EXE

if [ -f "${HOME}/ado-auth-helper" ]; then
    unset VSS_NUGET_ACCESSTOKEN
    unset VSS_NUGET_URI_PREFIXES
fi

exit $EXIT_CODE