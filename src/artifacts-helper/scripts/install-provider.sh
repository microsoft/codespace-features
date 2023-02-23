#!/bin/bash

if [ "$1" = "true" ]; then
    echo "Installing artifacts-credprovider with .NET 6 framework"
    export USE_NET6_ARTIFACTS_CREDENTIAL_PROVIDER=true
else
    echo "Installing artifacts-credprovider with .NET 3.1 framework"
fi

wget -qO- https://aka.ms/install-artifacts-credprovider.sh | bash