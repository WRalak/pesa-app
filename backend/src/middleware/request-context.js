import crypto from 'node:crypto';

/** Assigns a correlation id (honouring a well-formed inbound X-Request-Id). */
export function requestId(req, res, next) {
  const inbound = req.get('x-request-id');
  req.id = inbound && /^[\w-]{8,64}$/.test(inbound) ? inbound : crypto.randomUUID();
  res.setHeader('X-Request-Id', req.id);
  next();
}

/** Remove keys starting with `$` or containing `.` to block NoSQL operator injection. */
export function sanitize(req, _res, next) {
  const clean = (obj, depth = 0) => {
    if (!obj || typeof obj !== 'object' || depth > 10) return;
    for (const key of Object.keys(obj)) {
      if (key.startsWith('$') || key.includes('.') || key === '__proto__' || key === 'constructor' || key === 'prototype') {
        delete obj[key];
      } else {
        clean(obj[key], depth + 1);
      }
    }
  };
  clean(req.body);
  clean(req.params);
  // req.query is a getter in Express 5; sanitise the parsed object in place.
  clean(req.query);
  next();
}

export function clientInfo(req) {
  return {
    ip: req.ip,
    userAgent: req.get('user-agent')?.slice(0, 300),
    deviceId: req.get('x-device-id')?.slice(0, 128),
    appVersion: req.get('x-app-version')?.slice(0, 32),
    platform: req.get('x-platform')?.slice(0, 16),
  };
}
