
from typing import Annotated
from fastapi import Depends
from app.exceptions import AuthFailedException
from app.config import settings
import requests
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def verify_token(bearer_token: Annotated[str, Depends(oauth2_scheme)]):
    res = requests.get("{0}/verify?token={1}".format(settings.AUTH_SERVICE_URL, bearer_token))

    if res.status_code != 200:
        raise AuthFailedException(detail="Token missing or invalid")
    
    return res.json()["full_name"]