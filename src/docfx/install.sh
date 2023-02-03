#!/bin/bash

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
        sudo -u ${_REMOTE_USER} bash -c "cd ~ && dotnet tool install --global docfx"
        exit 0
    fi
fi

dotnet tool install --global docfx