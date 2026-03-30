import sys;sys.path.append('.')
import pytest
from app.main import app
from fastapi.testclient import TestClient
from fastapi.encoders import jsonable_encoder
from unittest.mock import patch
from app.config import settings
from app.schemas.auth import authRegister

from tests.conftest import  skip_auth
from tests.fixtures import (valid_register_data, 
                            valid_register_response_data,
                            valid_login_response_data,
                            valid_login_data,
                            mock_json_header)

client = TestClient(app)
#########################################################Register Test##########################################################
@patch('app.clients.auth_service.requests.post')
def test_register_user(mock_post, valid_register_data, valid_register_response_data, mock_json_header):
    #Mock setup
    mock_post.return_value.json.return_value = valid_register_response_data
    mock_post.return_value.status_code = 200
    #test
    response = client.post("/register", json=jsonable_encoder(valid_register_data))
    #assert
    data = response.json()
    client_url = "/register"
    assert response.status_code == 200
    assert data["username"] == valid_register_response_data["username"]
    assert data["email"] == valid_register_response_data["email"]
    assert data["full_name"] == valid_register_response_data["full_name"]
    mock_post.assert_called_once_with(settings.AUTH_SERVICE_URL + client_url, data=authRegister(**valid_register_data).model_dump_json(), headers=mock_json_header)


######################################################## Login Test #############################################################
@patch('app.clients.auth_service.requests.post')
def test_login(mock_post, valid_login_data, valid_login_response_data):
    #Mock setup
    mock_post.return_value.json.return_value = valid_login_response_data
    mock_post.return_value.status_code = 200
    #test
    response = client.post("/login",
                            data = valid_login_data,
                            headers = {"content-type": "application/x-www-form-urlencoded"})
    #assert
    data = response.json()
    client_url = "/login"
    assert response.status_code == 200
    assert not data["access_token"] == False
    assert data["token_type"] == "bearer"
    mock_post.assert_called_once_with(settings.AUTH_SERVICE_URL + client_url, data=valid_login_data)