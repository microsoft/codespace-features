#!/bin/sh

set -e

PREFIXES="${NUGETURIPREFIXES:-"https://pkgs.dev.azure.com/"}"
USENET6="${DOTNET6:-"false"}"
ALIAS_DOTNET="${DOTNETALIAS:-"true"}"
ALIAS_NUGET="${NUGETALIAS:-"true"}"
ALIAS_NPM="${NPMALIAS:-"true"}"
ALIAS_YARN="${YARNALIAS:-"true"}"
ALIAS_NPX="${NPXALIAS:-"true"}"
ALIAS_RUSH="${RUSHALIAS:-"true"}"
INSTALL_PIP_HELPER="${PYTHON:-"false"}"

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
        rm -rf /var/lib/apt/lists/*
    fi
}

export DEBIAN_FRONTEND=noninteractive

if [ "${ID}" = "mariner" ]; then
    tdnf install -y wget ca-certificates
    tdnf clean all
else
    check_packages wget ca-certificates
fi

# Change to the directory where this script is located
cd "$(dirname "$0")"

cp ./scripts/install-provider.sh /tmp
chmod +rx /tmp/install-provider.sh
cp ./scripts/install-python-keyring.sh /tmp
chmod +rx /tmp/install-python-keyring.sh

sed "s|REPLACE_WITH_AZURE_DEVOPS_NUGET_FEED_URL_PREFIX|${PREFIXES}|g" ./scripts/run-dotnet.sh > /usr/local/bin/run-dotnet.sh
chmod +rx /usr/local/bin/run-dotnet.sh
sed "s|REPLACE_WITH_AZURE_DEVOPS_NUGET_FEED_URL_PREFIX|${PREFIXES}|g" ./scripts/run-nuget.sh > /usr/local/bin/run-nuget.sh
chmod +rx /usr/local/bin/run-nuget.sh
cp ./scripts/run-npm.sh /usr/local/bin/run-npm.sh
chmod +rx /usr/local/bin/run-npm.sh
cp ./scripts/run-yarn.sh /usr/local/bin/run-yarn.sh
chmod +rx /usr/local/bin/run-yarn.sh
cp ./scripts/write-npm.sh /usr/local/bin/write-npm.sh
chmod +rx /usr/local/bin/write-npm.sh
cp ./scripts/run-npx.sh /usr/local/bin/run-npx.sh
chmod +rx /usr/local/bin/run-npx.sh

cp ./scripts/run-rush.sh /usr/local/bin/run-rush.sh
chmod +rx /usr/local/bin/run-rush.sh
cp ./scripts/run-rush-pnpm.sh /usr/local/bin/run-rush-pnpm.sh
chmod +rx /usr/local/bin/run-rush-pnpm.sh


if command -v sudo >/dev/null 2>&1; then
    if [ "root" != "$_REMOTE_USER" ]; then
        if [ "${ALIAS_DOTNET}" = "true" ]; then
            sudo -u ${_REMOTE_USER} bash -c "echo 'alias dotnet=/usr/local/bin/run-dotnet.sh' >> ~/.bashrc"
            sudo -u ${_REMOTE_USER} bash -c "echo 'alias dotnet=/usr/local/bin/run-dotnet.sh' >> ~/.zshrc"
        fi
        if [ "${ALIAS_NUGET}" = "true" ]; then
            sudo -u ${_REMOTE_USER} bash -c "echo 'alias nuget=/usr/local/bin/run-nuget.sh' >> ~/.bashrc"
            sudo -u ${_REMOTE_USER} bash -c "echo 'alias nuget=/usr/local/bin/run-nuget.sh' >> ~/.zshrc"
        fi
        if [ "${ALIAS_NPM}" = "true" ]; then
            sudo -u ${_REMOTE_USER} bash -c "echo 'alias npm=/usr/local/bin/run-npm.sh' >> ~/.bashrc"
            sudo -u ${_REMOTE_USER} bash -c "echo 'alias npm=/usr/local/bin/run-npm.sh' >> ~/.zshrc"
        fi
        if [ "${ALIAS_YARN}" = "true" ]; then
            sudo -u ${_REMOTE_USER} bash -c "echo 'alias yarn=/usr/local/bin/run-yarn.sh' >> ~/.bashrc"
            sudo -u ${_REMOTE_USER} bash -c "echo 'alias yarn=/usr/local/bin/run-yarn.sh' >> ~/.zshrc"
        fi
        if [ "${ALIAS_NPX}" = "true" ]; then
            sudo -u ${_REMOTE_USER} bash -c "echo 'alias npx=/usr/local/bin/run-npx.sh' >> ~/.bashrc"
            sudo -u ${_REMOTE_USER} bash -c "echo 'alias npx=/usr/local/bin/run-npx.sh' >> ~/.zshrc"
        fi
        if [ "${ALIAS_RUSH}" = "true" ]; then
            sudo -u ${_REMOTE_USER} bash -c "echo 'alias rush=/usr/local/bin/run-rush.sh' >> ~/.bashrc"
            sudo -u ${_REMOTE_USER} bash -c "echo 'alias rush=/usr/local/bin/run-rush.sh' >> ~/.zshrc"

            sudo -u ${_REMOTE_USER} bash -c "echo 'alias rush-pnpm=/usr/local/bin/run-rush-pnpm.sh' >> ~/.bashrc"
            sudo -u ${_REMOTE_USER} bash -c "echo 'alias rush-pnpm=/usr/local/bin/run-rush-pnpm.sh' >> ~/.zshrc"
        fi
        sudo -u ${_REMOTE_USER} bash -c "/tmp/install-provider.sh ${USENET6}"
        rm /tmp/install-provider.sh
        if [ "${INSTALL_PIP_HELPER}" = "true" ]; then
        # check if python is installed
            if command -v python3 >/dev/null 2>&1; then
                sudo -u ${_REMOTE_USER} bash -c "/tmp/install-python-keyring.sh"
                rm /tmp/install-python-keyring.sh
            else
                echo "Python installation not detected, keyring helper not installed."
            fi
        fi
        exit 0
    fi
fi

if [ "${ALIAS_DOTNET}" = "true" ]; then
    echo "alias dotnet='/usr/local/bin/run-dotnet.sh'" >> /etc/bash.bashrc || true
    echo "alias dotnet='/usr/local/bin/run-dotnet.sh'" >> /etc/zsh/zshrc || true
fi

if [ "${ALIAS_NUGET}" = "true" ]; then
    echo "alias nuget='/usr/local/bin/run-nuget.sh'" >> /etc/bash.bashrc || true
    echo "alias nuget='/usr/local/bin/run-nuget.sh'" >> /etc/zsh/zshrc || true
fi

if [ "${ALIAS_NPM}" = "true" ]; then
    sudo -u ${_REMOTE_USER} bash -c "echo 'alias npm=/usr/local/bin/run-npm.sh' >> /etc/bash.bashrc || true
    sudo -u ${_REMOTE_USER} bash -c "echo 'alias npm=/usr/local/bin/run-npm.sh' >> /etc/zsh/zshrc || true
fi

if [ "${ALIAS_YARN}" = "true" ]; then
    sudo -u ${_REMOTE_USER} bash -c "echo 'alias yarn=/usr/local/bin/run-yarn.sh' >> /etc/bash.bashrc || true
    sudo -u ${_REMOTE_USER} bash -c "echo 'alias yarn=/usr/local/bin/run-yarn.sh' >> /etc/zsh/zshrc || true
fi

if [ "${ALIAS_NPX}" = "true" ]; then
    sudo -u ${_REMOTE_USER} bash -c "echo 'alias npx=/usr/local/bin/run-npx.sh' >> /etc/bash.bashrc || true
    sudo -u ${_REMOTE_USER} bash -c "echo 'alias npx=/usr/local/bin/run-npx.sh' >> /etc/zsh/zshrc || true
fi

if [ "${ALIAS_RUSH}" = "true" ]; then
    sudo -u ${_REMOTE_USER} bash -c "echo 'alias rush=/usr/local/bin/run-rush.sh' >> /etc/bash.bashrc || true
    sudo -u ${_REMOTE_USER} bash -c "echo 'alias rush=/usr/local/bin/run-rush.sh' >> /etc/zsh/zshrc || true

    sudo -u ${_REMOTE_USER} bash -c "echo 'alias rush-pnpm=/usr/local/bin/run-rush-pnpm.sh' >> /etc/bash.bashrc || true
    sudo -u ${_REMOTE_USER} bash -c "echo 'alias rush-pnpm=/usr/local/bin/run-rush-pnpm.sh' >> /etc/zsh/zshrc || true
fi

if [ "${INSTALL_PIP_HELPER}" = "true" ]; then
# check if python is installed
    if command -v python3 >/dev/null 2>&1; then
        bash -c "/tmp/install-python-keyring.sh"
        rm /tmp/install-python-keyring.sh
    else
        echo "Python installation not detected, keyring helper not installed."
    fi
fi
rm /tmp/install-provider.sh

exit 0