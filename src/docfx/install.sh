#!/bin/bash

DOCFX_VERSION=${VERSION:-"2.67.5"} 

if command -v tdnf >/dev/null 2>&1; then
    tdnf update
    tdnf install -y dotnet-sdk-6.0 sudo awk ca-certificates
    tdnf clean all
elif command -v apt-get >/dev/null 2>&1; then
    apt update
    apt-get install -y dotnet6
    rm -rf /var/lib/apt/lists/*
else
    echo "Unsupported package manager"
    exit 1
fi

# Check if dotnet is installed
if ! command -v dotnet >/dev/null 2>&1; then
    echo "dotnet is required to install DocFX"
    exit 1
fi


if command -v sudo >/dev/null 2>&1; then
    if [ "root" != "$_REMOTE_USER" ]; then
        if [ "latest" == "${DOCFX_VERSION}"]
            sudo -u ${_REMOTE_USER} bash -c "cd ~ && dotnet tool install --global docfx"
            exit 0
        else
            sudo -u ${_REMOTE_USER} bash -c "cd ~ && dotnet tool install --global docfx --version ${DOCFX_VERSION}"
            exit 0
        fi
    fi
fi

if [ "latest" == "${DOCFX_VERSION}"]
    dotnet tool install --global docfx
else
    dotnet tool install --global docfx --version ${DOCFX_VERSION}
fi