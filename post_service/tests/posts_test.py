import sys;sys.path.append('.')
from app.main import app
from tests.conftest import setup_database, skip_auth
from fastapi.testclient import TestClient
from tests.fixtures import (valid_create_data, 
                            existing_create_data,
                            valid_update_data,
                            valid_author)
from app.dependencies import verify_token

client = TestClient(app)

############################################create posts###############################################

def test_valid_create(setup_database, skip_auth, valid_create_data):
    response = client.post("/post", json=valid_create_data)
    data = response.json()
    assert response.status_code == 200
    assert data["title"] == valid_create_data["title"]
    assert data["content"] == valid_create_data["content"]
    assert data["author"] == "test_author"
    assert data["id"]

def test_create_existing_post(setup_database, skip_auth, existing_create_data):
    response = client.post("/post", json=existing_create_data)
    data = response.json()
    assert response.status_code == 400
    assert data["detail"] == "Author cannot create posts with the same title"


def test_create_should_require_auth(setup_database, valid_create_data):
    response = client.post("/post", json=valid_create_data)
    data = response.json()
    assert response.status_code == 401
    assert data["detail"] == "Not authenticated"

############################################delete posts###############################################

def test_delete_existing_post(setup_database, skip_auth):
    response = client.delete("/posts/1")
    
    assert response.status_code == 200
    assert response.json() == {"success":"Post deleted!"}

def test_delete_diferent_user_post(setup_database, skip_auth):
    response = client.delete("/posts/2")
    data = response.json()
    assert response.status_code == 403
    assert data["detail"] == "You are not the author!"

def test_delete_non_existent_post(setup_database, skip_auth):
    response = client.delete("/posts/900")
    data = response.json()
    assert response.status_code == 404
    assert data["detail"] == "Post not found!"

def test_delete_should_require_auth(setup_database):
    response = client.delete("/posts/1")
    
    data = response.json()
    assert response.status_code == 401
    assert data["detail"] == "Not authenticated"

############################################update posts###############################################

def test_valid_update_post(setup_database, skip_auth, valid_update_data):
    response = client.patch("/posts/1", json=valid_update_data)

    data = response.json()
    assert response.status_code == 200
    assert data["title"] == valid_update_data["title"]
    assert data["content"] == valid_update_data["content"]
    assert data["author"] == "test_author"
    assert data["id"]

def test_update_diferent_user_post(setup_database, skip_auth, valid_update_data):
    response = client.patch("/posts/2", json=valid_update_data)

    data = response.json()
    assert response.status_code == 403
    assert data["detail"] == "You are not the author!"

def test_delete_non_existent_post(setup_database, skip_auth, valid_update_data):
    response = client.patch("/posts/900", json=valid_update_data)

    data = response.json()
    assert response.status_code == 404
    assert data["detail"] == "Post not found!"

def test_delete_should_require_auth(setup_database,valid_update_data):
    response = client.patch("/posts/1", json=valid_update_data)
    
    data = response.json()
    assert response.status_code == 401
    assert data["detail"] == "Not authenticated"

############################################get users posts##################################################

def test_get_users_post(setup_database, skip_auth):
    response = client.get("/user_posts/")

    data = response.json()
    assert response.status_code == 200
    assert len(data) == 1
    assert data[0]["title"] == "existing_title"
    assert data[0]["content"] == "valid content"

def test_get_users_post_should_require_auth(setup_database):
    response = client.get("/user_posts/")

    data = response.json()
    assert response.status_code == 401
    assert data["detail"] == "Not authenticated"


#########################################get posts########################################

def test_get_author_post(setup_database, valid_author):
    response = client.get("/posts/" + valid_author)

    data = response.json()
    assert response.status_code == 200
    assert len(data) == 1

def test_get_all_post(setup_database):
    response = client.get("/posts")

    data = response.json()
    assert response.status_code == 200
    assert len(data) == 2

