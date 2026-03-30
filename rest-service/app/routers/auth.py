from typing import Annotated

from fastapi.security import OAuth2PasswordRequestForm
from app.schemas.auth import Token, authRegister, authBaseRegister
from app.clients import auth_service
from fastapi import APIRouter, Depends

router = APIRouter()

@router.post("/register", response_model=authBaseRegister)
def register(data: authRegister):
    response = auth_service.register(data)
    return response

@router.post("/login", response_model = Token)
def login(form_data: Annotated[OAuth2PasswordRequestForm, Depends()]):
    response = auth_service.login(form_data.__dict__)
    return response
    