import client from 'prom-client';

export const registry = new client.Registry();
client.collectDefaultMetrics({ register: registry, prefix: 'pesa_' });

export const httpDuration = new client.Histogram({
  name: 'pesa_http_request_duration_seconds',
  help: 'HTTP request duration',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
  registers: [registry],
});

export const paymentCounter = new client.Counter({
  name: 'pesa_payments_total',
  help: 'Payment state transitions',
  labelNames: ['provider', 'type', 'status'],
  registers: [registry],
});

export const callbackCounter = new client.Counter({
  name: 'pesa_provider_callbacks_total',
  help: 'Provider callbacks received',
  labelNames: ['provider', 'outcome'],
  registers: [registry],
});

export function metricsMiddleware(req, res, next) {
  const end = httpDuration.startTimer();
  res.on('finish', () => {
    end({ method: req.method, route: req.route?.path ? `${req.baseUrl}${req.route.path}` : 'unmatched', status: res.statusCode });
  });
  next();
}
