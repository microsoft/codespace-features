#!/bin/sh

set -e

PREFIXES="${NUGETURIPREFIXES:-"https://pkgs.dev.azure.com/"}"
USENET6="${DOTNET6:-"false"}"
ALIAS_DOTNET="${DOTNETALIAS:-"true"}"
ALIAS_NUGET="${NUGETALIAS:-"true"}"

if [ "$(id -u)" -ne 0 ]; then
    echo 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Change to the directory where this script is located
cd "$(dirname "$0")"

# Install the Azure Artifacts Credential Provider
if [ "${USENET6}" = "true" ]; then
   export USE_NET6_ARTIFACTS_CREDENTIAL_PROVIDER=true
fi
wget -qO- https://aka.ms/install-artifacts-credprovider.sh | bash
unset USE_NET6_ARTIFACTS_CREDENTIAL_PROVIDER

sed "s/REPLACE_WITH_AZURE_DEVOPS_NUGET_FEED_URL_PREFIX/${PREFIXES}/g" ./scripts/run-dotnet.sh > /usr/local/bin/run-dotnet.sh
chmod +rx /usr/local/bin/run-dotnet.sh
sed "s/REPLACE_WITH_AZURE_DEVOPS_NUGET_FEED_URL_PREFIX/${PREFIXES}/g" ./scripts/run-nuget.sh > /usr/local/bin/run-nuget.sh
chmod +rx /usr/local/bin/run-nuget.sh

if [ "${ALIAS_DOTNET}" = "true" ]; then
    echo "alias dotnet='/usr/local/bin/run-dotnet.sh'" >> /etc/bash.bashrc
    echo "alias dotnet='/usr/local/bin/run-dotnet.sh'" >> /etc/zsh/zshrc
fi

if [ "${ALIAS_NUGET}" = "true" ]; then
    echo "alias nuget='/usr/local/bin/run-nuget.sh'" >> /etc/bash.bashrc
    echo "alias nuget='/usr/local/bin/run-nuget.sh'" >> /etc/zsh/zshrc
fi

exit 0