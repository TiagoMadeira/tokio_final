from sqlmodel import Field, Session, SQLModel, select
from pydantic import validator
from app.auth.auth_service import verify_password

class Userbase(SQLModel):
    username: str
    email: str | None = None
    full_name: str | None = None

class UserInDB(Userbase):
    hashed_password: str
    disabled: bool | None = None

class User(UserInDB, table=True):
    id: int | None = Field(default=None, primary_key=True)

    @classmethod
    def find_by_email(cls, db: Session, email: str):
        statement = select(cls).where(cls.email == email)
        result = db.execute(statement=statement)
        return result.scalars().first()
    
    @classmethod
    def find_by_username(cls, db: Session, username: str):
        statement = select(cls).where(cls.username == username)
        result = db.execute(statement=statement)
        return result.scalars().first()
    
    @classmethod
    def authenticate_user(cls, db: Session, username: str, password: str):
        user = cls.find_by_username(db=db, username=username)    
        if not user or not verify_password(password, user.hashed_password):
            return False
        return user

class UserRegister(Userbase):
    password: str
    confirm_password: str

    @validator("confirm_password")
    def verify_password_match(cls, v, values, **kwargs):
        password = values.get("password")

        if v != password:
            raise ValueError("The two passwords did not match.")

        return v   
    
class UserPublic(Userbase):
    pass
    


