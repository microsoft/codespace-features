#!/bin/bash
# Azure CLI shim for GitHub Codespaces
# Intercepts 'az account get-access-token' requests and uses azure-auth-helper
# to acquire tokens via the ado-codespaces-auth VS Code extension.
#
# This enables DefaultAzureCredential's AzureCliCredential to work in Codespaces
# without requiring 'az login' (which times out waiting for browser auth).
#
# To install: Copy this to /usr/local/share/codespace-shims/az
# The shims directory should already be in PATH for Codespaces.

# If ACTIONS_ID_TOKEN_REQUEST_URL is set, we're in GitHub Actions - skip interception
if [ -n "${ACTIONS_ID_TOKEN_REQUEST_URL}" ]; then
    source "$(dirname $0)"/resolve-shim.sh
    AZ_EXE="$(resolve_shim)"
    exec "${AZ_EXE}" "$@"
fi

source "$(dirname $0)"/resolve-shim.sh

# Well-known resource type mappings (az account get-access-token --resource-type)
declare -A RESOURCE_TYPE_MAP=(
    ["arm"]="https://management.azure.com"
    ["aad-graph"]="https://graph.windows.net"
    ["ms-graph"]="https://graph.microsoft.com"
    ["batch"]="https://batch.core.windows.net"
    ["data-lake"]="https://datalake.azure.net"
    ["media"]="https://rest.media.azure.net"
    ["oss-rdbms"]="https://ossrdbms-aad.database.windows.net"
)

# Check if this is a get-access-token request that we should intercept
if [[ "$1" == "account" && "$2" == "get-access-token" ]]; then
    # Parse arguments to extract --resource, --scope, or --resource-type
    resource=""
    scope=""
    resource_type=""
    prev=""
    
    for arg in "${@:3}"; do
        case "$prev" in
            --resource)
                resource="$arg"
                ;;
            --scope)
                scope="$arg"
                ;;
            --resource-type)
                resource_type="$arg"
                ;;
        esac
        prev="$arg"
    done

    # Resolve resource-type to resource URL if specified
    if [[ -n "$resource_type" && -z "$resource" ]]; then
        resource="${RESOURCE_TYPE_MAP[$resource_type]}"
    fi

    # Determine the scope to request
    # Priority: explicit --scope > --resource/.default > --resource-type/.default
    request_scope=""
    if [[ -n "$scope" ]]; then
        request_scope="$scope"
    elif [[ -n "$resource" ]]; then
        # Append /.default if not already present
        if [[ "$resource" == *"/.default" ]]; then
            request_scope="$resource"
        else
            request_scope="${resource}/.default"
        fi
    fi

    # If we have a scope and azure-auth-helper exists, use it
    if [[ -n "$request_scope" && -f "${HOME}/azure-auth-helper" ]]; then
        # Get token from azure-auth-helper
        token=$("${HOME}/azure-auth-helper" get-access-token "$request_scope" 2>/dev/null)
        exit_code=$?

        if [[ $exit_code -eq 0 && -n "$token" ]]; then
            # Return in az CLI JSON format
            cat <<EOF
{
  "accessToken": "${token}",
  "tokenType": "Bearer"
}
EOF
            exit 0
        fi
        # Fall through to real az CLI if azure-auth-helper fails
    fi
fi

# Fall through to real az CLI for all other commands
AZ_EXE="$(resolve_shim)"
if [[ -n "$AZ_EXE" ]]; then
    exec "${AZ_EXE}" "$@"
else
    echo "Error: Azure CLI not found in PATH" >&2
    exit 1
fi
