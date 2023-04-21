#!/usr/bin/env bash

# Change to the directory where this script is located
cd "$(dirname "$0")"

# Load the variables
source ./variables.sh

configure_git_for_user() {

    GIT_PATH=""
    if [ -d  "${1}"/.git ]; then 
        GIT_PATH="${1}/.git"
    else
        GIT_PATH="${1}/src/.git"
    fi

    # See if $GIT_PATH/.git/config contains [credential] section
    if grep -q "\[credential\]" "${GIT_PATH}/config"; then
        if grep -q "helper =" "${GIT_PATH}/config"; then
            echo "Git [credential] is already configured"
            return
        fi
    fi

    if [ "$ADO" = "true" ]; then
        echo "Configuring ADO Authorization Helper"
        ADO_HELPER=$(echo ~)/ado-auth-helper
        sed "s|ADO_HELPER_PATH|${ADO_HELPER}|g" "./ado-git.config" >> "${GIT_PATH}/config"
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
        return
    fi

    if [ "${EXT_GIT_TELEMETRY}" = "name" ]; then
        echo "Configuring Git Username"
        cd "${EXT_GIT_LOCAL_PATH}"
        # Retrieve the user's name from the git config
        GIT_USER_NAME=$(git config user.name)
        if [ "${GIT_USER_NAME}" = "" ]; then
            echo "Git Username is not set"
            return
        fi
        # Set the git user name to the telemetry name
        git config user.name "${GIT_USER_NAME} (Codespaces)"
        return
    fi

    if [ "${EXT_GIT_TELEMETRY}" = "email" ]; then
        echo "Configuring Git Email address"
        cd "${EXT_GIT_LOCAL_PATH}"
        # Retrieve the user's email from the git config
        GIT_USER_EMAIL=$(git config user.email)
        if [ "${GIT_USER_EMAIL}" = "" ]; then
            echo "Git Email is not set"
            return
        fi
        # Split the email address at the @ sign
        IFS="@"
        set -- ${GIT_USER_EMAIL}
        if [ "${#@}" -ne 2 ];then
            echo "Could not parse email address"
            return
        fi
        # Set the git user email to the telemetry email
        git config user.email "${1}+codespaces@${2}"
        return
    fi
        
}

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

# Configure to use ado-auth-helper unless a userSecret is specified
if [ "${EXT_GIT_PROVIDER}" = "azuredevops" ]; then
    # Check if a USER PAT variable name is specified
    # and if it exists with a value set. Otherwise, use ADO Helper
    ADO="true"
    if [[ "${EXT_GIT_USER_PAT}" != "" ]]; then
        EXT_GIT_PAT_VALUE=${!EXT_GIT_USER_PAT}
        if [[ "${EXT_GIT_PAT_VALUE}" != "" ]]; then
            ADO="false"
        fi
    fi
else
    ADO="false"
fi


# Split EXT_GIT_REPO_URL into an array based on a comma delimiter
IFS=',' read -ra EXT_GIT_REPO_URL_ARRAY <<< "${EXT_GIT_REPO_URL}"
# If there is more than one repo URL, then we need to clone each one
if [ ${#EXT_GIT_REPO_URL_ARRAY[@]} -gt 1 ]; then
    # Loop through each repo URL
    for i in "${EXT_GIT_REPO_URL_ARRAY[@]}"; do
        # Set the repo URL to the current value
        REPO_URL=$i
        # Get the folder name from the last part of the URL
        REPO_FOLDER=$(echo "${REPO_URL}" | awk -F'/' '{print $NF}' | awk -F'.' '{print $1}')
        LOCAL_PATH=${EXT_GIT_LOCAL_PATH}/${REPO_FOLDER
        # Clone the repo
        configure_git_for_user $LOCAL_PATH
    done
    exit 0
fi
# There was only one repository specified
configure_git_for_user $EXT_GIT_LOCAL_PATH
