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

GIT_PATH=""
if [ -d  "${EXT_GIT_LOCAL_PATH}"/.git ]; then 
    GIT_PATH="${EXT_GIT_LOCAL_PATH}/.git"
else
    GIT_PATH="${EXT_GIT_LOCAL_PATH}/src/.git"
fi

# See if $EXT_GIT_LOCAL_PATH/.git/config contains [credential] section
if grep -q "\[credential\]" "${GIT_PATH}/config"; then
    if grep -q "helper =" "${GIT_PATH}/config"; then
        echo "Git [credential] is already configured"
        exit 0
    fi
fi

if [ "$GCM" = "true" ]; then
    echo "Configuring Git Credential Manager"
    cat "./gcm-git.config" >> "${GIT_PATH}/config"
else
    echo "Configuring Git Credentials to use a secret"
    cat "./usersecret-git.config" >> "${GIT_PATH}/config"
fi

# Setup Git Telemetry .. note that the checks for the credentials
# will already have exited the script before we get here if
# they have previously been configured. So we are relying on
# that as our way to only do this once

if [ "${EXT_GIT_TELEMETRY}" = "message" ]; then
    echo "Configuring Git commit-msg hook"
    cp "./commit-msg.sh" "${GIT_PATH}/hooks/commit-msg"
    chmod +x "${GIT_PATH}/hooks/commit-msg"
    exit 0
fi

if [ "${EXT_GIT_TELEMETRY}" = "name" ]; then
    echo "Configuring Git Username"
    cd "${EXT_GIT_LOCAL_PATH}"
    # Retrieve the user's name from the git config
    GIT_USER_NAME=$(git config user.name)
    if [ "${GIT_USER_NAME}" = "" ]; then
        echo "Git Username is not set"
        exit 0
    fi
    # Set the git user name to the telemetry name
    git config user.name "${GIT_USER_NAME} (Codespaces)"
    exit 0
fi

if [ "${EXT_GIT_TELEMETRY}" = "email" ]; then
    echo "Configuring Git Email address"
    cd "${EXT_GIT_LOCAL_PATH}"
    # Retrieve the user's email from the git config
    GIT_USER_EMAIL=$(git config user.email)
    if [ "${GIT_USER_EMAIL}" = "" ]; then
        echo "Git Email is not set"
        exit 0
    fi
    # Split the email address at the @ sign
    IFS="@"
    set -- ${GIT_USER_EMAIL}
    if [ "${#@}" -ne 2 ];then
        echo "Could not parse email address"
        exit 0
    fi
    # Set the git user email to the telemetry email
    git config user.email "${1}+codespaces@${2}"
    exit 0
fi
