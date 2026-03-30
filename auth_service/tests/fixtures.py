from app.auth.jwt_tokens_service import create_access_token
import pytest
from fastapi.encoders import jsonable_encoder

@pytest.fixture
def valid_register_data():
    return jsonable_encoder({
        "username": "valid",
        "email": "validemail@gmail.com",
        "full_name":"valid user",
        "password": "test_pass",
        "confirm_password": "test_pass"
    })

@pytest.fixture
def valid_existing_user_data():
    return jsonable_encoder({
    "username": "existing_user",
    "email": "validemail@gmail.com",
    "full_name":"existing_user user",
    "password": "test_pass",
    "confirm_password": "test_pass"
    })

@pytest.fixture
def password_not_matching_register_data():
    return jsonable_encoder({
        "username": "valid",
        "email": "validemail@gmail.com",
        "full_name":"valid user",
        "password": "test_pass",
        "confirm_password": "not_matching"
    })


@pytest.fixture
def valid_login_data():
    return {
    "username": "existing_user",
    "password": "test_pass",
    }

@pytest.fixture   
def wrong_pass_login_data():
    return {
    "username": "existing_user",
    "password": "wrong_pass",
    }

@pytest.fixture   
def wrong_user_login_data():
    return jsonable_encoder({
    "username": "wrong_user",
    "password": "test_pass",
    })

@pytest.fixture
def get_bearer():
    return create_access_token(data={"sub": "existing_user"})

@pytest.fixture
def get_wrong_bearer():
    return create_access_token(data={"sub": "wrong_user"})

    

