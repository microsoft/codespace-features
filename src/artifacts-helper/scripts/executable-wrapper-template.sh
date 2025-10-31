#!/usr/bin/env bash

# Recursively unwrap itself from the path, eventually calling the target binary's
# `run-<target>.sh` script, which will inject a feed authentication token.

TARGET_BIN_NAME=TARGET_BIN_NAME

log() {
  # Print to stderr to avoid interfering with scripts that capture stdout.
  # Prefix error messages so the user can quickly determine that it's from our
  # artifacts-helper wrapper, not an error originating from the wrapped binary.
  printf >&2 "[codespace-features/artifacts-helper] %s" "$1"
}

log_line() {
  log "$1
"
}

call_wrapped_bin() {
  CURRENT_SCRIPT_PATH=$(realpath "${BASH_SOURCE[0]}")
  if [ -z "$CURRENT_SCRIPT_PATH" ]; then
    log_line "Error: Current script path could not be determined! This will result in infinite recursion. Bailing early."
    exit 1
  fi

  # Find the next executable from the PATH order, which would be shadowed by this wrapper
  if [ -z "$ARTIFACTS_HELPER_TARGET_BIN_PATHS" ]; then
    ARTIFACTS_HELPER_TARGET_BIN_PATHS=$(which -a "$TARGET_BIN_NAME")
  fi

  ARTIFACTS_HELPER_TARGET_BIN_PATHS=$(sed '/^[[:space:]]*$/d' <<<"$ARTIFACTS_HELPER_TARGET_BIN_PATHS")
  ARTIFACTS_HELPER_TARGET_BIN_PATHS=$(grep --color=never -Fve "$CURRENT_SCRIPT_PATH" <<<"$ARTIFACTS_HELPER_TARGET_BIN_PATHS")
  NEXT_SHADOWED_BIN=$(head -n 1 <<<"$ARTIFACTS_HELPER_TARGET_BIN_PATHS")
  if [ -z "$NEXT_SHADOWED_BIN" ]; then
    log_line "Error: The real $TARGET_BIN_NAME could not be found on PATH."
    log_line "which -a $TARGET_BIN_NAME:\n%s\n" "$(which -a $TARGET_BIN_NAME)"
    log_line "CC_SHADOWED_BINS:\n%s\n" "$ARTIFACTS_HELPER_TARGET_BIN_PATHS"
    log_line "CURRENT_SCRIPT_PATH: %s\n" "$CURRENT_SCRIPT_PATH"
    exit 1
  fi

  # Recursively removing the wrapper script(s) from the shadowed bin paths will
  # allow us to account for circumstances where the wrapper script appears multiple
  # times on the PATH. We will eventually descend to the real target binary.
  export ARTIFACTS_HELPER_TARGET_BIN_PATHS

  log_line "Running: %s\n" "$NEXT_SHADOWED_BIN"
  ${NEXT_SHADOWED_BIN} "$@"
  return "$?"
}

call_wrapped_bin "$@"
exit $?
