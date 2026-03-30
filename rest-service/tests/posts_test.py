import sys;sys.path.append('.')
import pytest
from app.main import app
from fastapi.testclient import TestClient
from fastapi.encoders import jsonable_encoder
from unittest.mock import patch
from app.config import settings
from app.schemas.posts import postCreate, postUpdate, postPublic

from tests.conftest import  skip_auth
from tests.fixtures import (valid_create_data, 
                            valid_create_response_data,
                            existing_create_data, 
                            post_already_exists_response,
                            valid_post_delete_response,
                            post_not_found_response,
                            forbidden_response,
                            valid_update_data,
                            valid_update_response_data,
                            valid_get_response_data,
                            mock_auth_header,
                            mock_json_header)

client = TestClient(app)


############################################create posts###############################################
@patch('app.clients.post_service.requests.post')
def test_valid_create(mock_post, skip_auth, valid_create_data, valid_create_response_data, mock_auth_header,mock_json_header ):
    #Mock setup
    mock_post.return_value.json.return_value = valid_create_response_data
    mock_post.return_value.status_code = 200
    #test
    response = client.post("/post", json=jsonable_encoder(valid_create_data))
    #assert
    data = response.json()
    client_url = "/post"
    assert response.status_code == 200
    assert data["title"] == valid_create_response_data["title"]
    assert data["content"] == valid_create_response_data["content"]
    assert data["author"] == valid_create_response_data["author"]
    assert data["id"] == valid_create_response_data["id"]
    mock_post.assert_called_once_with(settings.POST_SERVICE_URL + client_url, data=postCreate(**valid_create_data).model_dump_json(), headers=mock_auth_header|mock_json_header)


@patch('app.clients.post_service.requests.post')
def test_create_existing_post(mock_post, skip_auth, existing_create_data, post_already_exists_response, mock_auth_header,mock_json_header):
    #Mock setup
    mock_post.return_value.json.return_value = post_already_exists_response
    mock_post.return_value.status_code = 400
    client_url = "/post"
    #test
    response = client.post(client_url, json=jsonable_encoder(existing_create_data))
    #assert
    data = response.json()
    assert response.status_code == 400
    assert data["detail"] == post_already_exists_response["detail"]
    mock_post.assert_called_once_with(settings.POST_SERVICE_URL + client_url, data=postCreate(**existing_create_data).model_dump_json(), headers=mock_auth_header|mock_json_header)


def test_create_should_require_auth(valid_create_data):
    response = client.post("/post", json=valid_create_data)
    data = response.json()
    assert response.status_code == 401
    assert data["detail"] == "Not authenticated"


############################################delete posts##############################################

@patch('app.clients.post_service.requests.delete')
def test_valid_delete(mock_delete, skip_auth, valid_post_delete_response, mock_auth_header):
    #Mock setup
    mock_delete.return_value.json.return_value = valid_post_delete_response
    mock_delete.return_value.status_code = 200
    client_url = "/posts/1"
    #test
    response = client.delete(client_url)
    data = response.json()
    #assert
    assert response.status_code == 200
    assert data["success"] == valid_post_delete_response["success"]
    mock_delete.assert_called_once_with(settings.POST_SERVICE_URL + client_url, headers=mock_auth_header)


@patch('app.clients.post_service.requests.delete')
def test_not_found_post_delete(mock_delete, skip_auth, post_not_found_response, mock_auth_header):
    #Mock setup
    mock_delete.return_value.json.return_value = post_not_found_response
    mock_delete.return_value.status_code = 404
    client_url = "/posts/1"
    #test
    response = client.delete(client_url)
    data = response.json()
    #assert
    assert response.status_code == 404
    assert data["detail"] == post_not_found_response["detail"]
    mock_delete.assert_called_once_with(settings.POST_SERVICE_URL + client_url, headers=mock_auth_header)


@patch('app.clients.post_service.requests.delete')
def test_test_forbidden_delete(mock_delete, skip_auth, forbidden_response, mock_auth_header):
    #Mock setup
    mock_delete.return_value.json.return_value = forbidden_response
    mock_delete.return_value.status_code = 403
    client_url = "/posts/1"
    #test
    response = client.delete(client_url)
    data = response.json()
    #assert
    assert response.status_code == 403
    assert data["detail"] == forbidden_response["detail"]
    mock_delete.assert_called_once_with(settings.POST_SERVICE_URL + client_url, headers=mock_auth_header)

def test_delete_should_require_auth( ):
    client_url = "/posts/1"
    response = client.delete(client_url)
    data = response.json()
    assert response.status_code == 401
    assert data["detail"] == "Not authenticated"


############################################Update Posts#################################################

