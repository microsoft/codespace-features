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
cp ./scripts/*.sh /tmp

sed "s|REPLACE_WITH_AZURE_DEVOPS_NUGET_FEED_URL_PREFIX|${PREFIXES}|g" /tmp/run-dotnet.sh > /usr/local/bin/run-dotnet.sh
chmod +rx /usr/local/bin/run-dotnet.sh
sed "s|REPLACE_WITH_AZURE_DEVOPS_NUGET_FEED_URL_PREFIX|${PREFIXES}|g" /tmp/run-nuget.sh > /usr/local/bin/run-nuget.sh
chmod +rx /usr/local/bin/run-nuget.sh


if command -v sudo >/dev/null 2>&1; then
    if [ "root" != "$_REMOTE_USER" ]; then
        if [ "${ALIAS_DOTNET}" = "true" ]; then
            sudo -u ${_REMOTE_USER} bash -c "echo 'alias dotnet=/usr/local/bin/run-dotnet.sh'" >> ~/.bashrc
            sudo -u ${_REMOTE_USER} bash -c "echo 'alias dotnet=/usr/local/bin/run-dotnet.sh'" >> ~/.zshrc
        fi
        if [ "${ALIAS_NUGET}" = "true" ]; then
            sudo -u ${_REMOTE_USER} bash -c "echo 'alias nuget=/usr/local/bin/run-nuget.sh'" >> ~/.bashrc
            sudo -u ${_REMOTE_USER} bash -c "echo 'alias nuget=/usr/local/bin/run-nuget.sh'" >> ~/.zshrc
        fi
        if [ "${USENET6}" = "true" ]; then
            sudo -u ${_REMOTE_USER} bash -c "echo 'export USE_NET6_ARTIFACTS_CREDENTIAL_PROVIDER=true'" >> ~/.bashrc"
            sudo -u ${_REMOTE_USER} bash -c "echo 'export USE_NET6_ARTIFACTS_CREDENTIAL_PROVIDER=true'" >> ~/.zshrc"
        fi
        exit 0
    fi
fi

if [ "${ALIAS_DOTNET}" = "true" ]; then
    echo "alias dotnet='/usr/local/bin/run-dotnet.sh'" >> /etc/bash.bashrc
    echo "alias dotnet='/usr/local/bin/run-dotnet.sh'" >> /etc/zsh/zshrc
fi

if [ "${ALIAS_NUGET}" = "true" ]; then
    echo "alias nuget='/usr/local/bin/run-nuget.sh'" >> /etc/bash.bashrc
    echo "alias nuget='/usr/local/bin/run-nuget.sh'" >> /etc/zsh/zshrc
fi

if [ "${USENET6}" = "true" ]; then
   echo "export USE_NET6_ARTIFACTS_CREDENTIAL_PROVIDER=true" >> /etc/bash.bashrc
   echo "export USE_NET6_ARTIFACTS_CREDENTIAL_PROVIDER=true" >> /etc/zsh/zshrc
fi

exit 0