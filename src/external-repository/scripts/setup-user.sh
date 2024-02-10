#!/usr/bin/env bash

# Change to the directory where this script is located
cd "$(dirname "$0")"

# Load the variables
source ./variables.sh

checkout_branch() {
    # If AZDO_BRANCH is not set, then return
    if [[ "${AZDO_BRANCH}" == "" ]]; then
        return
    fi
    cd ${1}

    # Get the current branch name
    CURRENT_BRANCH=$(git branch --show-current)
    if [[ "${CURRENT_BRANCH}" == "${AZDO_BRANCH}" ]]; then
        echo "Already on branch ${AZDO_BRANCH}"
        return
    fi

    echo "Checking out branch ${AZDO_BRANCH}"
    
    if [ ! -f ${HOME}/ado-auth-helper ]; then
        echo "Waiting up to 180 seconds for ado-auth-helper extension to be installed"
    fi    
    # Wait up to 3 minutes for the ado-auth-helper to be installed
    for i in {1..180}; do
        if [ -f ${HOME}/ado-auth-helper ]; then
            break
        fi
        sleep 1
    done

    # fetch the branch named AZDO_BRANCH
    git fetch origin ${AZDO_BRANCH}
    git checkout ${AZDO_BRANCH}
}

configure_git_for_user() {
    GIT_PATH=""
    WC_PATH=""
    if [ -d  "${1}"/.git ]; then 
        GIT_PATH="${1}/.git"
        WC_PATH="${1}"
    else
        GIT_PATH="${1}/src/.git"
        WC_PATH="${1}/src"
    fi

    # See if $GIT_PATH/.git/config contains [credential] section
    credential_configured=false
    if grep -q "\[credential\]" "${GIT_PATH}/config"; then
        if grep -q "helper =" "${GIT_PATH}/config"; then
            echo "Git [credential] is already configured"
            credential_configured=true
        fi
    fi

    if [ "$ADO" = "true" ] && [ "$credential_configured" = false ]; then
        echo "Configuring ADO Authorization Helper"
        ADO_HELPER=$(echo ~)/ado-auth-helper
        sed "s|ADO_HELPER_PATH|${ADO_HELPER}|g" "./ado-git.config" >> "${GIT_PATH}/config"
    elif [ "$ADO" != "true" ]; then
        echo "Configuring Git Credentials to use a secret"
        cat "./usersecret-git.config" >> "${GIT_PATH}/config"
    fi

    if [ "$ADO" = "true" ]; then
        # See if there was a request to checkout an AzDO branch by checking the branch name of
        # the Codespaces bridge repository. If the branch name begins with azdo/ then the
        # rest of the branch name is the branch to checkout.
        if [[ "${RepositoryName}" != "" ]]; then
            CS_FOLDER=/workspaces/${RepositoryName}
            if [ -d "${CS_FOLDER}" ]; then
                CS_BRANCH_NAME=$(git -C ${CS_FOLDER} branch --show-current)
                if [[ ${CS_BRANCH_NAME} == azdo/* ]]; then
                    export AZDO_BRANCH=${CS_BRANCH_NAME#azdo/}
                fi
            fi
        fi        

        # Call the function regardless so that some other process can set the AZDO_BRANCH variable
        # before this script is called and it will still work. This allows for other techniques to be
        # used to communicate the desire to checkout a branch
        checkout_branch ${WC_PATH}
    fi

    # Setup Git Telemetry .. note that the checks for the credentials
    # will already have exited the script before we get here if
    # they have previously been configured. So we are relying on
    # that as our way to only do this once

    if [ "${EXT_GIT_TELEMETRY}" = "message" ]; then
        echo "Configuring Git commit-msg hook"
        cp "/usr/local/external-repository-feature/commit-msg.sh" "${GIT_PATH}/hooks/commit-msg"
        chmod +x "${GIT_PATH}/hooks/commit-msg"
        return
    fi

    if [ "${EXT_GIT_TELEMETRY}" = "name" ]; then
        echo "Confguring Git Username"
        cd "${WC_PATH}"
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
        cd "${WC_PATH}"
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


# Split EXT_GIT_REPO_URL into an array based on a comma delimiter if multiple URLs are specified
IFS=',' read -ra EXT_GIT_REPO_URL_ARRAY <<< "${EXT_GIT_REPO_URL}"
# If there is more than one repo URL, then we need to configure each one
# When there is more than one repo URL, the EXT_GIT_LOCAL_PATH is the parent folder
# that will contain the repositories. When there is only one repo URL, the EXT_GIT_LOCAL_PATH
# is the folder that will contain the repository
if [ ${#EXT_GIT_REPO_URL_ARRAY[@]} -gt 1 ]; then
    # Loop through each repo URL
    for i in "${EXT_GIT_REPO_URL_ARRAY[@]}"; do
        # Set the repo URL to the current value
        REPO_URL=$i
        # Get the folder name from the last part of the URL (dropping .git if necessary)
        REPO_FOLDER=$(echo "${REPO_URL}" | sed 's/\.git$//;s#.*/##')
        LOCAL_PATH=${EXT_GIT_LOCAL_PATH}/${REPO_FOLDER}
        # Clone the repo
        configure_git_for_user ${LOCAL_PATH}
    done
    exit 0
fi
# There was only one repository specified
configure_git_for_user ${EXT_GIT_LOCAL_PATH}
