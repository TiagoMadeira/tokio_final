import sys;sys.path.append('.')
from app.main import app
from tests.conftest import setup_database
from fastapi.testclient import TestClient
from tests.fixtures import (valid_login_data,
                            valid_register_data, 
                            valid_existing_user_data, 
                            wrong_pass_login_data, 
                            get_bearer,
                            get_wrong_bearer,
                            password_not_matching_register_data)
import pytest

client = TestClient(app)

################################ Register tests ###########################################
def test_valid_register(setup_database, valid_register_data):
    response = client.post("/register", json=valid_register_data)
    assert response.status_code == 200
    assert response.json() == {
        "username": "valid",
        "email": "validemail@gmail.com",
        "full_name": "valid user",
    }

def test_register_existing_user(setup_database, valid_existing_user_data):
    response = client.post("/register", json=valid_existing_user_data)
    assert response.status_code == 400
    assert response.json() == {
        "detail": "User has already registered"
    }

def test_register_password_not_matching(setup_database, password_not_matching_register_data):
    response = client.post("/register", json=password_not_matching_register_data)
    assert response.status_code == 422

################################ Login tests ##############################################
def test_valid_login(setup_database, valid_login_data):
    response = client.post("/login",
                    data=valid_login_data ,
                    headers = {"content-type": "application/x-www-form-urlencoded"})
    data = response.json()
    assert response.status_code == 200
    assert not data["access_token"] == False
    assert data["token_type"] == "bearer"
      
def test_wrong_pass_login(setup_database, wrong_pass_login_data):
    response = client.post("/login",
                    data= wrong_pass_login_data,
                    headers = {"content-type": "application/x-www-form-urlencoded"})
    
    assert response.status_code == 401
    assert response.json() == {
        "detail": "Incorrect username or password"
    }

def test_wrong_user_login(setup_database, wrong_pass_login_data):
    response = client.post("/login",
                    data= wrong_pass_login_data,
                    headers = {"content-type": "application/x-www-form-urlencoded"})
    
    assert response.status_code == 401
    assert response.json() == {
        "detail": "Incorrect username or password"
    }

################################ Verify tests ##############################################

def test_valid_verify(setup_database, get_bearer):
    response = client.get("/verify?token=" + get_bearer)

    #expects correct user
    assert response.status_code == 200
    assert response.json() == {
        "username": "existing_user",
        "email": "existing@email.com",
        "full_name": "existing_user user"
    }

def test_wrong_user_verify(setup_database, get_wrong_bearer):
    response = client.get("/verify?token=" + get_wrong_bearer)

    assert response.status_code == 404
    assert response.json() == {
        "detail": "User not found"
    }

def test_incorrect_bearer_verify(setup_database):
    response = client.get("/verify?token=" + "dummy bearer" )

    assert response.status_code == 401
    assert response.json() == {
        "detail": "Authenticate failed"
    }