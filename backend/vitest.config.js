import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    globalSetup: ['./tests/global-setup.js'],
    setupFiles: ['./tests/setup.js'],
    fileParallelism: false,
    testTimeout: 30_000,
    hookTimeout: 120_000,
    env: {
      NODE_ENV: 'test',
      JOBS_INLINE: 'true',
      LOG_LEVEL: 'silent',
      PAYMENT_PROVIDERS: 'mock',
      ENABLED_COUNTRIES: 'KE,UG',
      PAYMENT_RATE_LIMIT_PER_MIN: '1000',
      RISK_VELOCITY_WARN: '500',
      RISK_VELOCITY_BLOCK: '1000',
    },
    coverage: { provider: 'v8', include: ['src/**'], reporter: ['text-summary', 'lcov'] },
  },
});
