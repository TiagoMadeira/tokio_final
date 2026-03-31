from fastapi import FastAPI
from fastapi.responses import JSONResponse
from app.routers import auth, posts
from app.config import settings
from app.utils import otel_trace_init
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

app = FastAPI()
app.include_router(auth.router)
app.include_router(posts.router)

if settings.ENABLE_MONOTORING:
    #Init otel tracel
    otel_trace_init()
    #Instrument the requests module
    RequestsInstrumentor().instrument()
    FastAPIInstrumentor().instrument_app(app)

@app.get('/healthz')
def healthz():
    return JSONResponse( status_code=200 ,content = {"message": "Everything okay"})