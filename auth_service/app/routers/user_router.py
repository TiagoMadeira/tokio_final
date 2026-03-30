from app.exceptions import BadRequestException, NotFoundException, AuthTokenExpiredException, AuthFailedException
from fastapi import APIRouter, Depends
from fastapi.security import OAuth2PasswordRequestForm
from app.auth.auth_service import get_password_hash
from app.auth.jwt_tokens_service import verify_token, create_access_token
from jwt.exceptions import InvalidTokenError,ExpiredSignatureError
from app.models.token import Token
from app.models.user import UserRegister, User, UserPublic
from app.database.config import get_session
from typing import Annotated
from sqlmodel import  Session

SessionDep = Annotated[Session, Depends(get_session)]
router = APIRouter()

@router.post("/login")
def login_for_access_token(session: SessionDep, form_data: Annotated[OAuth2PasswordRequestForm, Depends()],) -> Token:
    user = User.authenticate_user(db=session, username=form_data.username, password=form_data.password)
    if not user:
        raise AuthFailedException(detail="Incorrect username or password")
    access_token = create_access_token(
        data={"sub": user.username})
    return Token(access_token=access_token, token_type="bearer")

@router.post("/register", response_model=UserPublic)
def register(data: UserRegister, session: SessionDep):
    user = User.find_by_username(db=session, username=data.username)
    if user:
        raise BadRequestException(detail="User has already registered")
    # hashing password
    user_data = data.dict(exclude={"confirm_password"})
    user_data["hashed_password"] = get_password_hash(user_data["password"])
    # save user to db
    user = User(**user_data)
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

@router.get("/verify", response_model = UserPublic)
def verify(token: str, session: SessionDep):
    try:
        user = verify_token(token=token, session=session)
        if user is None:
            raise NotFoundException(detail="User not found")
    except ExpiredSignatureError:
        raise AuthTokenExpiredException()
    except InvalidTokenError:
        raise AuthFailedException() 
    return user


