from app.main import app
from fastapi.testclient import TestClient
from fastapi.encoders import jsonable_encoder

from tests.conftest import  (skip_auth, api_client)
from tests.fixtures import (valid_register_data, 
                            valid_login_data,
                            wrong_pass_login_data,
                            wrong_user_login_data,
                            valid_existing_register_data,
                            password_not_matching_register_data)

# Define endpoints based on your port-forwarding or tunnel
REST_SERVICE_URL = "http://localhost:8000"
#########################################################Register Test##########################################################
def test_register_user(api_client, valid_register_data):
    #test
    response = api_client.post("/register", json=jsonable_encoder(valid_register_data))
    #assert
    data = response.json()
    assert response.status_code == 200
    assert data["username"] == valid_register_data["username"]
    assert data["email"] == valid_register_data["email"]
    assert data["full_name"] == valid_register_data["full_name"]

def test_register_user_already_exists(api_client, valid_existing_register_data):
    #setup
    api_client.post("/register", json=jsonable_encoder(valid_existing_register_data))
    #test
    response = api_client.post("/register", json=jsonable_encoder(valid_existing_register_data))
    #assert
    assert response.status_code == 400
    assert response.json() == {
        "detail": "User has already registered"
    }

def test_register_password_not_matching(api_client, password_not_matching_register_data):
    #test
    response = api_client.post("/register", json=password_not_matching_register_data)
    #assert
    assert response.status_code == 422

#########################################################Login Tests##########################################################

def test_valid_login(api_client, valid_login_data ):
    #test
    response = api_client.post("/login",
                            data = valid_login_data,
                            headers = {"content-type": "application/x-www-form-urlencoded"})
    #assert
    data = response.json()
    assert response.status_code == 200
    assert not data["access_token"] == False
    assert data["token_type"] == "bearer"

def test_wrong_pass_login(api_client, wrong_pass_login_data):
    response = api_client.post("/login",
                    data= wrong_pass_login_data,
                    headers = {"content-type": "application/x-www-form-urlencoded"})
    
    assert response.status_code == 401
    assert response.json() == {
        "detail": "Incorrect username or password"
    }

def test_wrong_user_login(api_client, wrong_pass_login_data):
    response = api_client.post("/login",
                    data= wrong_pass_login_data,
                    headers = {"content-type": "application/x-www-form-urlencoded"})
    
    assert response.status_code == 401
    assert response.json() == {
        "detail": "Incorrect username or password"
    }