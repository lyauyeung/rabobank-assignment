import psycopg2
from fastapi import Depends, FastAPI
# from fastapi.responses import PlainTextResponse

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy import Column, Integer, String, Numeric

app = FastAPI()
app.title="Rabobank"

SQLALCHEMY_DATABASE_URL = "postgresql://postgres:postgres@postgres:5432/postgres"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class InvalidRecords(Base):
    __tablename__ = "invalid_records"
    reference = Column(Integer)
    account_number = Column(String(256))
    description = Column(String(256))
    start_balance = Column(Numeric(8,2))
    mutation = Column(Numeric(8,2))
    end_balance = Column(Numeric(8,2))

    __mapper_args__ = {
        "primary_key": [reference, account_number]
    }

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/records/invalid")
def get_invalid_records(db:Session = Depends(get_db)):
    invalid_records = db.query(InvalidRecords).all()
    return invalid_records
