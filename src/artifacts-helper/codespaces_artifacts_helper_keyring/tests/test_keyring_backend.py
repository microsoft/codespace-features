from pathlib import Path

import keyring
import keyring.backend
import keyring.backends.chainer
import keyring.errors
import pytest
from jaraco.classes import properties

from codespaces_artifacts_helper_keyring import (
    ArtifactsHelperCredentialProvider,
    CodespacesArtifactsHelperKeyringBackend,
)

# Shouldn't be accessed by tests, but needs to be able
# to get past the quick check.
SUPPORTED_HOST = "https://pkgs.dev.azure.com/"


class FakeProvider(ArtifactsHelperCredentialProvider):
    def get_token(self, service):
        return "pass" + service[-4:]

    @staticmethod
    def auth_helper_installed(auth_tool_path):
        return True


class PasswordsBackend(keyring.backend.KeyringBackend):
    priority = 10.0  # type: ignore

    def __init__(self):
        self.passwords = {}

    def get_password(self, system, username):
        return self.passwords.get((system, username))

    def set_password(self, system, username, password):
        self.passwords[system, username] = password

    def delete_password(self, system, username):
        try:
            del self.passwords[system, username]
        except LookupError as e:
            raise keyring.errors.PasswordDeleteError(username) from e


class MockGetResponse:
    status_code = 200


@pytest.fixture
def only_backend():
    previous = keyring.get_keyring()
    backend = CodespacesArtifactsHelperKeyringBackend()
    keyring.set_keyring(backend)
    yield backend
    keyring.set_keyring(previous)


@pytest.fixture
def passwords(monkeypatch):
    passwords_backend = PasswordsBackend()

    def mock_get_all_keyring():
        return [CodespacesArtifactsHelperKeyringBackend(), passwords_backend]

    monkeypatch.setattr(keyring.backend, "get_all_keyring", mock_get_all_keyring)

    chainer_backend = keyring.backends.chainer.ChainerBackend()

    previous = keyring.get_keyring()
    keyring.set_keyring(chainer_backend)
    yield passwords_backend.passwords
    keyring.set_keyring(previous)


@pytest.fixture
def fake_provider(monkeypatch):
    monkeypatch.setattr(
        CodespacesArtifactsHelperKeyringBackend, "_PROVIDER", FakeProvider
    )


def test_get_credential_unsupported_host(only_backend):
    assert keyring.get_credential("https://example.com", None) is None


def test_get_credential_default_username(only_backend, fake_provider):
    creds = keyring.get_credential(SUPPORTED_HOST + "1234", "user12345678")
    assert creds.username == "user12345678"
    assert creds.password == "pass1234"


def test_get_credential_with_username(only_backend, fake_provider):
    creds = keyring.get_credential(SUPPORTED_HOST + "1234", None)
    assert creds.username == "codespaces"
    assert creds.password == "pass1234"


def test_set_password_raises(only_backend):
    with pytest.raises(NotImplementedError):
        keyring.set_password("SYSTEM", "USERNAME", "PASSWORD")


def test_set_password_fallback(passwords, fake_provider):
    # Ensure we are getting good credentials
    assert keyring.get_credential(SUPPORTED_HOST + "1234", None).password == "pass1234"

    assert keyring.get_password("SYSTEM", "USERNAME") is None
    keyring.set_password("SYSTEM", "USERNAME", "PASSWORD")
    assert passwords["SYSTEM", "USERNAME"] == "PASSWORD"
    assert keyring.get_password("SYSTEM", "USERNAME") == "PASSWORD"
    assert keyring.get_credential("SYSTEM", "USERNAME").username == "USERNAME"
    assert keyring.get_credential("SYSTEM", "USERNAME").password == "PASSWORD"

    # Ensure we are getting good credentials
    assert keyring.get_credential(SUPPORTED_HOST + "1234", None).password == "pass1234"


def test_delete_password_raises(only_backend):
    with pytest.raises(NotImplementedError):
        keyring.delete_password("SYSTEM", "USERNAME")


def test_delete_password_fallback(passwords, fake_provider):
    # Ensure we are getting good credentials
    assert keyring.get_credential(SUPPORTED_HOST + "1234", None).password == "pass1234"

    passwords["SYSTEM", "USERNAME"] = "PASSWORD"
    keyring.delete_password("SYSTEM", "USERNAME")
    assert keyring.get_password("SYSTEM", "USERNAME") is None
    assert not passwords
    with pytest.raises(keyring.errors.PasswordDeleteError):
        keyring.delete_password("SYSTEM", "USERNAME")


def test_cannot_delete_password(passwords, fake_provider):
    # Ensure we are getting good credentials
    creds = keyring.get_credential(SUPPORTED_HOST + "1234", "user1234")
    assert creds.username == "user1234"
    assert creds.password == "pass1234"

    with pytest.raises(keyring.errors.PasswordDeleteError):
        keyring.delete_password(SUPPORTED_HOST + "1234", creds.username)


def test_priority_when_helper_installed(monkeypatch):
    class MockProvider(ArtifactsHelperCredentialProvider):
        @staticmethod
        def resolve_auth_helper_path(auth_helper_path):
            return Path("fake-path")

        @properties.classproperty
        @classmethod
        def priority(cls) -> float:
            return True

    monkeypatch.setattr(
        CodespacesArtifactsHelperKeyringBackend, "_PROVIDER", MockProvider
    )

    assert CodespacesArtifactsHelperKeyringBackend.priority == 10.0
    assert CodespacesArtifactsHelperKeyringBackend().priority == 10.0


def test_priority_when_helper_not_installed(monkeypatch):
    class MockProvider(ArtifactsHelperCredentialProvider):
        @staticmethod
        def resolve_auth_helper_path(auth_helper_path):
            return None

        @properties.classproperty
        @classmethod
        def priority(cls) -> float:
            return False

    monkeypatch.setattr(
        CodespacesArtifactsHelperKeyringBackend, "_PROVIDER", MockProvider
    )

    with pytest.raises(RuntimeError):
        assert not CodespacesArtifactsHelperKeyringBackend.priority

    with pytest.raises(RuntimeError):
        assert not CodespacesArtifactsHelperKeyringBackend().priority
