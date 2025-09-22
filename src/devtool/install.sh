#!/bin/sh

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
        rm -rf /var/lib/apt/lists/*
    fi
}

export DEBIAN_FRONTEND=noninteractive

if [ "${ID}" = "mariner" ]; then
    tdnf install -y curl ca-certificates tar
    tdnf clean all
else
    check_packages curl ca-certificates xdg-utils
fi

# --- Generate a 'install-devtool.sh' script to be executed by the 'postCreateCommand' lifecycle hook
DEVTOOL_SCRIPT_PATH="/usr/local/share/install-devtool.sh"

tee "$DEVTOOL_SCRIPT_PATH" > /dev/null \
<< EOF
#!/bin/bash
set -e
EOF

tee -a "$DEVTOOL_SCRIPT_PATH" > /dev/null \
<< 'EOF'

echo "::step::Waiting for AzDO Authentication Helper..."
# Wait up to 3 minutes for the ado-auth-helper to be installed
for i in {1..180}; do
    if [ -f ${HOME}/ado-auth-helper ]; then
        break
    fi
    sleep 1
done
echo "::step::Installing DevTool..."
cd /tmp
curl -sL https://aka.ms/InstallToolLinux.sh | bash -s DevTool
EOF

chmod 755 "$DEVTOOL_SCRIPT_PATH"

# Setup PATH so that DevTool will be on PATH when the initial terminal is started
if command -v sudo >/dev/null 2>&1; then
    if [ "root" != "$_REMOTE_USER" ]; then
        echo "Adding DevTool to PATH for $_REMOTE_USER"
        sudo -u ${_REMOTE_USER} bash -c 'echo "export PATH=\$PATH:$HOME/.config/DevTool/CurrentVersion" >> ~/.bashrc'
        sudo -u ${_REMOTE_USER} bash -c 'echo "export PATH=\$PATH:$HOME/.config/DevTool/CurrentVersion" >> ~/.zshrc'
        exit 0
    fi
fi

echo "Adding DevTool to PATH for root"
echo "export PATH=\$PATH:/root/.config/DevTool/CurrentVersion" >> /etc/bash.bashrc || true
echo "export PATH=\$PATH:/root/.config/DevTool/CurrentVersion" >> /etc/zsh/zshrc || true

exit 0
