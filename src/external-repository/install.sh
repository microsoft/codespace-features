#!/bin/sh

set -e

EXT_GIT_PROVIDER="${GITPROVIDER:-"azuredevops"}"
EXT_GIT_REPO_URL="${CLONEURL:-"required"}"
EXT_GIT_USERNAME="${USERNAME:-"user"}"
EXT_GIT_PREBUILD_PAT="${CLONESECRET:-"required"}"
EXT_GIT_LOCAL_PATH="${FOLDER:-"/workspace/external-repos"}"
EXT_GIT_USER_PAT="${USERSECRET:-""}"
EXT_GIT_CLONE_TIMEOUT="${TIMEOUT:-"30m"}"
EXT_GIT_BRANCH="${BRANCH:-"main"}"
EXT_GIT_OPTIONS="${OPTIONS:-""}"
EXT_GIT_SCALAR="${SCALAR:-"false"}"
EXT_GIT_SPARSECHECKOUT="${SPARSECHECKOUT:-""}"
EXT_GIT_TELEMETRY="${TELEMETRYSOURCE:-"none"}"


if [ "$(id -u)" -ne 0 ]; then
    echo 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

if [ "${EXT_GIT_REPO_URL}" = "required" ]; then
    echo 'Clone URL is required. Set the feature variable "cloneUrl" to the https:// URL of the repository you want to clone. Example: "https://dev.azure.com/contoso/MyProject/_git/MyRepo".'
    exit 1
fi

if [ "${EXT_GIT_PREBUILD_PAT}" = "required" ]; then
    echo 'Clone Secret is required. Please set the feature variable "cloneSecret" to the name of the Codespaces Secret you will use to store your token. Example: "ADO_PAT".'
    exit 1
fi


# Change to the directory where this script is located
cd "$(dirname "$0")"

if [ "${EXT_GIT_PROVIDER}" = "azuredevops" ]; then
    # Install Git Credential Manager and exit if not zero
    ./install-gcm.sh
    if [ $? -ne 0 ]; then
        exit 1
    fi
fi

# Install our scripts to the devcontainer
cp ./scripts/external-git /usr/local/bin
chmod a+rx /usr/local/bin/external-git

mkdir -p /usr/local/external-repository-feature
chmod +r /usr/local/external-repository-feature
cp ./scripts/clone.sh /usr/local/external-repository-feature
cp ./scripts/setup-user.sh /usr/local/external-repository-feature
cp ./scripts/commit-msg.sh /usr/local/external-repository-feature

# Write the variables.sh script
echo "EXT_GIT_PROVIDER=\"${EXT_GIT_PROVIDER}\"" > /usr/local/external-repository-feature/variables.sh
echo "EXT_GIT_REPO_URL=\"${EXT_GIT_REPO_URL}\"" >> /usr/local/external-repository-feature/variables.sh
echo "EXT_GIT_LOCAL_PATH=\"${EXT_GIT_LOCAL_PATH}\"" >> /usr/local/external-repository-feature/variables.sh
echo "EXT_GIT_USERNAME=\"${EXT_GIT_USERNAME}\"" >> /usr/local/external-repository-feature/variables.sh
echo "EXT_GIT_USER_PAT=\"${EXT_GIT_USER_PAT}\"" >> /usr/local/external-repository-feature/variables.sh
echo "EXT_GIT_PREBUILD_PAT=\"${EXT_GIT_PREBUILD_PAT}\"" >> /usr/local/external-repository-feature/variables.sh
echo "EXT_GIT_CLONE_TIMEOUT=\"${EXT_GIT_CLONE_TIMEOUT}\"" >> /usr/local/external-repository-feature/variables.sh
echo "EXT_GIT_BRANCH=\"${EXT_GIT_BRANCH}\"" >> /usr/local/external-repository-feature/variables.sh
echo "EXT_GIT_OPTIONS=\"${EXT_GIT_OPTIONS}\"" >> /usr/local/external-repository-feature/variables.sh
echo "EXT_GIT_SCALAR=\"${EXT_GIT_SCALAR}\"" >> /usr/local/external-repository-feature/variables.sh
echo "EXT_GIT_SPARSECHECKOUT=\"${EXT_GIT_SPARSECHECKOUT}\"" >> /usr/local/external-repository-feature/variables.sh
echo "EXT_GIT_TELEMETRY=\"${EXT_GIT_TELEMETRY}\"" >> /usr/local/external-repository-feature/variables.sh

# Make the scripts executable
chmod +rx /usr/local/external-repository-feature/*.sh
cat /usr/local/external-repository-feature/variables.sh

# Create the Git config file templates
cp ./scripts/*.config /usr/local/external-repository-feature

chmod +r /usr/local/external-repository-feature/*.config

exit 0