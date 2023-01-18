#!/usr/bin/env bash

# Change to the directory where this script is located
cd "$(dirname "$0")"

# Load the variables
source ./variables.sh

if [[ "${EXT_GIT_LOCAL_PATH}" == "" ]]; then
    echo "Repository Local Path is not set"
    exit 1;
fi

# If repository does not exist, we will initialize an empty one
# that points to the remote repository. This would only be the case
# when someone is testing Codespaces without setting up prebuild
if [ ! -d "${EXT_GIT_LOCAL_PATH}" ]; then
    echo "Initializing empty repository at ${EXT_GIT_LOCAL_PATH}"
    mkdir -p "${EXT_GIT_LOCAL_PATH}"
    cd "${EXT_GIT_LOCAL_PATH}"
    git init -b "${EXT_GIT_BRANCH}"
    git remote add origin "${EXT_GIT_REPO_URL}"
    cd "$(dirname "$0")"
fi

# Until we get user feedback, we will only install GCM for Azure DevOps repositories
# other git hosting service should use the userSecret approach
if [ "${EXT_GIT_PROVIDER}" = "azuredevops" ]; then
    # Check if a USER PAT variable name is specified
    # and if it exists with a value set. Otherwise, use GCM
    GCM="true"
    if [[ "${EXT_GIT_USER_PAT}" != "" ]]; then
        EXT_GIT_PAT_VALUE=${!EXT_GIT_USER_PAT}
        if [[ "${EXT_GIT_PAT_VALUE}" != "" ]]; then
            GCM="false"
        fi
    fi
else
    GCM="false"
fi

CONFIG_PATH=""
if [ -d  "${EXT_GIT_LOCAL_PATH}"/.git ]; then 
    CONFIG_PATH="${EXT_GIT_LOCAL_PATH}/.git/config"
else
    CONFIG_PATH="${EXT_GIT_LOCAL_PATH}/src/.git/config"
fi

# See if $EXT_GIT_LOCAL_PATH/.git/config contains [credential] section
if grep -q "\[credential\]" "${CONFIG_PATH}"; then
    if grep -q "helper =" "${CONFIG_PATH}"; then
        echo "Git [credential] is already configured"
        exit 0
    fi
fi

if [ "$GCM" = "true" ]; then
    echo "Configuring Git Credential Manager"
    cat "./gcm-git.config" >> "${CONFIG_PATH}"
else
    echo "Configuring Git Credentials to use a secret"
    cat "./usersecret-git.config" >> "${CONFIG_PATH}"
fi