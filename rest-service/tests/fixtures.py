import pytest
from fastapi.encoders import jsonable_encoder
########auth############
@pytest.fixture
def mock_auth_header():
    return {
        "Authorization": "bearer test_token"
    }

@pytest.fixture
def mock_json_header():
    return {'content-type': 'application/json'}

#########input data##############

@pytest.fixture
def valid_login_data():
    return {
    "username": "existing_user",
    "password": "test_pass",
    }

@pytest.fixture
def valid_register_data():
    return {
        "username": "valid",
        "email": "validemail@gmail.com",
        "full_name":"valid user",
        "password": "test_pass",
        "confirm_password": "test_pass"
    }

@pytest.fixture
def valid_create_data():
    return {
        "title": "valid",
        "content": "valid content",
    }


@pytest.fixture
def existing_create_data():
    return {
        "title": "existing_title",
        "content": "valid content",
    }

@pytest.fixture
def valid_update_data():
    return {
        "title": "valid",
        "content": "valid content",
    }

########Responses#################

@pytest.fixture
def valid_login_response_data():
    return jsonable_encoder({
        "token_type": "bearer",
        "access_token": "test_token",
    })

@pytest.fixture
def valid_register_response_data():
    return jsonable_encoder({
        "username": "valid",
        "email": "validemail@gmail.com",
        "full_name": "valid user",
    })

@pytest.fixture
def valid_create_response_data():
    return jsonable_encoder({
        "title": "valid",
        "content": "valid content",
        "author": "test",
        "id": 1
    })

@pytest.fixture
def post_already_exists_response():
    return jsonable_encoder({
        "detail": "Post already exists"
    })


@pytest.fixture
def valid_post_delete_response():
    return jsonable_encoder({
        "success":"Post deleted!"
    })

@pytest.fixture
def post_not_found_response():
    return jsonable_encoder({
        "detail":"Post not found!"
    })

@pytest.fixture
def forbidden_response():
    return jsonable_encoder({
        "detail":"You are not the author"
    })

@pytest.fixture
def valid_update_response_data():
    return jsonable_encoder({
        "title": "valid",
        "content": "valid content",
        "author": "test",
        "id": 1
    })

@pytest.fixture
def valid_get_response_data():
    return jsonable_encoder([{
        "title": "valid",
        "content": "valid content",
        "author": "test",
        "id": 1
    }])




