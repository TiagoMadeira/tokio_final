import requests
import re
from urllib.parse import quote, urljoin
from app.exceptions import BadRequestException
from app.config import settings
from app.schemas.auth import authRegister
from app.schemas.posts import postCreate, postUpdate
from app.utils import auth_header, handle_responses, json_header

POSTS_BASE_URL = "{0}/posts".format(settings.POST_SERVICE_URL)

def create_post(data :postCreate, token):
    res = requests.post("{0}/post".format(settings.POST_SERVICE_URL), data=data.model_dump_json(), headers = json_header() | auth_header(token))
    if res.status_code == 200:
        return res.json()
    
    handle_responses(res)
    
    
def delete_post(post_id :int , token):
    res = requests.delete(POSTS_BASE_URL + "/{0}".format(post_id) , headers = auth_header(token) )
    if res.status_code == 200:
        return res.json()
    
    handle_responses(res)

def update_post(post_id :int, data :postUpdate, token):
    res = requests.patch(POSTS_BASE_URL + "/{0}".format(post_id) , data=data.model_dump_json(), headers = json_header() | auth_header(token) )
    if res.status_code == 200:
        return res.json()
    
    handle_responses(res)
        
def get_posts():
    res = requests.patch(POSTS_BASE_URL)
    if res.status_code == 200:
        return res.json()
   
    handle_responses(res)
    
def get_posts():
    res = requests.get(POSTS_BASE_URL)
    if res.status_code == 200:
        return res.json()
   
    handle_responses(res)
    
def get_posts_by_author(author: str):

    if not re.match(r"^[a-zA-Z0-9\-\_]+$", author):
        raise BadRequestException(detail="Only alfanumeric characters allowed for author name")

    res = requests.get(POSTS_BASE_URL + "/{0}".format(author))
    if res.status_code == 200:
        return res.json()
   
    handle_responses(res)
    
def get_users_posts(token:str):
    res = requests.get("{0}/user_posts".format(settings.POST_SERVICE_URL), headers = auth_header(token))
    if res.status_code == 200:
        return res.json()
   
    handle_responses(res)
    
