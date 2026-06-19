#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------


GIT_VERSION=${VERSION:-"latest"} 

set -e

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

MICROSOFT_GIT_VERSION_REGEX='[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?\.vfs\.[0-9]+\.[0-9]+'

export DEBIAN_FRONTEND=noninteractive

if command -v tdnf >/dev/null 2>&1; then
    tdnf install -y curl ca-certificates
else
    check_packages curl ca-certificates
fi

# Partial version matching
requested_version="${GIT_VERSION#v}"
if ! echo "${requested_version}" | grep -Eq "^${MICROSOFT_GIT_VERSION_REGEX}$"; then
    if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "lts" ] || [ "${requested_version}" = "current" ]; then
        # For latest, lts, and current, use the releases API to get the actual latest stable release
        GIT_VERSION="$(curl -sSL -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/microsoft/git/releases/latest" | sed -nE "s/.*\"tag_name\"[[:space:]]*:[[:space:]]*\"v(${MICROSOFT_GIT_VERSION_REGEX})\".*/\1/p")"
    else
        # For partial versions, use the releases API so multi-digit VFS and RC releases are included
        version_list="$(curl -sSL -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/microsoft/git/releases?per_page=100" | sed -nE "s/.*\"tag_name\"[[:space:]]*:[[:space:]]*\"v(${MICROSOFT_GIT_VERSION_REGEX})\".*/\1/p" | sort -rV | uniq)"
        escaped_requested_version="$(echo "${requested_version}" | sed -E 's/[][(){}.^$*+?|\\]/\\&/g')"
        set +e
        GIT_VERSION="$(echo "${version_list}" | grep -E -m 1 "^${escaped_requested_version}([.-]|$)")"
        set -e
        if [ -z "${GIT_VERSION}" ] || ! echo "${version_list}" | grep "^${GIT_VERSION//./\\.}$" > /dev/null 2>&1; then
            echo "Invalid git version: ${requested_version}" >&2
            exit 1
        fi
    fi
else
    GIT_VERSION="${requested_version}"
fi

if [ -z "${GIT_VERSION}" ]; then
    echo "Invalid git version: ${requested_version}" >&2
    exit 1
fi


echo "Downloading Microsoft Git ${GIT_VERSION}..."

if command -v tdnf >/dev/null 2>&1; then
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

# Detect host architecture for arch-specific .deb packages (added in v2.52.0.vfs.0.5+)
ARCH="$(dpkg --print-architecture)"
DEB_URL="https://github.com/microsoft/git/releases/download/v${GIT_VERSION}/microsoft-git_${GIT_VERSION}_${ARCH}.deb"
DEB_FILE="microsoft-git_${GIT_VERSION}_${ARCH}.deb"

# Try arch-specific .deb first, fall back to legacy amd64 .deb for older releases
if ! wget -q "${DEB_URL}" -O "${DEB_FILE}" 2>/dev/null; then
    if [ "${ARCH}" != "amd64" ]; then
        echo "Could not download Microsoft Git ${GIT_VERSION} package for architecture ${ARCH}." >&2
        echo "Older Microsoft Git releases only published legacy amd64 Debian package assets." >&2
        exit 1
    fi
    DEB_URL="https://github.com/microsoft/git/releases/download/v${GIT_VERSION}/microsoft-git_${GIT_VERSION}.deb"
    DEB_FILE="microsoft-git_${GIT_VERSION}.deb"
    wget -q "${DEB_URL}" -O "${DEB_FILE}"
fi

dpkg -i "${DEB_FILE}"

rm "${DEB_FILE}"

rm -rf /var/lib/apt/lists/*
echo "Done!"