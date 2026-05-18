import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { SimpleSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { XMLHttpRequestInstrumentation } from '@opentelemetry/instrumentation-xml-http-request';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { ZoneContextManager } from '@opentelemetry/context-zone';
import {resourceFromAttributes, defaultResource} from '@opentelemetry/resources';
// Note: In 1.40.0, the import name changed to SEMRESATTRS
import { ATTR_SERVICE_NAME } from '@opentelemetry/semantic-conventions';



const exporter = new OTLPTraceExporter({
  // OTLP/HTTP default port is 4318. Ensure your ingress handles this!
  url: `${window.location.origin}/v1/traces`, 
   headers: {
    'Content-Type': 'application/json',
  },
});

const resource = defaultResource().merge(
  resourceFromAttributes({
   [ATTR_SERVICE_NAME]: 'REPLACE_VITE_OTEL_SERVICE_NAME',
  })
);

const provider = new WebTracerProvider({
  resource: resource,
  spanProcessors: [new SimpleSpanProcessor(exporter)]
});


provider.register({
  contextManager: new ZoneContextManager(),
});

// 4. Auto-instrument Axios/XHR requests
registerInstrumentations({
  instrumentations: [
    new XMLHttpRequestInstrumentation({
      propagateTraceHeaderCorsUrls: [
         new RegExp(`${window.location.origin}/.*`), // Propagates headers to your API
      ],
    }),
  ],
});