
# External Git Repository in Codespace (external-repository)

Configures Codespace to work with an external Git repository

## Example Usage

```json
"features": {
    "ghcr.io/microsoft/codespace-features/external-repository:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| gitProvider | Git Provider | string | azuredevops |
| cloneUrl | Clone URL without username: https://dev.azure.com/{organization}/{project}/_git/{repository} | string | - |
| folder | Specify the workspace path in the devcontainer for the clone | string | /workspaces/external-repos |
| username | Username for clone (if required) | string | codespaces |
| cloneSecret | Name of the Codespaces repository secret that contains the token or password for clone. Example: ADO_PAT | string | - |
| userSecret | Name of the Codespaces user secret that contains the token or password for Codespace user | string | - |
| scalar | Use Scalar to clone the repository | boolean | false |
| sparseCheckout | Sparse checkout paths when using scalar. Example: common projecta/src projectb/src | string | - |
| options | Additional options for the clone operation: --depth 1 --single-branch --no-tags | string | - |
| branch | Default branch | string | main |
| timeout | Timeout for the clone operation | string | 30m |
| telemetrySource | Configure source of Git commit telemetry | string | none |

This feature standardizes and simplifies the proces of setting up a Codespace
to work with an external repository -- meaning a Git repository other than
the one that defines your Codespace. This is being primarily developed to
support Azure DevOps repositories but it ought to work with any Git repository.

This feature includes a CLI that handles the details of cloning the external repository
as well as configuring the Git authentication for the user of the Codespace by
providing a Git credential helper that does not conflict with the one that is
installed by Codespaces for the primary repository.

For Azure DevOps repositories, this installs what is currently a [fork of Git Credential Manager](https://github.com/markphip/git-credential-manager)
that adapts it to work in Codespaces. Specifically, when GCM attempts to use
the Device Code Flow to authenticate the user, rather than just output to the Terminal (which is
not visible when Git is run from the VSCode GUI) it also outputs a JSON file with the information.
A companion VSCode extension is installed by this feature that picks up
the JSON and displays UI to the user to initiate the flow.

Once we confirm this authentication flow is desirable, we will work with the GCM team to
upstream this feature in a way that is compatible with their design philosophy.

It is always possible to provide a token via the `userSecret` and this is what works with
other Git hosting providers.

## Example Usage Scenarios

Here is a minimal example that clones an Azure DevOps repository. This would also require
you to configure a Codespaces Prebuild and setup a Codespaces Repository secret named
**ADO_PAT** that contains a token with `read` access to the repository. We **strongly recommend**
that the token only have this scope.

```json
{
"image": "mcr.microsoft.com/devcontainers/universal:ubuntu",
"features": {
    "ghcr.io/microsoft/codespace-features/external-repository:latest": {
        "cloneUrl": "https://dev.azure.com/contoso/_git/reposname",
        "cloneSecret": "ADO_PAT",
        "folder": "/workspaces/ado-repos"
    }
},
"workspaceFolder": "/workspaces/ado-repos",
"initializeCommand": "mkdir -p ${localWorkspaceFolder}/../ado-repos",
"onCreateCommand": "external-git clone",
"postStartCommand": "external-git config"     
}
```

This would clone the repository to `/workspaces/ado-repos` during the Prebuild process
using the PAT stored in a Codespaces secret. At runtime, when a user opens the Codespace
the `workspaceFolder` feature would open VS Code to this folder automatically and it
would be configured to use Git Credential Manager to prompt the user for credentials
when they try to push/fetch the repository.

If you want to allow your users to use their own token, then you can add this to the configuration:

```json
        "userSecret": "ADO_SECRET"
```

If a user configures a Codespaces User Secret named `ADO_SECRET` and assigns this secret to the
Codespace, then the value of that secret will be used as a PAT for authentication. If the secret
is not defined by the user it will fallback to Git Credential Manager.

## Usage Telemetry

If you are looking for ways to track usage of Codespaces within your team, we offer a mechanism
to install a "telemetrySource" for git commits within the Codespace. This offers three options:

* `none`: the default. Does not make any changes to git
* `message`: installs commit-msg hook that adds a trailer to the commit message in the form of `Codespaces: name-of-codespace`
* `name`: changes the user name in the git configuration to `Existing Name (Codespaces)`
* `email`: changes the email address in the git configuration to `existing+codespaces@domain.com`

## OS Support

This feature is tested to work with Debian, Ubuntu and Mariner for the Codespaces base image


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/microsoft/codespace-features/blob/main/src/external-repository/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
