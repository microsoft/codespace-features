This feature standardizes and simplifies the process of setting up a Codespace
to work with an external repository -- meaning a Git repository other than
the one that defines your Codespace. This is being primarily developed to
support Azure DevOps repositories but it ought to work with any Git repository.

This feature includes a CLI that handles the details of cloning the external repository
as well as configuring the Git authentication for the user of the Codespace by
providing a Git credential helper that does not conflict with the one that is
installed by Codespaces for the primary repository.

For Azure DevOps repositories, this installs a companion VSCode extension that provides
a Git credential helper that uses the web browser to perform an OAuth 2.0 authentication
process.

It is always possible to provide a token via the `userSecret` and this is what works with
other Git hosting providers.

#### Microsoft Entra ID Tenant Configuration

The authentication to Azure DevOps happens on the default tenant. If the user is present on
multiple tenants, and the Azure DevOps organization for the repository belongs to a specific
one, the repository operations may fail (unauthorized). You can configure the tenant for
the authentication by providing it as setting to the the underlying extension in your devcontainer.json:

```json
"customizations": {
  "vscode":{
    "settings": { 
      "adoCodespacesAuth.tenantID": "<YOUR_ENTRA_ID_TENANT_ID>",
     }
   }
}
```

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
would be configured to prompt the user to login to Azure DevOps when they open the Codespace.

If you want to allow your users to use their own token, then you can add this to the configuration:

```json
        "userSecret": "ADO_SECRET"
```

If a user configures a Codespaces User Secret named `ADO_SECRET` and assigns this secret to the
Codespace, then the value of that secret will be used as a PAT for authentication. If the secret
is not defined by the user it will fallback to the browser login.

### Secret-less Azure DevOps Prebuilds

It is possible to avoid using PATs entirely and dynamically obtain a token during prebuild using
OIDC. This requires creating a Managed Identity or Service Principal in Entra, and creating a
Federated Identity Credential for the prebuild scenario. The identity you create must also be added
to Azure DevOps and given permission to the repositories and feeds you will be accessing during the
prebuild process. The configuration looks similar to the previous example but adds in new options
for the identity you have created:

```json
{
"image": "mcr.microsoft.com/devcontainers/universal:ubuntu",
"features": {
    "ghcr.io/devcontainers/features/azure-cli:1": {},
    "ghcr.io/microsoft/codespace-features/external-repository:latest": {
        "cloneUrl": "https://dev.azure.com/contoso/_git/reposname",
        "cloneSecret": "ADO_PAT",
        "clientID": "xxxx-yyyy-zzzz",
        "tenantID": "1111-2222-3333",
        "folder": "/workspaces/ado-repos"
    }
},
"workspaceFolder": "/workspaces/ado-repos",
"initializeCommand": "mkdir -p ${localWorkspaceFolder}/../ado-repos",
"onCreateCommand": "external-git clone",
"postStartCommand": "external-git config"     
}
```

In this scenario you do not need to add a Codespaces secret for `ADO_PAT`. Instead, during
the prebuild process this variable will be created and populated with a token obtained
via OIDC. This token will be used during the git clone process but then is otherwise available
for you to use in your scripts to install dependencies from feeds or anything else you may need.
The variable will only be available during the prebuild process.

You can name the variable anything you want, it does not need to be named `ADO_PAT` and in this case
it contains an OIDC bearer token, not a PAT.

> [!NOTE]
> You MUST install the Azure CLI feature in your devcontainer.json if using this option

### Interactive authentication only (avoids PAT token)

The advantage of using a PAT token is the ability to clone the repository during the devContainer creation
(onCreateCommand). You can avoid the need to configure a secret by requiring the authentication once the
Codespace loads. This means the repository will be cloned only after the Codespaces UI initializes completely:

```json
{
"image": "mcr.microsoft.com/devcontainers/universal:ubuntu",
"features": {
    "ghcr.io/microsoft/codespace-features/external-repository:latest": {
        "cloneUrl": "https://dev.azure.com/contoso/_git/reposname",
        "folder": "/workspaces/ado-repos"
    }
},
"workspaceFolder": "/workspaces/ado-repos",
"initializeCommand": "mkdir -p ${localWorkspaceFolder}/../ado-repos",
"postStartCommand": "external-git clone && external-git config"     
}
```

## Multiple Repository Support

As of version 3, you can clone multiple repositories by separating the URL's with a comma. In this
mode all of the repositories will be cloned to the folder. Each will get a local folder name from the
last part of the clone URL so this value has to be unique for each repository specified.

## AzDO Branch Support

When `external-git config` is executed it will check the branch name of the Codespaces bridge repository
and if it begins with "azdo/" then it will treat the rest of the branch name as an AzDO branch name
to checkout on the external repository. The idea here is that a utility could be created in AzDO that
would let you open a Pull Request in a Codespace. The process would create a new branch in the bridge
repository named "azdo/branch/name" and then create the Codespace on that branch name. When the Codespace
opens and clones the AzDO repository default branch it will then detect the need to fetch and checkout
the requested branch.

If a different process is desired for determining the branch name, then an environment variabled named
`AZDO_BRANCH` can be created with the name of the branch that should be checked out. When the `external-git config`
command runs it will also detect that this envvar is set and checkout that

## Usage Telemetry

If you are looking for ways to track usage of Codespaces within your team, we offer a mechanism
to install a "telemetrySource" for git commits within the Codespace. This offers three options:

* `none`: the default. Does not make any changes to git
* `message`: installs commit-msg hook that adds a trailer to the commit message in the form of `Codespaces: name-of-codespace`
* `name`: changes the user name in the git configuration to `Existing Name (Codespaces)`
* `email`: changes the email address in the git configuration to `existing+codespaces@domain.com`

## OS Support

This feature is tested to work with Debian, Ubuntu and Mariner for the Codespaces base image
