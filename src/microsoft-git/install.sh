#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------


GIT_VERSION=${VERSION:-"latest"} 

set -e

# Source /etc/os-release to get OS info
. /etc/os-release

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

apt_get_update()
{
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

export DEBIAN_FRONTEND=noninteractive

if [ "${ID}" = "mariner" ]; then
    tdnf install -y curl ca-certificates
else
    check_packages curl ca-certificates
fi

# Partial version matching
if [ "$(echo "${GIT_VERSION}" | grep -o '\.' | wc -l)" != "2" ]; then
    requested_version="${GIT_VERSION}"
    if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "lts" ] || [ "${requested_version}" = "current" ]; then
        # For latest, lts, and current, use the releases API to get the actual latest release
        GIT_VERSION="$(curl -sSL -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/microsoft/git/releases/latest" | grep -oP '"tag_name":\s*"v\K[0-9]+\.[0-9]+\.[0-9]+\.vfs\.[0-9]+\.[0-9]+"' | tr -d '"')"
    else
        # For partial versions, use the existing tags logic
        version_list="$(curl -sSL -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/microsoft/git/tags?per_page=100" | grep -oP '"name":\s*"v\K[0-9]+\.[0-9]+\.[0-9]+\.vfs\.[0-9]+\.[0-9]+"' | tr -d '"' | sort -rV)"
        set +e
        GIT_VERSION="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
        set -e
        if [ -z "${GIT_VERSION}" ] || ! echo "${version_list}" | grep "^${GIT_VERSION//./\\.}$" > /dev/null 2>&1; then
            echo "Invalid git version: ${requested_version}" >&2
            exit 1
        fi
    fi
    if [ -z "${GIT_VERSION}" ]; then
        echo "Invalid git version: ${requested_version}" >&2
        exit 1
    fi
fi


echo "Downloading Microsoft Git ${GIT_VERSION}..."

# If ID is mariner
if [ "${ID}" = "mariner" ]; then
    # We need to build Git from source release on Mariner
    tdnf install -y wget tar git pcre2 binutils build-essential openssl-devel expat-devel curl-devel python3-devel gettext asciidoc xmlto cronie
    wget -q https://github.com/microsoft/git/archive/refs/tags/v${GIT_VERSION}.tar.gz
    tar xvf v${GIT_VERSION}.tar.gz -C /usr
    rm v${GIT_VERSION}.tar.gz
    cd /usr/git-${GIT_VERSION}
    make prefix=/usr/local all install
    cd /usr
    rm -rf git-${GIT_VERSION}
    tdnf clean all
    exit 0
fi

# Install for Debian/Ubuntu
check_packages wget git

wget -q https://github.com/microsoft/git/releases/download/v${GIT_VERSION}/microsoft-git_${GIT_VERSION}.deb

dpkg -i "microsoft-git_${GIT_VERSION}.deb"

rm "microsoft-git_${GIT_VERSION}.deb"

rm -rf /var/lib/apt/lists/*
echo "Done!"