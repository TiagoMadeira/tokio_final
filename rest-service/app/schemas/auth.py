from pydantic import BaseModel
##########################################Base############################
class auth(BaseModel):
    username: str

#########################################Register##############################

class authBaseRegister(auth):
    email: str 
    full_name: str

class authRegister(authBaseRegister):
    password: str
    confirm_password: str

########################################Login##########################
class authLogin(auth):
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class  authResponse(auth):
    comfirm_password:str