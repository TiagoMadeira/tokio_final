from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor, SimpleSpanProcessor, ConsoleSpanExporter
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from app.config import settings

def otel_trace_init():
    
    resource = Resource(attributes = {"service.name": settings.OTEL_SERVICE_NAME})
    provider = TracerProvider(resource=resource)
    processor = BatchSpanProcessor(OTLPSpanExporter(endpoint="{0}/v1/traces".format(settings.OTEL_EXPORTER_OTLP_ENDPOINT)))
    provider.add_span_processor(processor)

    #Add console processor for debug
    if settings.DEBUG:
        provider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter()))
    #set global default tracer provider
    trace.set_tracer_provider(provider)
    
    tracer = trace.get_tracer("my.tracer.name")