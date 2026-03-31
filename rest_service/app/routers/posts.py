from typing import Annotated

from app.clients import post_service
from fastapi import APIRouter, Depends
from app.dependencies import verify_token
from app.schemas.posts import postPublic, postCreate, postUpdate

router = APIRouter()

@router.post("/post", response_model=postPublic)
def create_post(data: postCreate,token: str = Depends(verify_token)):
    response = post_service.create_post(data=data, token=token)
    return response

@router.delete("/posts/{post_id}")
def delete_post(post_id: int, token: str = Depends(verify_token)):
    response = post_service.delete_post(post_id, token)
    return response

@router.patch("/posts/{post_id}", response_model=postPublic)
def update_post( data: postUpdate, post_id: int, token: str = Depends(verify_token)):
    response = post_service.update_post(data = data, post_id=post_id, token=token)
    return response

@router.get("/posts", response_model=list[postPublic])
def get_posts( ):
    response = post_service.get_posts()
    return response

@router.get("/posts/{author}", response_model=list[postPublic])
def get_posts_by_author(author: str ):
    response = post_service.get_posts_by_author(author)
    return response

@router.get("/user_posts", response_model=list[postPublic])
def get_users_posts( token: str = Depends(verify_token)):
    response = post_service.get_users_posts(token)
    return response