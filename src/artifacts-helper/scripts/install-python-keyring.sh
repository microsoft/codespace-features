#!/bin/bash


cd /tmp
wget https://github.com/microsoft/codespace-features/releases/download/latest/codespaces_artifacts_helper_keyring-0.1.0-py3-none-any.whl
if command -v python3 &> /dev/null
then
    python3 -m pip install codespaces_artifacts_helper_keyring-0.1.0-py3-none-any.whl
elif command -v python &> /dev/null
then
    python -m pip install codespaces_artifacts_helper_keyring-0.1.0-py3-none-any.whl
else
    echo "Python installation not detected. Artifacts Helper keyring not installed."
    exit 1
fi
