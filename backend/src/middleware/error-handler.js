import { AppError } from '../lib/errors.js';
import { logger } from '../lib/logger.js';
import * as Sentry from '@sentry/node';
import { config } from '../config/env.js';

export function notFoundHandler(req, res) {
  res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Route not found', requestId: req.id } });
}

// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, _next) {
  let e = err;
  if (err?.type === 'entity.parse.failed') e = new AppError('BAD_REQUEST', 'Malformed JSON body', 400);
  else if (err?.type === 'entity.too.large') e = new AppError('PAYLOAD_TOO_LARGE', 'Request body too large', 413);
  else if (err?.name === 'CastError') e = new AppError('BAD_REQUEST', 'Invalid identifier', 400);
  else if (err?.code === 11000) e = new AppError('DUPLICATE', 'Resource already exists', 409);
  else if (err?.name === 'ValidationError' && err.errors) {
    e = new AppError('VALIDATION_ERROR', 'Validation failed', 422, Object.values(err.errors).map((x) => ({ path: x.path, message: x.message })));
  }

  if (!(e instanceof AppError)) {
    logger.error({ err, requestId: req.id, path: req.path }, 'Unhandled error');
    if (config.SENTRY_DSN) Sentry.captureException(err);
    e = new AppError('INTERNAL_ERROR', 'Something went wrong. Please try again.', 500);
  } else if (e.status >= 500) {
    logger.error({ code: e.code, requestId: req.id }, e.message);
  }

  if (e.status === 429 && e.details?.retryAfter) res.setHeader('Retry-After', String(e.details.retryAfter));
  res.status(e.status).json({ error: { code: e.code, message: e.message, details: e.details, requestId: req.id } });
}
