import { Router } from 'express';
import { z, registry, ErrorSchema } from './openapi.js';
import { Errors } from './errors.js';

/**
 * Declarative route helper. A single definition wires:
 *   - zod validation of params/query/body (unknown body keys rejected)
 *   - middleware (auth, permissions, rate limits, idempotency)
 *   - the OpenAPI document served at /docs
 */
export function createRouter({ prefix, tags, security }) {
  const router = Router();
  const api = {
    router,
    route(def) {
      const { method, path, summary, description, body, query, params, response, status = 200, middleware = [], handler, auth = security } = def;
      const openPath = (prefix + path).replace(/:(\w+)/g, '{$1}');
      registry.registerPath({
        method,
        path: openPath,
        summary,
        description,
        tags: def.tags ?? tags,
        security: auth ? [{ [auth]: [] }] : [],
        request: {
          params: params,
          query: query,
          body: body ? { content: { 'application/json': { schema: body } } } : undefined,
          headers: def.idempotent ? z.object({ 'idempotency-key': z.string().min(8).max(128) }) : undefined,
        },
        responses: {
          [status]: { description: 'Success', content: response ? { 'application/json': { schema: response } } : undefined },
          default: { description: 'Error', content: { 'application/json': { schema: ErrorSchema } } },
        },
      });
      router[method](path, ...middleware, validate({ body, query, params }), async (req, res) => {
        const result = await handler(req, res);
        if (res.headersSent) return;
        if (result === undefined) return res.status(204).end();
        res.status(status).json(result);
      });
      return api;
    },
  };
  return api;
}

export function validate({ body, query, params }) {
  return (req, _res, next) => {
    const issues = [];
    const run = (schema, key) => {
      if (!schema) return;
      const s = key === 'body' && schema instanceof z.ZodObject ? schema.strict() : schema;
      const r = s.safeParse(req[key] ?? {});
      if (r.success) {
        // Express 5 exposes req.query via a getter; store parsed values separately.
        req.valid = req.valid ?? {};
        req.valid[key] = r.data;
        if (key === 'body') req.body = r.data;
      } else {
        for (const i of r.error.issues) issues.push({ in: key, path: i.path.join('.'), message: i.message });
      }
    };
    run(params, 'params');
    run(query, 'query');
    run(body, 'body');
    if (issues.length) return next(Errors.validation(issues));
    next();
  };
}

// Reusable schema fragments
export const objectId = z.string().regex(/^[a-f\d]{24}$/i, 'Invalid id');
export const idParams = z.object({ id: objectId });
export const pageQuery = z.object({
  cursor: z.string().max(200).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});
export const amountString = z.string().regex(/^\d{1,15}(\.\d{1,4})?$/, 'Amount must be a positive decimal string').openapi({ example: '1500.00' });
