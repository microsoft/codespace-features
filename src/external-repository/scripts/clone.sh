#!/usr/bin/env bash

# Change to the directory where this script is located
cd "$(dirname "$0")"

# Load the variables
source ./variables.sh

clone_repository() {
    set -e
    GIT_REPO_URL=${1}
    GIT_LOCAL_PATH=${2}

    # If .git directory exists, then we can assume that the repo has already been cloned
    if [ ! -d  "${GIT_LOCAL_PATH}"/.git ]; then 
        # Check if ${HOME}/.gitconfig exists and save it
        if [ -f ${HOME}/.gitconfig ]; then
            mv ${HOME}/.gitconfig ${HOME}/.gitconfig.external_git_feature
        fi

        if [[ "${EXT_GIT_PREBUILD_PAT}" == "" && "${EXT_GIT_OIDC_PREBUILD}" == "false" ]]; then
            # Put the ado-auth-helper git config in place
            ADO_HELPER=$(echo ~)/ado-auth-helper
            sed "s|ADO_HELPER_PATH|${ADO_HELPER}|g" "./ado-git.config" > ${HOME}/.gitconfig
        else
            # Put the prebuild git config in place
            cp /usr/local/external-repository-feature/prebuild-git.config ${HOME}/.gitconfig
        fi

        # Perform a git clone
        if [[ "${EXT_GIT_SCALAR}" != "true" ]]; then
            echo "Cloning ${GIT_REPO_URL} to ${GIT_LOCAL_PATH}"
            timeout ${EXT_GIT_CLONE_TIMEOUT} git clone ${EXT_GIT_OPTIONS} "${GIT_REPO_URL}" "${GIT_LOCAL_PATH}"
            if [ $? -eq 124 ]; then
                echo "git clone command timed out..."
            fi
        else
            # Perform a scalar clone
            echo "Cloning ${GIT_REPO_URL} to ${GIT_LOCAL_PATH} using scalar"
            
            # Scalar cannot clone into an existing folder so we need to remove it
            # Anyone using workspaceFolder in Codespaces will have created this folder already
            # so this will be a common scenario. We have already confirmed there is no .git folder
            # let's just do one more check to make sure there is not a src/.git folder which
            # would indicate a previous Scalar clone has been done
            if [ -d  "${GIT_LOCAL_PATH}"/src/.git ]; then
                echo "Repository already cloned"
                rm ${HOME}/.gitconfig
                # Put back the original .gitconfig if it exists
                if [ -f ${HOME}/.gitconfig.external_git_feature ]; then
                    mv ${HOME}/.gitconfig.external_git_feature ${HOME}/.gitconfig
                fi
                return 0
            fi

            # Remove the local path if it exists
            if [ -d  "${GIT_LOCAL_PATH}" ]; then
                rm -rf "${GIT_LOCAL_PATH}"
            fi

            timeout ${EXT_GIT_CLONE_TIMEOUT} scalar clone ${EXT_GIT_OPTIONS} "${GIT_REPO_URL}" "${GIT_LOCAL_PATH}"
            if [ $? -eq 124 ]; then
                echo "scalar clone command timed out..."
            fi
            # Figure out the where the .git directory is and change to the parent. Can vary whether --no-src is used
            if [ -d  "${GIT_LOCAL_PATH}"/.git ]; then 
                cd "${GIT_LOCAL_PATH}"
            else
                cd "${GIT_LOCAL_PATH}"/src
            fi
            if [[ "${EXT_GIT_SPARSECHECKOUT}" != "" ]]; then
                timeout ${EXT_GIT_CLONE_TIMEOUT} git sparse-checkout add ${EXT_GIT_SPARSECHECKOUT}
                if [ $? -eq 124 ]; then
                    echo "git sparse-checkout command timed out..."
                fi
            fi
            cd "$(dirname "$0")"
        fi

        rm ${HOME}/.gitconfig
        # Put back the original .gitconfig if it exists
        if [ -f ${HOME}/.gitconfig.external_git_feature ]; then
            mv ${HOME}/.gitconfig.external_git_feature ${HOME}/.gitconfig
        fi
    else
        echo "Repository already cloned"
    fi    
    
}

if [[ "${EXT_GIT_REPO_URL}" == "" ]]; then
    echo "Clone URL is not set"
    exit 0;
fi

if [[ "${EXT_GIT_LOCAL_PATH}" == "" ]]; then
    echo "Workspace folder for external repository is not set"
    exit 0;
fi

if [[ "${EXT_GIT_PREBUILD_PAT}" == "" && "${EXT_GIT_OIDC_PREBUILD}" == "false" ]]; then
    echo "Prebuild secret is not set, attempting to clone with ado-auth-helper"
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
else
    # Get the value from environment variable whose name is set in EXT_GIT_PREBUILD_PAT
    if [[ "${EXT_GIT_OIDC_PREBUILD}" == "true" ]]; then
        EXT_GIT_PAT_VALUE="OIDC"
    else
        EXT_GIT_PAT_VALUE=${!EXT_GIT_PREBUILD_PAT}
    fi

    if [[ "${EXT_GIT_PAT_VALUE}" == "" ]]; then
        echo "There is no secret stored in ${EXT_GIT_PREBUILD_PAT}"
        exit 0;
    fi
fi

# Split EXT_GIT_REPO_URL into an array based on a comma delimiter
IFS=',' read -ra EXT_GIT_REPO_URL_ARRAY <<< "${EXT_GIT_REPO_URL}"
# If there is more than one repo URL, then we need to clone each one
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
        clone_repository ${REPO_URL} ${LOCAL_PATH}
    done
    exit 0
fi
# There was only one repository specified
clone_repository ${EXT_GIT_REPO_URL} ${EXT_GIT_LOCAL_PATH}