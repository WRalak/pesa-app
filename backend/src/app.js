import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import compression from 'compression';
import pinoHttp from 'pino-http';
import swaggerUi from 'swagger-ui-express';
import { config } from './config/env.js';
import { logger } from './lib/logger.js';
import { requestId, sanitize } from './middleware/request-context.js';
import { errorHandler, notFoundHandler } from './middleware/error-handler.js';
import { globalLimiter } from './middleware/rate-limit.js';
import { metricsMiddleware } from './lib/metrics.js';
import { buildOpenApiDocument } from './lib/openapi.js';
import { mountRoutes } from './routes.js';

export function createApp() {
  const app = express();
  app.disable('x-powered-by');
  app.set('trust proxy', config.TRUST_PROXY);
  app.set('query parser', 'simple');

  app.use(requestId);
  app.use(pinoHttp({
    logger,
    genReqId: (req) => req.id,
    autoLogging: { ignore: (req) => req.url.startsWith('/health') },
    serializers: {
      req: (req) => ({ id: req.id, method: req.method, url: req.url.split('?')[0] }),
      res: (res) => ({ statusCode: res.statusCode }),
    },
  }));
  app.use(helmet({
    contentSecurityPolicy: { directives: { defaultSrc: ["'self'"], scriptSrc: ["'self'"], styleSrc: ["'self'", "'unsafe-inline'"], imgSrc: ["'self'", 'data:'] } },
    hsts: { maxAge: 63072000, includeSubDomains: true, preload: true },
    referrerPolicy: { policy: 'no-referrer' },
  }));
  app.use(cors({
    origin: (origin, cb) => cb(null, !origin || config.corsOrigins.includes(origin)),
    credentials: false,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    allowedHeaders: ['Authorization', 'Content-Type', 'Idempotency-Key', 'X-Request-Id', 'X-Device-Id', 'X-App-Version', 'X-Platform', 'Accept-Language'],
    exposedHeaders: ['X-Request-Id', 'Retry-After', 'Idempotent-Replayed'],
    maxAge: 600,
  }));
  app.use(compression());
  app.use(metricsMiddleware);

  // Provider callbacks need the raw body for signature verification.
  app.use('/v1/callbacks', express.json({ limit: '64kb', verify: (req, _res, buf) => { req.rawBody = buf; } }));
  app.use(express.json({ limit: '100kb' }));
  app.use(sanitize);
  app.use((req, res, next) => {
    res.setHeader('Cache-Control', 'no-store');
    next();
  });

  app.use(globalLimiter);
  mountRoutes(app);

  const doc = buildOpenApiDocument();
  app.get('/openapi.json', (_req, res) => res.json(doc));
  if (!config.isProd) {
    app.use('/docs', (_req, res, next) => {
      res.setHeader('Content-Security-Policy', "default-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; script-src 'self' 'unsafe-inline'");
      next();
    }, swaggerUi.serve, swaggerUi.setup(doc, { customSiteTitle: 'Pesa API' }));
  }

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
