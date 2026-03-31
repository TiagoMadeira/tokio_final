import sys;sys.path.append('.')
from app.main import app
import pytest
from app.dependencies import verify_token
from tests.dependencies import test_verify_token


@pytest.fixture()
def skip_auth():
    app.dependency_overrides[verify_token] = test_verify_token
    yield
    app.dependency_overrides.pop(verify_token)