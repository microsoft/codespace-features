#!/usr/bin/env bash

set -e

WRAPPER_INSTALL_PATH='/usr/local/share/codespace-features'
BINS_TO_CHECK=('yarn' 'npm' 'npx')

check_path_priority() {
    echo "Checking PATH priority"

    for BIN_NAME in "${BINS_TO_CHECK[@]}"; do
        if ! command -v "$BIN_NAME" &>/dev/null; then
            echo "Error: $BIN_NAME not found in PATH"
            exit 1
        fi

        # Check if the target binary is wrapped
        ACTUAL_BIN_PATH=$(command -v "$BIN_NAME")
        EXPECTED_BIN_PATH="$WRAPPER_INSTALL_PATH/$BIN_NAME"
        if ! grep -q "$EXPECTED_BIN_PATH" <<<"$ACTUAL_BIN_PATH"; then
            echo "Error: $BIN_NAME is not wrapped. We expected $EXPECTED_BIN_PATH but the actual binary path is $ACTUAL_BIN_PATH."
            echo "Please contact Clipchamp EngProd and let them know that the feed-auth-wrapper feature is not working as expected."
            exit 1
        fi

        echo "Success: $BIN_NAME is wrapped."
    done
}

check_bin_exec() {
    echo "Checking if the wrapped binaries get executed"

    WRAPPED_BINS_DIR=$(mktemp -d)
    BASH_BIN_DIR=$(dirname "$(command -v bash)")
    TEST_PATH="$WRAPPER_INSTALL_PATH:$WRAPPER_INSTALL_PATH:$WRAPPED_BINS_DIR:$BASH_BIN_DIR"

    for BIN_NAME in "${BINS_TO_CHECK[@]}"; do
        echo "Checking $BIN_NAME"
        echo "Creating a temporary binary to be shadowed by the wrapper"
        WRAPPED_BIN="$WRAPPED_BINS_DIR/$BIN_NAME"
        expected_stdout="Hello from $BIN_NAME"
        cat <<EOF >"$WRAPPED_BIN"
#!/usr/bin/env bash
if [ -z "\$ARTIFACTS_ACCESSTOKEN" ]; then
  echo "Error: ARTIFACTS_ACCESSTOKEN was not set! It should be set by the artifacts-helper wrapper."
  exit 1
fi
echo "$expected_stdout"
EOF
        chmod +x "$WRAPPED_BIN"

        echo "Executing $BIN_NAME to check if it wraps the temporary binary"
        actual_stdout=$(PATH="$TEST_PATH" "$BIN_NAME")
        actual_stderr=$(PATH="$TEST_PATH" "$BIN_NAME" 2>&1 >/dev/null)

        echo "Checking the output of the wrapper"
        echo "stdout: $actual_stdout"
        echo "stderr: $actual_stderr"
        if [ "$actual_stdout" = "$expected_stdout" ]; then
            echo "Success: wrapper for $BIN_NAME executed correctly."
        else
            echo "Error: wrapper for $BIN_NAME did not execute correctly. Expected '$expected_stdout' but got '$actual_stdout'."
            exit 1
        fi
    done

    rm -r "$WRAPPED_BINS_DIR"
    echo "Success: Wrapped binaries are executed correctly."
}

main() {
    echo "Starting scenario_executable_wrapper tests"

    check_path_priority
    check_bin_exec

    echo "scenario_executable_wrapper tests completed successfully"
}

main
