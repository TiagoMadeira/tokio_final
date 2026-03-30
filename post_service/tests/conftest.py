import sys;sys.path.append('.')
from app.database.config import get_session
from app.main import app
import pytest
from sqlmodel import  Session, SQLModel, create_engine, StaticPool
from app.models.post import Post
from app.dependencies import verify_token
from tests.dependencires import test_verify_token
SQLITE_URL = f"sqlite:///:memory:" #create an in memory SQLite database

test_engine = create_engine(
    SQLITE_URL,
    connect_args={
        "check_same_thread": False,
    },
    poolclass=StaticPool)

def get_test_session():
    with Session(test_engine) as session:
        yield session
        session.close()

app.dependency_overrides[get_session] = get_test_session #Override get session during tests

@pytest.fixture
def setup_database():
    SQLModel.metadata.create_all(test_engine)
    session = Session(test_engine)
    existing_post = Post(id=1, title = "existing_title", content = "valid content", author = "test_author")
    second_existing_post = Post(id=2, title = "existing_title_2", content = "valid content", author = "diferent_author")
    session.add(existing_post)
    session.add(second_existing_post)
    session.commit()
    yield
    SQLModel.metadata.drop_all(test_engine)
    print("Teardown database")

@pytest.fixture()
def skip_auth():
    app.dependency_overrides[verify_token] = test_verify_token
    yield
    app.dependency_overrides.pop(verify_token)


