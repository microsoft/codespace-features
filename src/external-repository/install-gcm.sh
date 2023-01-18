#!/bin/sh
set -e

# Check if dpkg is installed (Debian/Ubuntu)
if command -v dpkg >/dev/null 2>&1; then
    # Check if wget is installed
    if ! command -v wget >/dev/null 2>&1; then
        apt update -y
        apt install -y wget
        rm -rf /var/lib/apt/lists/*
    fi
    wget -q https://github.com/markphip/git-credential-manager/releases/download/codespaces-1.0.1/gcm-linux_amd64.2.0.874.deb
    dpkg -i gcm-linux_amd64.2.0.874.deb
    rm gcm-linux_amd64.2.0.874.deb
    exit 0
fi

# Check if tdnf is installed (Mariner)
if command -v tdnf >/dev/null 2>&1; then
    PACKAGES="wget tar unzip ca-certificates"
    # Check if dotnet is installed
    if ! command -v dotnet >/dev/null 2>&1; then
        PACKAGES="${PACKAGES} dotnet-sdk-6.0"
    fi
    if ! command -v git >/dev/null 2>&1; then
        PACKAGES="${PACKAGES} git"
    fi
    tdnf -y install ${PACKAGES}
    tdnf clean all
    wget -q https://github.com/markphip/git-credential-manager/releases/download/codespaces-1.0.1/gcm-linux_amd64.2.0.875.tar.gz
    tar -xzf gcm-linux_amd64.2.0.875.tar.gz -C /usr/local/bin
    rm gcm-linux_amd64.2.0.875.tar.gz
    exit 0
fi