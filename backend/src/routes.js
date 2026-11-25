import healthRoutes from './modules/health/routes.js';
import configRoutes from './modules/config/routes.js';
import authRoutes from './modules/auth/routes.js';
import userRoutes from './modules/users/routes.js';
import supportRoutes from './modules/support/routes.js';

/** Central route table. All public APIs are versioned under /v1. */
export function mountRoutes(app) {
  app.use(healthRoutes);
  app.use('/v1/config', configRoutes);
  app.use('/v1/auth', authRoutes);
  app.use('/v1/me', userRoutes);
  app.use('/v1/support', supportRoutes);
}
