import requests
from app.config import settings
from app.schemas.auth import authRegister
from app.schemas.posts import postCreate, postUpdate
from app.utils import auth_header, handle_responses, json_header

def create_post(data :postCreate, token):
    res = requests.post("{0}/post".format(settings.POST_SERVICE_URL), data=data.model_dump_json(), headers = json_header() | auth_header(token))
    if res.status_code == 200:
        return res.json()
    
    handle_responses(res)
    
    
def delete_post(post_id :int , token):
    res = requests.delete("{0}/posts/{1}".format(settings.POST_SERVICE_URL,post_id), headers = auth_header(token) )
    if res.status_code == 200:
        return res.json()
    
    handle_responses(res)

def update_post(post_id :int, data :postUpdate, token):
    res = requests.patch("{0}/posts/{1}".format(settings.POST_SERVICE_URL,post_id), data=data.model_dump_json(), headers = json_header() | auth_header(token) )
    if res.status_code == 200:
        return res.json()
    
    handle_responses(res)
        
def get_posts():
    res = requests.patch("{0}/posts".format(settings.POST_SERVICE_URL))
    if res.status_code == 200:
        return res.json()
   
    handle_responses(res)
    
def get_posts():
    res = requests.get("{0}/posts".format(settings.POST_SERVICE_URL))
    if res.status_code == 200:
        return res.json()
   
    handle_responses(res)
    
def get_posts_by_author(author: str):
    res = requests.get("{0}/posts/{1}".format(settings.POST_SERVICE_URL, author))
    if res.status_code == 200:
        return res.json()
   
    handle_responses(res)
    
def get_users_posts(token:str):
    res = requests.get("{0}/user_posts".format(settings.POST_SERVICE_URL), headers = auth_header(token))
    if res.status_code == 200:
        return res.json()
   
    handle_responses(res)
    
