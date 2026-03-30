import requests
from app.config import settings
from app.schemas.auth import authRegister
from app.utils import handle_responses, json_header

def login(data):
    form_data = {
        "username": data["username"],
        "password": data["password"]
    }
    res = requests.post("{0}/login".format(settings.AUTH_SERVICE_URL), data=form_data )
    if res.status_code == 200:
        return res.json()
    
    handle_responses(res)


def register(body: authRegister):
    res = requests.post("{0}/register".format(settings.AUTH_SERVICE_URL), data=body.model_dump_json(), headers = json_header())
    if res.status_code == 200:
        return res.json()
    
    handle_responses(res)
 
    
    