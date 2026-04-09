from app.main import app
from fastapi.testclient import TestClient
from fastapi.encoders import jsonable_encoder

from tests.conftest import  (skip_auth, api_client)
from tests.fixtures import (valid_register_data, 
                            valid_login_data,
                            valid_diferent_login_data,
                            valid_create_data,
                            valid_update_data,
                            wrong_pass_login_data,
                            wrong_user_login_data,
                            valid_existing_register_data,
                            password_not_matching_register_data)

# Define endpoints based on your port-forwarding or tunnel
REST_SERVICE_URL = "http://localhost:8000"
#########################################################Register Test##########################################################
def test_register_user(api_client, valid_register_data):
    #test
    response = api_client.post(f"{REST_SERVICE_URL}/register", json=jsonable_encoder(valid_register_data))
    #assert
    data = response.json()
    assert response.status_code == 200
    assert data["username"] == valid_register_data["username"]
    assert data["email"] == valid_register_data["email"]
    assert data["full_name"] == valid_register_data["full_name"]

def test_register_user_already_exists(api_client, valid_existing_register_data):
    #setup
    api_client.post(f"{REST_SERVICE_URL}/register", json=jsonable_encoder(valid_existing_register_data))
    #test
    response = api_client.post(f"{REST_SERVICE_URL}/register", json=jsonable_encoder(valid_existing_register_data))
    #assert
    assert response.status_code == 400
    assert response.json() == {
        "detail": "User has already registered"
    }

def test_register_password_not_matching(api_client, password_not_matching_register_data):
    #test
    response = api_client.post(f"{REST_SERVICE_URL}/register", json=password_not_matching_register_data)
    #assert
    assert response.status_code == 400

#########################################################Login Tests##########################################################

def test_valid_login(api_client, valid_login_data ):
    #test
    response = api_client.post(f"{REST_SERVICE_URL}/login",
                            data = valid_login_data,
                            headers = {"content-type": "application/x-www-form-urlencoded"})
    #assert
    data = response.json()
    assert response.status_code == 200
    assert not data["access_token"] == False
    assert data["token_type"] == "bearer"

def test_wrong_pass_login(api_client, wrong_pass_login_data):
    response = api_client.post(f"{REST_SERVICE_URL}/login",
                    data= wrong_pass_login_data,
                    headers = {"content-type": "application/x-www-form-urlencoded"})
    
    assert response.status_code == 401
    assert response.json() == {
        "detail": "Incorrect username or password"
    }

def test_wrong_user_login(api_client, wrong_pass_login_data):
    response = api_client.post(f"{REST_SERVICE_URL}/login",
                    data= wrong_pass_login_data,
                    headers = {"content-type": "application/x-www-form-urlencoded"})
    
    assert response.status_code == 401
    assert response.json() == {
        "detail": "Incorrect username or password"
    }

######################################################### Creat POSTS Tests##########################################################

def test_valid_create(api_client, valid_create_data, valid_login_data ):
    #test setup
    login_response = api_client.post(f"{REST_SERVICE_URL}/login",
                            data = valid_login_data,
                            headers = {"content-type": "application/x-www-form-urlencoded"})
    
    response_json = login_response.json()
    access_tokem = response_json["access_token"]
    token_type = response_json["token_type"]
    #test
    response = api_client.post(f"{REST_SERVICE_URL}/post", json=jsonable_encoder(valid_create_data), headers={"authorization": f"{token_type} {access_tokem}"})
    #assert
    data = response.json()
    assert response.status_code == 200
    assert data["title"] == valid_create_data["title"]
    assert data["content"] == valid_create_data["content"]
    assert data["author"] == valid_login_data["username"]


def test_create_post_need_auth(api_client, valid_create_data):
    #test
    response = api_client.post(f"{REST_SERVICE_URL}/post", json=jsonable_encoder(valid_create_data))
    #assert
    data = response.json()
    assert response.status_code == 401
    assert data["detail"] == "Not authenticated"


def test_create_already_existing_post(api_client, valid_create_data, valid_login_data):
    #test setup
    login_response = api_client.post(f"{REST_SERVICE_URL}/login",
                            data = valid_login_data,
                            headers = {"content-type": "application/x-www-form-urlencoded"})
    
    response_json = login_response.json()
    access_tokem = response_json["access_token"]
    token_type = response_json["token_type"]
    #test
    response = api_client.post(f"{REST_SERVICE_URL}/post", json=jsonable_encoder(valid_create_data), headers={"authorization": f"{token_type} {access_tokem}"})
    data = response.json()
    assert response.status_code == 400
    assert data["detail"] == "Post already exists"

######################################################### Update POSTS Tests##########################################################

def test_valid_update(api_client, valid_update_data, valid_login_data):
    #test setup
    login_response = api_client.post(f"{REST_SERVICE_URL}/login",
                            data = valid_login_data,
                            headers = {"content-type": "application/x-www-form-urlencoded"})
    
    response_json = login_response.json()
    access_tokem = response_json["access_token"]
    token_type = response_json["token_type"]
    #test
    response = api_client.patch(f"{REST_SERVICE_URL}/posts/1", json=jsonable_encoder(valid_update_data), headers={"authorization": f"{token_type} {access_tokem}"})
    #assert
    data = response.json()
    assert response.status_code == 200
    assert data["title"] == valid_update_data["title"]
    assert data["content"] == valid_update_data["content"]
    assert data["author"] == "existing user"

