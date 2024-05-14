#!/bin/bash


cd /tmp
wget https://github.com/microsoft/codespace-features/releases/download/latest/codespaces_artifacts_helper_keyring-0.1.0-py3-none-any.whl
if command -v pip3 &> /dev/null
then
    pip3 install codespaces_artifacts_helper_keyring-0.1.0-py3-none-any.whl
elif command -v pip &> /dev/null
then
    pip install codespaces_artifacts_helper_keyring-0.1.0-py3-none-any.whl
else
    echo "pip installation not detected. Artifacts Helper keyring not installed."
    exit 1
fi
