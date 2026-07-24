import sys;sys.path.append('.')
from app.auth.auth_service import get_password_hash
from app.models.user import User
from app.database.config import get_session
from app.main import app
import pytest
from sqlmodel import  Session, SQLModel, create_engine, StaticPool

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
    existing_user = User(username = "existing_user", email = "existing@email.com", full_name = "existing_user user", hashed_password=get_password_hash("test_pass"))
    session.add(existing_user)
    session.commit()
    yield
    SQLModel.metadata.drop_all(test_engine)
    print("Teardown database")