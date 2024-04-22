# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE in the project root for license information.
# --------------------------------------------------------------------------------------------

from __future__ import absolute_import

import os
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Union

import jwt
import requests


@dataclass
class Credentials:
    username: str
    password: str


class ArtifactsHelperCredentialProviderError(RuntimeError):
    pass


class ArtifactsHelperCredentialProvider:
    DEFAULT_AUTH_HELPER_PATH = "~/ado-auth-helper"

    def __init__(
        self,
        auth_helper_path: Union[os.PathLike, str] = DEFAULT_AUTH_HELPER_PATH,
        timeout: int = 30,
    ):
        self.auth_tool_path = self.resolve_auth_helper_path(auth_helper_path)
        self.timeout = timeout

    @staticmethod
    def resolve_auth_helper_path(
        auth_helper_path: Union[os.PathLike, str],
    ) -> Optional[str]:
        return shutil.which(str(Path(auth_helper_path).expanduser()), mode=os.X_OK)

    @classmethod
    def auth_helper_installed(cls, auth_helper_path: Union[os.PathLike, str]) -> bool:
        return cls.resolve_auth_helper_path(auth_helper_path) is not None

    def get_credentials(self, url) -> Optional[Credentials]:
        # Public feed short circuit: return nothing if not getting credentials for the upload endpoint
        # (which always requires auth) and the endpoint is public (can authenticate without credentials).
        if not self._is_upload_endpoint(url) and self._can_authenticate(url, None):
            return None

        jwt_str = self._get_jwt_from_helper()
        if not jwt_str:
            return None

        return self._get_credentials_from_jwt(jwt_str)

    @staticmethod
    def _is_upload_endpoint(url) -> bool:
        url = url[:-1] if url[-1] == "/" else url
        return url.endswith("pypi/upload")

    def _can_authenticate(self, url, auth) -> bool:
        response = requests.get(url, auth=auth, timeout=self.timeout)
        return response.status_code < 500 and response.status_code not in (401, 403)

    def _get_jwt_from_helper(self) -> str:
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
                    f"Failed to get credentials: No output from subprocess {self.auth_tool_path}"
                )

        except subprocess.CalledProcessError as e:
            raise ArtifactsHelperCredentialProviderError(
                f"Failed to get credentials: Process {self.auth_tool_path} exited with code {e.returncode}. Error: {e.stderr}"
            ) from e
        except subprocess.TimeoutExpired as e:
            raise ArtifactsHelperCredentialProviderError(
                f"Failed to get credentials: Process {self.auth_tool_path} timed out after {self.timeout} seconds"
            ) from e

    def _get_credentials_from_jwt(self, jwt_str: str) -> Credentials:
        try:
            decoded = jwt.decode(
                jwt_str, verify=False, options={"verify_signature": False}
            )
            return Credentials(
                username=decoded.get("unique_name", decoded.get("upn", None)),
                password=jwt_str,
            )
        except jwt.PyJWTError as e:
            raise ArtifactsHelperCredentialProviderError(
                f"Failed to decode JWT: {e}"
            ) from e