@patch('app.clients.post_service.requests.patch')
def test_valid_update(mock_post, skip_auth, valid_update_data, valid_update_response_data, mock_auth_header, mock_json_header):
    #Mock setup
    mock_post.return_value.json.return_value = valid_update_response_data
    mock_post.return_value.status_code = 200
    client_url = "/posts/1"
    #test
    response = client.patch(client_url, json=jsonable_encoder(valid_update_data))
    #assert
    data = response.json()
    assert response.status_code == 200
    assert data["title"] == valid_update_response_data["title"]
    assert data["content"] == valid_update_response_data["content"]
    assert data["author"] == valid_update_response_data["author"]
    assert data["id"] == valid_update_response_data["id"]
    mock_post.assert_called_once_with(settings.POST_SERVICE_URL + client_url, data=postUpdate(**valid_update_data).model_dump_json(), headers=mock_auth_header | mock_json_header)

@patch('app.clients.post_service.requests.patch')
def test_not_found_update(mock_post, skip_auth, valid_update_data, post_not_found_response, mock_auth_header, mock_json_header):
    #Mock setup
    mock_post.return_value.json.return_value = post_not_found_response
    mock_post.return_value.status_code = 404
    client_url = "/posts/1"
    #test
    response = client.patch(client_url, json=jsonable_encoder(valid_update_data))
    #assert
    data = response.json()
    assert response.status_code == 404
    assert data["detail"] == post_not_found_response["detail"]
    mock_post.assert_called_once_with(settings.POST_SERVICE_URL + client_url, data=postUpdate(**valid_update_data).model_dump_json(), headers=mock_auth_header | mock_json_header)

@patch('app.clients.post_service.requests.patch')
def test_forbidden_update(mock_post, skip_auth, valid_update_data, forbidden_response, mock_auth_header, mock_json_header):
    #Mock setup
    mock_post.return_value.json.return_value = forbidden_response
    mock_post.return_value.status_code = 403
    client_url = "/posts/1"
    #test
    response = client.patch(client_url, json=jsonable_encoder(valid_update_data))
    #assert
    data = response.json()
    assert response.status_code == 403
    assert data["detail"] == forbidden_response["detail"]
    mock_post.assert_called_once_with(settings.POST_SERVICE_URL + client_url, data=postUpdate(**valid_update_data).model_dump_json(), headers=mock_auth_header | mock_json_header)

def test_update_should_require_auth( ):
    client_url = "/posts/1"
    response = client.patch(client_url)
    data = response.json()
    assert response.status_code == 401
    assert data["detail"] == "Not authenticated"


############################################Get Posts#################################################
@patch('app.clients.post_service.requests.get')
def test_valid_get_posts(mock_get, valid_get_response_data):
    #Mock setup
    mock_get.return_value.json.return_value = valid_get_response_data
    mock_get.return_value.status_code = 200
    client_url = "/posts"
    #test
    response = client.get(client_url)
    #assert
    data = response.json()
    assert response.status_code == 200
    assert data[0]["title"] == valid_get_response_data[0]["title"]
    assert data[0]["content"] == valid_get_response_data[0]["content"]
    assert data[0]["author"] == valid_get_response_data[0]["author"]
    assert data[0]["id"] == valid_get_response_data[0]["id"]
    mock_get.assert_called_once_with(settings.POST_SERVICE_URL + client_url)

@patch('app.clients.post_service.requests.get')
def test_valid_get_posts_by_author(mock_get, valid_get_response_data):
    #Mock setup
    mock_get.return_value.json.return_value = valid_get_response_data
    mock_get.return_value.status_code = 200
    client_url = "/posts/test_author"
    #test
    response = client.get(client_url)
    #assert
    data = response.json()
    assert response.status_code == 200
    assert data[0]["title"] == valid_get_response_data[0]["title"]
    assert data[0]["content"] == valid_get_response_data[0]["content"]
    assert data[0]["author"] == valid_get_response_data[0]["author"]
    assert data[0]["id"] == valid_get_response_data[0]["id"]
    mock_get.assert_called_once_with(settings.POST_SERVICE_URL + client_url)

@patch('app.clients.post_service.requests.get')
def test_valid_get_users_posts(mock_get, skip_auth, valid_get_response_data, mock_auth_header):
    #Mock setup
    mock_get.return_value.json.return_value = valid_get_response_data
    mock_get.return_value.status_code = 200
    client_url = "/user_posts"
    #test
    response = client.get("/user_posts")
    #assert
    data = response.json()
    assert response.status_code == 200
    assert data[0]["title"] == valid_get_response_data[0]["title"]
    assert data[0]["content"] == valid_get_response_data[0]["content"]
    assert data[0]["author"] == valid_get_response_data[0]["author"]
    assert data[0]["id"] == valid_get_response_data[0]["id"]
    mock_get.assert_called_once_with(settings.POST_SERVICE_URL + client_url, headers=mock_auth_header)


def test_get_users_posts_should_require_login():
    client_url = "/user_posts"
    response = client.get(client_url)
    data = response.json()
    assert response.status_code == 401
    assert data["detail"] == "Not authenticated"

