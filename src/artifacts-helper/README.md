
# Azure Artifacts Credential Helper (artifacts-helper)

Configures Codespace to authenticate with Azure Artifact feeds

## Example Usage

```json
"features": {
    "ghcr.io/microsoft/codespace-features/artifacts-helper:2": {}
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
| pnpmAlias | Create alias for pnpm | boolean | true |
| targetFiles | Comma separated list of files to write to. Default is '/etc/bash.bashrc,/etc/zsh/zshrc' for root and '~/.bashrc,~/.zshrc' for non-root | string | DEFAULT |
| python | Install Python keyring helper for pip | boolean | false |
| wrapperType | Type of wrapper to use. Options are 'SHELL_FUNCTION' or 'EXECUTABLE' | string | `SHELL_FUNCTION` |

### Wrapper Types

| Wrapper Type | Description |
|-|-|
| `SHELL_FUNCTION` | Configures shell functions that wrap the commands to set the authentication token before calling the actual command. This is the default options. |
| `EXECUTABLE` | Configures a separate executable that wraps the commands to set the authentication token before calling the actual command. Suited for scenarios where the commands need to be invoked from scripts that do not consider shell functions, e.g. `subprocess.Popen(['npx'], shell=False)`. |

## Customizations

### VS Code Extensions

- `ms-codespaces-tools.ado-codespaces-auth`

This installs [Azure Artifacts Credential Provider](https://github.com/microsoft/artifacts-credprovider)
and optionally configures functions which shadow `dotnet`, `nuget`, `npm`, `yarn`, `rush`, and `pnpm` which dynamically sets an authentication token
for pulling artifacts from a feed before running the command.

For `npm`, `yarn`, `rush`, and `pnpm` this requires that your `~/.npmrc` file is configured to use the ${ARTIFACTS_ACCESSTOKEN}
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

## Changing where functions are configured

By default, the functions are defined in `/etc/bash.bashrc` and `/etc/zsh/zshrc` if the container user is `root`, otherwise `~/.bashrc` and `~/.zshrc`.
This default configuration ensures that the functions are always available for any interactive shells.

In some cases it can be useful to have the functions written to a non-default location. For example:
- the configuration file of a shell other than `bash` and `zsh`
- a custom file which is not a shell configuration script (so that it can be `source`d in non-interactive shells and scripts)

To do this, set the `targetFiles` option to the path script path where the functions should be written. Note that the default paths WILL NOT be used
if the `targetFiles` option is provided, so you may want to include them in the overridden value, or add `source` the custom script in those configurations:

```bash
# .devcontainer/devcontainer.json
{
    // ...
    "targetFiles": "/custom/path/to/auth-helper.sh"
}

# ~/.bashrc

source /custom/path/to/auth-helper.sh
```

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/microsoft/codespace-features/blob/main/src/artifacts-helper/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
