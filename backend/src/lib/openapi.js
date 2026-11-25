import { OpenAPIRegistry, OpenApiGeneratorV3, extendZodWithOpenApi } from '@asteasolutions/zod-to-openapi';
import { z } from 'zod';

extendZodWithOpenApi(z);

export const registry = new OpenAPIRegistry();

registry.registerComponent('securitySchemes', 'bearerAuth', { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' });
registry.registerComponent('securitySchemes', 'adminAuth', { type: 'http', scheme: 'bearer', bearerFormat: 'JWT', description: 'Admin console token (MFA-verified)' });

export const ErrorSchema = registry.register('Error', z.object({
  error: z.object({
    code: z.string().openapi({ example: 'VALIDATION_ERROR' }),
    message: z.string(),
    details: z.any().optional(),
    requestId: z.string().optional(),
  }),
}));

export function buildOpenApiDocument() {
  const generator = new OpenApiGeneratorV3(registry.definitions);
  return generator.generateDocument({
    openapi: '3.0.3',
    info: {
      title: 'Pesa API',
      version: '1.0.0',
      description: 'Pesa fintech platform API. All monetary amounts are integer minor units (`amountMinor`) with an ISO 4217 `currency`.',
    },
    servers: [{ url: '/' }],
  });
}

export { z };
