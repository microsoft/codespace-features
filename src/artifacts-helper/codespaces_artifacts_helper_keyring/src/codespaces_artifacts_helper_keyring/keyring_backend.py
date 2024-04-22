import warnings
from typing import Optional, Type
from urllib.parse import urlsplit

from jaraco.classes import properties
from keyring.backend import KeyringBackend
from keyring.credentials import Credential, SimpleCredential

from .artifacts_helper_credential_provider import ArtifactsHelperCredentialProvider


class CodespacesArtifactsHelperKeyringBackend(KeyringBackend):
    SUPPORTED_NETLOC = (
        "pkgs.dev.azure.com",
        "pkgs.visualstudio.com",
        "pkgs.codedev.ms",
        "pkgs.vsts.me",
    )

    _PROVIDER: Type[ArtifactsHelperCredentialProvider] = (
        ArtifactsHelperCredentialProvider
    )
    AUTH_HELPER_PATH = _PROVIDER.DEFAULT_AUTH_HELPER_PATH

    @properties.classproperty
    @classmethod
    def priority(cls) -> float:
        if not cls._PROVIDER.auth_helper_installed(cls.AUTH_HELPER_PATH):
            raise RuntimeError(
                f"Auth helper not found at {cls.AUTH_HELPER_PATH}. "
                "Install https://github.com/microsoft/ado-codespaces-auth"
            )
        return 10.0

    def get_credential(
        self, service: str, username: Optional[str]
    ) -> Optional[Credential]:
        if not self._is_supported_netloc(service):
            return None

        provider = self._PROVIDER(auth_helper_path=self.AUTH_HELPER_PATH)
        creds = provider.get_credentials(service)
        if creds is None:
            return None
        return SimpleCredential(creds.username or username, creds.password)

    def _is_supported_netloc(self, service) -> bool:
        try:
            parsed = urlsplit(service, scheme="https")
        except Exception as exc:
            warnings.warn(str(exc), stacklevel=2)
            return False

        netloc = parsed.netloc.rpartition("@")[-1]
        return netloc is not None and netloc.endswith(self.SUPPORTED_NETLOC)

    def get_password(self, service, username):
        creds = self.get_credential(service, None)
        if creds and username == creds.username:
            return creds.password
        return None

    def set_password(self, service, username, password):
        raise NotImplementedError()

    def delete_password(self, service, username):
        raise NotImplementedError()
