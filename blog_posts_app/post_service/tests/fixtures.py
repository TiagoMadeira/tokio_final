import pytest
from fastapi.encoders import jsonable_encoder

@pytest.fixture
def valid_create_data():
    return jsonable_encoder({
        "title": "valid",
        "content": "valid content",
    })

@pytest.fixture
def existing_create_data():
    return jsonable_encoder({
        "title": "existing_title",
        "content": "valid content",
    })

@pytest.fixture
def valid_update_data():
    return jsonable_encoder({
        "title": "updated_tile",
        "content": "valid content",
    })

@pytest.fixture
def valid_author():
    return"test_author"