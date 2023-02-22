#!/bin/bash

source /usr/local/external-repository-feature/variables.sh

# Find out if user configured a PAT for ADO and use it if so
EXT_GIT_PAT_VALUE=""
if [[ "${EXT_GIT_USER_PAT}" != "" ]]; then
    EXT_GIT_PAT_VALUE=${!EXT_GIT_USER_PAT}
else
    EXT_GIT_PAT_VALUE=""
fi

# Setup access token for nuget
if [ "${EXT_GIT_PAT_VALUE}" = "" ]; then
    export VSS_NUGET_ACCESSTOKEN=$(/home/vscode/ado-auth-helper get-access-token)
else
    export VSS_NUGET_ACCESSTOKEN=${EXT_GIT_PAT_VALUE}
fi

# If VSS_NUGET_URI_PREFIXES is not set, we will set it to the default value
if [ "${VSS_NUGET_URI_PREFIXES}" = "" ]; then
    export VSS_NUGET_URI_PREFIXES=https://pkgs.dev.azure.com/
fi

dotnet "$@"

unset VSS_NUGET_ACCESSTOKEN
unset VSS_NUGET_URI_PREFIXES