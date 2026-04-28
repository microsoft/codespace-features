#!/usr/bin/env bash

# Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib || exit 1

check "non-root bash aliases written" grep -q 'dotnet() { ".*/dotnet" "\$@"; }' /home/vscode/.bashrc
check "non-root zsh aliases written" grep -q 'npm() { ".*/npm" "\$@"; }' /home/vscode/.zshrc

reportResults
