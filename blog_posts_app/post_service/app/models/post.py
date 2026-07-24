from sqlmodel import Field, Session, SQLModel, select
from pydantic import validator

class PostBase(SQLModel):
    title: str
    content: str 

class Post(PostBase, table=True):
    id: int | None = Field(default=None, primary_key=True)
    author: str 

    @classmethod
    def find_by_title(cls, db: Session, author: str, title: str ):
        statement = select(cls).where(cls.title == title and cls.author == author )
        result = db.exec(statement=statement)
        return result.all()
    
    @classmethod
    def get_posts_by_author(cls, db: Session, author: str):
        statement = select(cls).where(cls.author == author )
        result = db.exec(statement=statement)
        return result.all()
    
    @classmethod
    def find_by_id(cls, db: Session, id: int):
        statement = select(cls).where(cls.id == id )
        result = db.exec(statement=statement)
        return result.first()
    
    @classmethod
    def get_all(cls, db: Session):
        statement = select(cls)
        result = db.exec(statement=statement)
        return result.all()
    
    
class PostCreate(PostBase):
    pass

class PostPublic(Post):
    pass

class PostUpdate(PostBase):
    pass