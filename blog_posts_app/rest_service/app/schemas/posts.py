from pydantic import BaseModel
##########################################Base############################
class PostBase(BaseModel):
    title: str
    content: str 

class postCreate(PostBase):
    pass

class postPublic(PostBase):
    id: int
    author: str

class postUpdate(PostBase):
    pass