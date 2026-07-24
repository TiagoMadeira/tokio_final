from datetime import datetime, timedelta, timezone
from app.models.token import Token
from app.models.user import User
from sqlmodel import Session
from app.config import settings
import jwt


def create_access_token(data: dict):
    expires_delta = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def verify_token(token: Token, session: Session):
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    username = payload.get("sub")
    return User.find_by_username(db=session, username=username)
    