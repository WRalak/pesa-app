import { config } from '../config/env.js';

/**
 * OpenTelemetry tracing + Sentry error monitoring. Imported first by the
 * server and worker entrypoints so auto-instrumentation can patch modules.
 */
export async function initTelemetry(serviceName) {
  if (config.SENTRY_DSN) {
    const Sentry = await import('@sentry/node');
    Sentry.init({
      dsn: config.SENTRY_DSN,
      environment: config.NODE_ENV,
      tracesSampleRate: config.isProd ? 0.05 : 0.5,
      sendDefaultPii: false,
      beforeSend(event) {
        if (event.request) {
          delete event.request.data;
          delete event.request.cookies;
          if (event.request.headers) delete event.request.headers.authorization;
        }
        return event;
      },
    });
  }
  if (config.OTEL_ENABLED) {
    const { NodeSDK } = await import('@opentelemetry/sdk-node');
    const { getNodeAutoInstrumentations } = await import('@opentelemetry/auto-instrumentations-node');
    const { OTLPTraceExporter } = await import('@opentelemetry/exporter-trace-otlp-http');
    const sdk = new NodeSDK({
      serviceName,
      traceExporter: new OTLPTraceExporter({ url: config.OTEL_EXPORTER_OTLP_ENDPOINT }),
      instrumentations: [getNodeAutoInstrumentations({ '@opentelemetry/instrumentation-fs': { enabled: false } })],
    });
    sdk.start();
    process.once('SIGTERM', () => sdk.shutdown().catch(() => {}));
  }
}