def test_update_needs_auth(api_client, valid_update_data):

    #test
    response = api_client.patch(f"{REST_SERVICE_URL}/posts/1", json=jsonable_encoder(valid_update_data))
    #assert
    data = response.json()
    assert response.status_code == 401
    assert data["detail"] == "Not authenticated"

def test_update_with_diferent_user(api_client, valid_update_data, valid_diferent_login_data):
    #test setup
    login_response = api_client.post(f"{REST_SERVICE_URL}/login",
                            data = valid_diferent_login_data,
                            headers = {"content-type": "application/x-www-form-urlencoded"})
    
    response_json = login_response.json()
    access_tokem = response_json["access_token"]
    token_type = response_json["token_type"]
    #test
    response = api_client.patch(f"{REST_SERVICE_URL}/posts/1", json=jsonable_encoder(valid_update_data), headers={"authorization": f"{token_type} {access_tokem}"})
    #assert
    data = response.json()
    assert response.status_code == 403
    assert data["detail"] == "You are not the author"

######################################################### Get POSTS Tests############################################################

def test_valid_get_posts(api_client):
    #test
    response = api_client.get(f"{REST_SERVICE_URL}/posts")
    #assert
    data = response.json()
    assert response.status_code == 200
    assert len(data) == 1
    assert "title" in data[0]
    assert "content" in data[0]
    assert "author" in data[0]
    assert "id" in data[0]

def test_valid_get_posts_by_author(api_client):
   
    client_url = "/posts/test_author"
    #test
    response = api_client.get(f"{REST_SERVICE_URL}/posts/valid_user")
    #assert
    data = response.json()
    assert response.status_code == 200
    assert len(data) == 1
    assert "title" in data[0]
    assert "content" in data[0]
    assert "author" in data[0]
    assert "id" in data[0]

def test_get_users_posts_should_require_login(api_client):
    response = api_client.get(f"{REST_SERVICE_URL}/posts/valid_user")
    data = response.json()
    assert response.status_code == 401
    assert data["detail"] == "Not authenticated"

def test_get_users_posts(api_client, valid_login_data):
    #test_setup 
    login_response = api_client.post(f"{REST_SERVICE_URL}/login",
                            data = valid_login_data,
                            headers = {"content-type": "application/x-www-form-urlencoded"})
    
    response_json = login_response.json()
    access_tokem = response_json["access_token"]
    token_type = response_json["token_type"]

    #test
    response = api_client.get(f"{REST_SERVICE_URL}/user_posts", headers={"authorization": f"{token_type} {access_tokem}"})

    #assert
    data = response.json()
    assert response.status_code == 200
    assert len(data) == 1
    assert "title" in data[0]
    assert "content" in data[0]
    assert "author" in data[0]
    assert "id" in data[0]

#########################################################Delete POSTS Tests##########################################################

def test_delete_should_require_auth(api_client ):
    response = api_client.delete(f"{REST_SERVICE_URL}/posts/1")
    data = response.json()
    assert response.status_code == 401
    assert data["detail"] == "Not authenticated"

def test_not_found_post_delete(api_client, valid_login_data):
    #test setup
    login_response = api_client.post(f"{REST_SERVICE_URL}/login",
                            data = valid_login_data,
                            headers = {"content-type": "application/x-www-form-urlencoded"})
    
    response_json = login_response.json()
    access_tokem = response_json["access_token"]
    token_type = response_json["token_type"]  
   
    #test
    response = api_client.delete(f"{REST_SERVICE_URL}/posts/999", headers={"authorization": f"{token_type} {access_tokem}"})
    data = response.json()
    #assert
    assert response.status_code == 404
    assert data["detail"] == "Post not found!"

def test_forbidden_delete(api_client, valid_diferent_login_data):
    #test setup
    login_response = api_client.post(f"{REST_SERVICE_URL}/login",
                            data = valid_diferent_login_data,
                            headers = {"content-type": "application/x-www-form-urlencoded"})
    
    response_json = login_response.json()
    access_tokem = response_json["access_token"]
    token_type = response_json["token_type"]     
   
    #test
    response = api_client.delete(f"{REST_SERVICE_URL}/posts/1", headers={"authorization": f"{token_type} {access_tokem}"})
    data = response.json()
    #assert
    assert response.status_code == 403
    assert data["detail"] == "You are not the author"

def test_valid_delete(api_client, valid_diferent_login_data):
    #test setup
    login_response = api_client.post(f"{REST_SERVICE_URL}/login",
                            data = valid_diferent_login_data,
                            headers = {"content-type": "application/x-www-form-urlencoded"})
    
    response_json = login_response.json()
    access_tokem = response_json["access_token"]
    token_type = response_json["token_type"]   
   
    #test
    response = api_client.delete(f"{REST_SERVICE_URL}/posts/1", headers={"authorization": f"{token_type} {access_tokem}"})
    data = response.json()
    #assert
    assert response.status_code == 403
    assert data["detail"] == "You are not the author"

    