
# Azure Artifacts Credential Helper (artifacts-helper)

Configures Codespace to authenticate with Azure Artifact feeds

## Example Usage

```json
"features": {
    "ghcr.io/microsoft/codespace-features/artifacts-helper:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| nugetURIPrefixes | Nuget URI Prefixes | string | https://pkgs.dev.azure.com/ |
| dotnet6 | Use .NET 6 Runtime | boolean | false |
| dotnetAlias | Create alias for dotnet | boolean | true |
| nugetAlias | Create alias for nuget | boolean | true |
| npmAlias | Create alias for npm | boolean | true |
| yarnAlias | Create alias for yarn | boolean | true |
| npxAlias | Create alias for npx | boolean | true |
| rushAlias | Create alias for rush | boolean | true |
| python | Install Python keyring helper for pip | boolean | false |
| targetFiles | Comma-separated list of files to write aliases to | string | DEFAULT (`/etc/bash.bashrc,/etc/zsh/zshrc` for `root`, otherwise `~/.bashrc,~/.zshrc`) |

## Customizations

### VS Code Extensions

- `ms-codespaces-tools.ado-codespaces-auth`

This installs [Azure Artifacts Credential Provider](https://github.com/microsoft/artifacts-credprovider)
and optionally configures functions which shadow `dotnet`, `nuget`, `npm`, `yarn`, and `rush` which dynamically sets an authentication token
for pulling artifacts from a feed before running the command.

For `npm`, `yarn`, and `rush` this requires that your `~/.npmrc` file is configured to use the ${ARTIFACTS_ACCESSTOKEN}
environment variable for the `authToken`. A helper script has been added that you can use to write your `~/.npmrc`
file during your setup process, though there are many ways you could accomplish this. To use the script, run it like
this:

```
write-npm.sh pkgs.dev.azure.com/orgname/projectname/_packaging/feed1/npm
write-npm.sh pkgs.dev.azure.com/orgname/projectname/_packaging/feed2/npm username
write-npm.sh pkgs.dev.azure.com/orgname/projectname/_packaging/feed3/npm username email
```

You must pass the feed name to the script, but you can optionally provide a username and email if desired. Defaults
are put in place if they are not provided. An example of the `.npmrc` file created is this:

```
//pkgs.dev.azure.com/orgname/projectname/_packaging/feed1/npm/registry/:username=codespaces
//pkgs.dev.azure.com/orgname/projectname/_packaging/feed1/npm/registry/:_authToken=${ARTIFACTS_ACCESSTOKEN}
//pkgs.dev.azure.com/orgname/projectname/_packaging/feed1/npm/registry/:email=codespaces@github.com
//pkgs.dev.azure.com/orgname/projectname/_packaging/feed1/npm/:username=codespaces
//pkgs.dev.azure.com/orgname/projectname/_packaging/feed1/npm/:_authToken=${ARTIFACTS_ACCESSTOKEN}
//pkgs.dev.azure.com/orgname/projectname/_packaging/feed1/npm/:email=codespaces@github.com
```

## Python Keyring Helper

Add the optional `{ "python" : true }` to install a Python Keyring helper that will handle authentication
to Python feeds using the same mechanism as the other languages. To install a package just run something
like:

```
pip install <package_name> --index-url https://pkgs.dev.azure.com/<org_name>/_packaging/<feed_name>/pypi/simple
```

When the feed URL is an Azure Artifacts feed pip will use the keyring helper to provide the credentials needed
to download the package.

## OS Support

This feature is tested to work on Debian/Ubuntu and Mariner CBL 2.0


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/microsoft/codespace-features/blob/main/src/artifacts-helper/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
