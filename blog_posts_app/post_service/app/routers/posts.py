from typing import Annotated
from app.exceptions import BadRequestException, ForbiddenException, NotFoundException
from fastapi import APIRouter, Depends
from app.database.config import get_session
from app.models.post import Post, PostCreate, PostPublic, PostUpdate
from app.dependencies import verify_token
from sqlmodel import  Session
from fastapi.responses import JSONResponse

SessionDep = Annotated[Session, Depends(get_session)]
router = APIRouter()
#######################################Create Post######################################
@router.post("/post",response_model=PostPublic)
def create_post(session: SessionDep, data: PostCreate, user: str = Depends(verify_token)):
    posts=Post.find_by_title(db=session, author=user,title=data.title)
    if posts:
        raise BadRequestException(detail="Author cannot create posts with the same title")

    post_data = data.dict()
    post_data["author"] = user 
    post = Post(**post_data)
    session.add(post)
    session.commit()
    session.refresh(post)
    return post

#######################################Get Posts######################################
@router.get("/user_posts", response_model=list[PostPublic]) 
def get_user_posts(session: SessionDep, user: str = Depends(verify_token)):
    posts = Post.get_posts_by_author(db=session, author=user)
    return posts

@router.get("/posts/{author}")
def get_author_posts(session: SessionDep, author: str ):
    posts = Post.get_posts_by_author(db=session, author=author)
    return posts

@router.get("/posts")
def get_posts(session: SessionDep ):
    posts = Post.get_all(db=session)
    return posts

#######################################Delete Posts######################################
@router.delete("/posts/{post_id}")
def delete_post(session: SessionDep, post_id: int, user: str = Depends(verify_token)):
    post = Post.find_by_id(db=session, id=post_id)
    if not post:
        raise NotFoundException(detail="Post not found!")
    
    if post.author != user:
        raise ForbiddenException(detail="You are not the author!")
    
    session.delete(post)
    session.commit()
    
    return JSONResponse(status_code=200, content= {"success":"Post deleted!"})


#######################################Update Posts######################################
@router.patch("/posts/{post_id}", response_model=PostPublic)
def update_post(session: SessionDep, data: PostUpdate, post_id: int, user: str = Depends(verify_token)):

    post = Post.find_by_id(db=session, id=post_id)
    if not post:
        raise NotFoundException(detail = "Post not found!")
    
    if post.author != user:
        raise ForbiddenException(detail="You are not the author!")
    
    post.sqlmodel_update(data)
    session.add(post)
    session.commit()
    session.refresh(post)
    
    return post