import healthRoutes from './modules/health/routes.js';
import configRoutes from './modules/config/routes.js';
import authRoutes from './modules/auth/routes.js';
import userRoutes from './modules/users/routes.js';
import supportRoutes from './modules/support/routes.js';
import paymentRoutes from './modules/payments/routes.js';
import callbackRoutes from './modules/payments/callback.routes.js';
import transactionRoutes from './modules/transactions/routes.js';
import notificationRoutes from './modules/notifications/routes.js';
import accountRoutes from './modules/accounts/routes.js';

/** Central route table. All public APIs are versioned under /v1. */
export function mountRoutes(app) {
  app.use(healthRoutes);
  app.use('/v1/config', configRoutes);
  app.use('/v1/auth', authRoutes);
  app.use('/v1/me', userRoutes);
  app.use('/v1/support', supportRoutes);
  app.use('/v1/payments', paymentRoutes);
  app.use('/v1/callbacks', callbackRoutes);
  app.use('/v1/transactions', transactionRoutes);
  app.use('/v1/notifications', notificationRoutes);
  app.use('/v1/accounts', accountRoutes);
}
