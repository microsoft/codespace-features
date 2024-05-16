#!/usr/bin/env bash

set -e

WHEEL_URL='https://github.com/microsoft/codespace-features/releases/download/latest/codespaces_artifacts_helper_keyring-0.1.0-py3-none-any.whl'
WHEEL_DEST_FILENAME='codespaces_artifacts_helper_keyring-0.1.0-py3-none-any.whl'

cd /tmp

while [[ "$#" -gt 0 ]]; do
    case $1 in
    -h | --help)
        echo "Usage: $(basename "$0") [(-u | --user) <user>] [-h | --help]

Options:
  -h --help             Show this screen.
  -u USER, --user USER  Install for another user by specifying their name.
                        Alternatively, set the USER environment variable.
"
        exit
        ;;

    -u | --user)
        USER="$2"
        shift
        ;;

    *)
        echo "Unknown parameter passed: $1"
        exit 1
        ;;
    esac
    shift
done

# Find the path to the Python executable outside of sudo, to account for Python
# not being present in the secure_path.
if command -v python3 &>/dev/null; then
    PYTHON_SRC=$(which python3)
elif command -v python &>/dev/null; then
    PYTHON_SRC=$(which python)
else
    echo "Python not found. Artifacts Helper keyring not installed. whoami=$(whoami), PATH=$PATH"
    exit 1
fi

sudo_if_user() {
    COMMAND="$*"
    if [[ $USER ]]; then
        if ! command -v sudo >/dev/null 2>&1; then
            echo "The --user option was specified, but sudo could not be found."
            exit 1
        fi
        sudo -u "$USER" bash -c "$COMMAND"
    else
        $COMMAND
    fi
}

install_user_package() {
    sudo_if_user "${PYTHON_SRC}" -m pip install --user --upgrade --no-cache-dir "$1"
}

wget "$WHEEL_URL" -O "$WHEEL_DEST_FILENAME"
chmod a=r "$WHEEL_DEST_FILENAME" # Usually not needed, but helpful just in case
install_user_package "$WHEEL_DEST_FILENAME"
rm "$WHEEL_DEST_FILENAME"
