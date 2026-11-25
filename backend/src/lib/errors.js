/** Application error with a stable machine-readable code and HTTP status. */
export class AppError extends Error {
  constructor(code, message, status = 400, details) {
    super(message);
    this.name = 'AppError';
    this.code = code;
    this.status = status;
    this.details = details;
  }
}

export const Errors = {
  badRequest: (msg = 'Bad request', details) => new AppError('BAD_REQUEST', msg, 400, details),
  validation: (details) => new AppError('VALIDATION_ERROR', 'Request validation failed', 422, details),
  unauthorized: (msg = 'Authentication required', code = 'UNAUTHORIZED') => new AppError(code, msg, 401),
  forbidden: (msg = 'You do not have permission to perform this action') => new AppError('FORBIDDEN', msg, 403),
  notFound: (what = 'Resource') => new AppError('NOT_FOUND', `${what} not found`, 404),
  conflict: (msg, code = 'CONFLICT') => new AppError(code, msg, 409),
  locked: (msg, details) => new AppError('LOCKED', msg, 423, details),
  tooMany: (msg = 'Too many requests', retryAfter) => new AppError('RATE_LIMITED', msg, 429, { retryAfter }),
  unprocessable: (code, msg, details) => new AppError(code, msg, 422, details),
  provider: (msg = 'Payment provider unavailable') => new AppError('PROVIDER_ERROR', msg, 502),
};
