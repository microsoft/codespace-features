#!/bin/bash
[[ ${RESOLVE_SHIMS_IMPORTED} == "true" ]] && return
RESOLVE_SHIMS_IMPORTED=true

resolve_shim() {
    # Find the next non-shim executable in PATH so we do not run the shim again
    shim_file=$(readlink -f "${BASH_SOURCE[1]}")
    echo $(which -a dotnet | grep -vx "$shim_file" | head -n 1)
}