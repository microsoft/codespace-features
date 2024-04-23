"""Wrapper to interface with the artifacts authentication helper."""

from __future__ import absolute_import

import os
import shutil
import subprocess
from pathlib import Path
from typing import Optional, Union

import requests


class ArtifactsHelperCredentialProviderError(RuntimeError):
    """Generic error for ArtifactsHelperCredentialProvider."""


class ArtifactsHelperCredentialProvider:
    """A wrapper retrieve credentials from the artifacts authentication helper.

    The authentication helper should be installed from
    https://github.com/microsoft/ado-codespaces-auth.

    Attributes:
        DEFAULT_AUTH_HELPER_PATH: The default path to the authentication helper
            executable.

    Raises:
        ArtifactsHelperCredentialProviderError: When the credentials could not be
            retrieved.
    """

    DEFAULT_AUTH_HELPER_PATH = "~/ado-auth-helper"

    def __init__(
        self,
        auth_helper_path: Union[os.PathLike, str] = DEFAULT_AUTH_HELPER_PATH,
        timeout: int = 30,
    ):
        """Initialise the provider.

        Args:
            auth_helper_path: The path to the authentication helper executable, or the
                name of the executable if it is in the PATH. Defaults to
                DEFAULT_AUTH_HELPER_PATH.

            timeout: The timeout in seconds for calling the authentication helper and
                any HTTP requests made to test credentials. Defaults to 30.
        """
        self.auth_tool_path = self.resolve_auth_helper_path(auth_helper_path)
        self.timeout = timeout

    @staticmethod
    def resolve_auth_helper_path(
        auth_helper_path: Union[os.PathLike, str],
    ) -> Optional[str]:
        """Resolve the path to the authentication helper executable.

        Returns:
            The path to the authentication helper executable, or `None` if it is not
            executable or not found.
        """
        return shutil.which(str(Path(auth_helper_path).expanduser()), mode=os.X_OK)

    @classmethod
    def auth_helper_installed(cls, auth_helper_path: Union[os.PathLike, str]) -> bool:
        """Check whether the authentication helper is installed and executable."""
        return cls.resolve_auth_helper_path(auth_helper_path) is not None

    def get_token(self, url: str) -> Optional[str]:
        """Get an access token for the given URL.

        Args:
            url: The URL to retrieve credentials for.

        Returns:
            The token for the URL, or `None` if no credentials could be retrieved.
        """
        # Public feed short circuit: return nothing if not getting credentials for the
        # upload endpoint (which always requires auth) and the endpoint is public (can
        # authenticate without credentials).
        if not self._is_upload_endpoint(url) and self._can_authenticate(url, None):
            return None

        token = self._get_token_from_helper()
        return token if token else None

    @staticmethod
    def _is_upload_endpoint(url) -> bool:
        url = url[:-1] if url[-1] == "/" else url
        return url.endswith("pypi/upload")

    def _can_authenticate(self, url, auth) -> bool:
        response = requests.get(url, auth=auth, timeout=self.timeout)
        return response.status_code < 500 and response.status_code not in (401, 403)

    def _get_token_from_helper(self) -> str:
        if self.auth_tool_path is None:
            raise ArtifactsHelperCredentialProviderError(
                "Failed to get credentials: No authentication tool found"
            )

        try:
            p = subprocess.run(
                [self.auth_tool_path, "get-access-token"],
                capture_output=True,
                encoding="utf-8",
                check=True,
                timeout=self.timeout,
            )
            stdout = p.stdout
            if stdout:
                return stdout.strip()
            else:
                raise ArtifactsHelperCredentialProviderError(
                    "Failed to get credentials: "
                    f"No output from subprocess {self.auth_tool_path}"
                )

        except subprocess.CalledProcessError as e:
            raise ArtifactsHelperCredentialProviderError(
                f"Failed to get credentials: Process {self.auth_tool_path} exited with "
                f"code {e.returncode}. Error: {e.stderr}"
            ) from e
        except subprocess.TimeoutExpired as e:
            raise ArtifactsHelperCredentialProviderError(
                f"Failed to get credentials: Process {self.auth_tool_path} timed out "
                f"after {self.timeout} seconds"
            ) from e
