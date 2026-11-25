import 'dotenv/config';
import { z } from 'zod';

/**
 * Centralised, validated configuration. Every secret comes from the environment
 * (injected by AWS Secrets Manager / SSM in deployed environments). The process
 * refuses to start in production with weak or missing secrets.
 */
const bool = z
  .union([z.boolean(), z.string()])
  .transform((v) => v === true || v === 'true' || v === '1');

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'staging', 'production']).default('development'),
  APP_NAME: z.string().default('Pesa'),
  PORT: z.coerce.number().int().default(4000),
  PUBLIC_BASE_URL: z.string().url().default('http://localhost:4000'),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
  TRUST_PROXY: z.coerce.number().int().default(1),

  MONGODB_URI: z.string().default('mongodb://localhost:27017/pesa?replicaSet=rs0'),
  MONGODB_MAX_POOL: z.coerce.number().int().default(50),
  REDIS_URL: z.string().default('redis://localhost:6379'),

  CORS_ORIGINS: z.string().default('http://localhost:5173'),

  JWT_ACCESS_SECRET: z.string().min(32).default('dev-access-secret-change-me-0123456789abcdef'),
  JWT_ADMIN_SECRET: z.string().min(32).default('dev-admin-secret-change-me-0123456789abcdef'),
  JWT_ISSUER: z.string().default('pesa-api'),
  ACCESS_TOKEN_TTL_SECONDS: z.coerce.number().int().default(900),
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().default(30),
  ADMIN_TOKEN_TTL_SECONDS: z.coerce.number().int().default(1800),

  /** HMAC pepper for OTPs, refresh tokens and lookup hashes. */
  HASH_PEPPER: z.string().min(32).default('dev-pepper-change-me-0123456789abcdefghij'),
  /** 32-byte base64 key for AES-256-GCM field encryption (KYC numbers, TOTP secrets). */
  FIELD_ENCRYPTION_KEY: z
    .string()
    .default('ZGV2LWZpZWxkLWtleS1jaGFuZ2UtbWUtMzJieXRlcyE='),

  DEFAULT_COUNTRY: z.string().length(2).default('KE'),
  ENABLED_COUNTRIES: z.string().default('KE'),

  OTP_TTL_SECONDS: z.coerce.number().int().default(300),
  OTP_MAX_ATTEMPTS: z.coerce.number().int().default(5),
  LOGIN_MAX_FAILURES: z.coerce.number().int().default(5),
  LOGIN_LOCK_MINUTES: z.coerce.number().int().default(15),
  PIN_MAX_FAILURES: z.coerce.number().int().default(3),
  PIN_LOCK_MINUTES: z.coerce.number().int().default(30),

  /** Development-only conveniences. Rejected in staging/production. */
  DEV_OTP_OUTBOX: bool.default(false),
  PAYMENT_PROVIDERS: z.string().default('mock'),
  DEFAULT_PAYMENT_PROVIDER: z.string().default('mock'),
  MOCK_PROVIDER_WEBHOOK_SECRET: z.string().default('dev-mock-webhook-secret-0123456789'),

  DARAJA_ENV: z.enum(['sandbox', 'production']).default('sandbox'),
  DARAJA_CONSUMER_KEY: z.string().optional(),
  DARAJA_CONSUMER_SECRET: z.string().optional(),
  DARAJA_SHORTCODE: z.string().optional(),
  DARAJA_PASSKEY: z.string().optional(),
  /** Random path segment appended to callback URLs (Daraja does not sign callbacks). */
  DARAJA_CALLBACK_TOKEN: z.string().optional(),
  DARAJA_ALLOWED_IPS: z.string().default(''),

  SMS_PROVIDER: z.enum(['console', 'africastalking']).default('console'),
  AFRICASTALKING_USERNAME: z.string().optional(),
  AFRICASTALKING_API_KEY: z.string().optional(),
  EMAIL_PROVIDER: z.enum(['console', 'ses']).default('console'),
  FCM_ENABLED: bool.default(false),
  FCM_SERVICE_ACCOUNT_JSON: z.string().optional(),

  S3_ENDPOINT: z.string().optional(),
  S3_BUCKET: z.string().default('pesa-uploads'),
  S3_REGION: z.string().default('af-south-1'),

  AI_EXTERNAL_PROVIDER: z.enum(['none', 'anthropic']).default('none'),
  AI_API_KEY: z.string().optional(),

  SENTRY_DSN: z.string().optional(),
  OTEL_ENABLED: bool.default(false),
  OTEL_EXPORTER_OTLP_ENDPOINT: z.string().optional(),
  METRICS_TOKEN: z.string().optional(),

  JOBS_INLINE: bool.default(false),
  SEED_ADMIN_EMAIL: z.string().email().optional(),
  SEED_ADMIN_PASSWORD: z.string().optional(),
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  // eslint-disable-next-line no-console
  console.error('Invalid environment configuration', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

const env = parsed.data;

const isDeployed = env.NODE_ENV === 'production' || env.NODE_ENV === 'staging';
if (isDeployed) {
  const problems = [];
  for (const k of ['JWT_ACCESS_SECRET', 'JWT_ADMIN_SECRET', 'HASH_PEPPER', 'FIELD_ENCRYPTION_KEY', 'MOCK_PROVIDER_WEBHOOK_SECRET']) {
    if (String(env[k]).startsWith('dev-') || env[k] === schema.shape[k]?._def?.defaultValue?.()) problems.push(`${k} uses a development default`);
  }
  if (env.DEV_OTP_OUTBOX) problems.push('DEV_OTP_OUTBOX must be disabled');
  if (env.NODE_ENV === 'production' && env.PAYMENT_PROVIDERS.split(',').includes('mock')) {
    problems.push('mock payment provider cannot be enabled in production');
  }
  if (problems.length) {
    // eslint-disable-next-line no-console
    console.error('Refusing to start:', problems);
    process.exit(1);
  }
}

export const config = Object.freeze({
  ...env,
  isProd: env.NODE_ENV === 'production',
  isTest: env.NODE_ENV === 'test',
  isDev: env.NODE_ENV === 'development',
  isDeployed,
  corsOrigins: env.CORS_ORIGINS.split(',').map((s) => s.trim()).filter(Boolean),
  enabledCountries: env.ENABLED_COUNTRIES.split(',').map((s) => s.trim().toUpperCase()),
  paymentProviders: env.PAYMENT_PROVIDERS.split(',').map((s) => s.trim()).filter(Boolean),
  darajaAllowedIps: env.DARAJA_ALLOWED_IPS.split(',').map((s) => s.trim()).filter(Boolean),
});
