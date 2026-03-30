from typing import Annotated

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from app.database.config import create_db_and_tables
from app.routers import user_router
from app.config import settings
from app.utils import otel_trace_init
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

app = FastAPI()
app.include_router(user_router.router)

if settings.ENABLE_MONOTORING:
    #Init otel tracel
    otel_trace_init()
    #Instrument the requests module
    RequestsInstrumentor().instrument()
    FastAPIInstrumentor().instrument_app(app)

@app.on_event("startup")
def on_startup():
    create_db_and_tables()

@app.get('/healthz')
def healthz():
    return JSONResponse( status_code=200 ,content = {"message": "Everything okay"})