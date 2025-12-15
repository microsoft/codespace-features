#!/bin/bash
[[ ${RESOLVE_SHIMS_IMPORTED} == "true" ]] && return
RESOLVE_SHIMS_IMPORTED=true

resolve_shim() {
    # Find the next non-shim executable in PATH so we do not run the shim again
    shim_file="$(readlink -f "${BASH_SOURCE[1]}")"
    executable="$(basename "$shim_file")"

    # Read into array first to handle spaces properly
    readarray -t candidates < <(which -a "$executable" 2>/dev/null)
    
    for candidate in "${candidates[@]}"; do
        # Skip any candidate which is a symlink to the shim file
        [[ "$(readlink -f "$candidate")" != "$shim_file" ]] && {
            echo "$candidate"
            return 0
        }
    done
    
    return 1
}