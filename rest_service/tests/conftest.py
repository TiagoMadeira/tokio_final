import sys;sys.path.append('.')
from app.main import app
import pytest
import httpx
import os
from app.dependencies import verify_token
from tests.dependencies import test_verify_token

@pytest.fixture()
def skip_auth():
    app.dependency_overrides[verify_token] = test_verify_token
    yield
    app.dependency_overrides.pop(verify_token)

@pytest.fixture
def api_client():
    cert_path = "/etc/tls/tls.crt"
    ssl_verification = cert_path if os.path.exists(cert_path) else True
    with httpx.Client(verify=ssl_verification) as client:
        yield client