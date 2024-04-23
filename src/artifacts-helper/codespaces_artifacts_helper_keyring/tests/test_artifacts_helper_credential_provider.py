import os
import stat
import unittest
from pathlib import Path
from typing import Optional, Union

import pytest
from codespaces_artifacts_helper_keyring import ArtifactsHelperCredentialProvider
from codespaces_artifacts_helper_keyring.artifacts_helper_credential_provider import (
    ArtifactsHelperCredentialProviderError,
)


class TestArtifactsHelperWrapper(unittest.TestCase):
    SUPPORTED_HOST = "https://pkgs.dev.azure.com/"
    TEST_JWT = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1cG4iOiJ1cG5AY29udG9zby5jb20iLCJ1bmlxdWVfbmFtZSI6Im5hbWVAY29udG9zby5jb20ifQ.srKYrr5B0i29XERHsvE6mqZpLBzyyrX-gUKe9OHZODw"  # noqa: E501

    def __init__(self, *args, **kwargs) -> None:
        super().__init__(*args, **kwargs)
        self.tmp_dir: Optional[os.PathLike] = None
        self.script_name = "mock_artifacts_helper.py"

    @pytest.fixture(autouse=True)
    def init_tmp_dir(self, tmp_path):
        self.tmp_dir = Path(tmp_path)

    @property
    def script_path(self):
        return self.tmp_dir / self.script_name

    def write_script(self, content: str, shebang: str = "#!/usr/bin/env python3"):
        with open(self.script_path, "w", encoding="utf-8") as f:
            f.write(shebang + "\n")
            f.write(content)
        set_path_executable(self.script_path)

    def test_auth_helper_installed_invalid_path(self):
        assert not ArtifactsHelperCredentialProvider.resolve_auth_helper_path(
            self.tmp_dir / "nonexistent"
        )
        assert not ArtifactsHelperCredentialProvider.auth_helper_installed(
            self.tmp_dir / "nonexistent"
        )

    def test_auth_helper_installed_and_not_executable(self):
        self.write_script("pass")
        set_path_not_executable(self.script_path)
        assert not ArtifactsHelperCredentialProvider.resolve_auth_helper_path(
            self.script_path
        )
        assert not ArtifactsHelperCredentialProvider.auth_helper_installed(
            self.script_path
        )

    def test_auth_helper_installed_and_executable(self):
        self.write_script("pass")
        assert (
            ArtifactsHelperCredentialProvider.resolve_auth_helper_path(self.script_path)
            is not None
        )
        assert ArtifactsHelperCredentialProvider.auth_helper_installed(self.script_path)

    def test_get_token_from_helper(self):
        raw_token_value = "raw_token_here._-azAZ09"
        self.write_script(f"print('{raw_token_value}')")
        provider = ArtifactsHelperCredentialProvider(self.script_path)
        assert provider._get_token_from_helper() == raw_token_value.strip()

    def test_get_token_from_helper_not_installed(self):
        provider = ArtifactsHelperCredentialProvider()
        with pytest.raises(
            ArtifactsHelperCredentialProviderError, match="No authentication tool found"
        ):
            provider._get_token_from_helper()

    def test_get_token(self):
        self.write_script(f"print('{self.TEST_JWT}')")
        provider = ArtifactsHelperCredentialProvider(self.script_path)
        assert provider.get_token(self.SUPPORTED_HOST) == self.TEST_JWT

    def test_get_token_invalid_token(self):
        self.write_script(r"print('\n\n\n')")
        provider = ArtifactsHelperCredentialProvider(self.script_path)
        assert provider.get_token(self.SUPPORTED_HOST) is None

    def test_get_token_helper_non_zero_exit(self):
        self.write_script("exit(1)")
        provider = ArtifactsHelperCredentialProvider(self.script_path)
        with pytest.raises(
            ArtifactsHelperCredentialProviderError,
            match=f"Process .*{self.script_name}.* exited with code 1",
        ):
            provider.get_token(self.SUPPORTED_HOST)


def set_path_executable(path: Union[os.PathLike, str]):
    p = Path(path)
    p.chmod(p.stat().st_mode | stat.S_IEXEC)


def set_path_not_executable(path: Union[os.PathLike, str]):
    p = Path(path)
    p.chmod(p.stat().st_mode & ~stat.S_IEXEC)
