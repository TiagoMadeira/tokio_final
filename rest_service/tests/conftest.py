import sys;sys.path.append('.')
from app.main import app
import pytest
import httpx
import ssl
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
    # Create an SSL context for local integration testing
    ssl_context = ssl.create_default_context()
    ssl_context.check_hostname = False
    ssl_context.verify_mode = ssl.CERT_NONE
    with httpx.Client(verify=ssl_context) as client:
        yield client