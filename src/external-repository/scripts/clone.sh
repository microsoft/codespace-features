#!/usr/bin/env bash


# Change to the directory where this script is located
cd "$(dirname "$0")"

# Load the variables
source ./variables.sh

if [[ "${EXT_GIT_REPO_URL}" == "" ]]; then
    echo "Clone URL is not set"
    exit 0;
fi

if [[ "${EXT_GIT_LOCAL_PATH}" == "" ]]; then
    echo "Workspace folder for external repository is not set"
    exit 0;
fi

if [[ "${EXT_GIT_PREBUILD_PAT}" == "" ]]; then
    echo "Clone Secret for Codespace is not set"
    exit 0;
fi

# Get the value from environment variable whose name is set in EXT_GIT_PREBUILD_PAT
EXT_GIT_PAT_VALUE=${!EXT_GIT_PREBUILD_PAT}

if [[ "${EXT_GIT_PAT_VALUE}" == "" ]]; then
    echo "There is no secret stored in ${EXT_GIT_PREBUILD_PAT}"
    exit 0;
fi

set -ex

# If .git directory exists, then we can assume that the repo has already been cloned
if [ ! -d  "${EXT_GIT_LOCAL_PATH}"/.git ]; then 
    # Check if ${HOME}/.gitconfig exists and save it
    if [ -f ${HOME}/.gitconfig ]; then
        mv ${HOME}/.gitconfig ${HOME}/.gitconfig.external_git_feature
    fi
    # Put the prebuild git config in place
    cp /usr/local/external-repository-feature/prebuild-git.config ${HOME}/.gitconfig

    # Perform a git clone
    if [[ "${EXT_GIT_SCALAR}" != "true" ]]; then
        echo "Cloning ${EXT_GIT_REPO_URL} to ${EXT_GIT_LOCAL_PATH}"
        timeout ${EXT_GIT_CLONE_TIMEOUT} git clone ${EXT_GIT_OPTIONS} "${EXT_GIT_REPO_URL}" "${EXT_GIT_LOCAL_PATH}"
        if [ $? -eq 124 ]; then
            echo "git clone command timed out..."
        fi
    else
        # Perform a scalar clone
        echo "Cloning ${EXT_GIT_REPO_URL} to ${EXT_GIT_LOCAL_PATH} using scalar"
        
        # Scalar cannot clone into an existing folder so we need to remove it
        # Anyone using workspaceFolder in Codespaces will have created this folder already
        # so this will be a common scenario. We have already confirmed there is no .git folder
        # let's just do one more check to make sure there is not a src/.git folder which
        # would indicate a previous Scalar clone has been done
        if [ -d  "${EXT_GIT_LOCAL_PATH}"/src/.git ]; then
            echo "Repository already cloned"
            rm ${HOME}/.gitconfig
            # Put back the original .gitconfig if it exists
            if [ -f ${HOME}/.gitconfig.external_git_feature ]; then
                mv ${HOME}/.gitconfig.external_git_feature ${HOME}/.gitconfig
            fi
            exit 0
        fi

        # Remove the local path if it exists
        if [ -d  "${EXT_GIT_LOCAL_PATH}" ]; then
            rm -rf "${EXT_GIT_LOCAL_PATH}"
        fi

        timeout ${EXT_GIT_CLONE_TIMEOUT} scalar clone ${EXT_GIT_OPTIONS} "${EXT_GIT_REPO_URL}" "${EXT_GIT_LOCAL_PATH}"
        if [ $? -eq 124 ]; then
            echo "scalar clone command timed out..."
        fi
        # Figure out the where the .git directory is and change to the parent. Can vary whether --no-src is used
        if [ -d  "${EXT_GIT_LOCAL_PATH}"/.git ]; then 
            cd "${EXT_GIT_LOCAL_PATH}"
        else
            cd "${EXT_GIT_LOCAL_PATH}"/src
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