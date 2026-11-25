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
import savingsRoutes from './modules/savings/routes.js';
import budgetRoutes from './modules/budgets/routes.js';
import analyticsRoutes from './modules/analytics/routes.js';
import insightsRoutes from './modules/insights/routes.js';
import dashboardRoutes from './modules/dashboard/routes.js';
import cardRoutes, { issuerWebhook } from './modules/cards/routes.js';
import rewardRoutes from './modules/rewards/routes.js';
import adminAuthRoutes from './modules/admin/auth.js';
import adminRoutes from './modules/admin/routes.js';

/** Central route table. All public APIs are versioned under /v1. */
export function mountRoutes(app) {
  app.use(healthRoutes);
  app.use('/v1/config', configRoutes);
  app.use('/v1/auth', authRoutes);
  app.use('/v1/me', userRoutes);
  app.use('/v1/support', supportRoutes);
  app.use('/v1/payments', paymentRoutes);
  app.use('/v1/callbacks', callbackRoutes);
  app.use('/v1/callbacks', issuerWebhook);
  app.use('/v1/transactions', transactionRoutes);
  app.use('/v1/notifications', notificationRoutes);
  app.use('/v1/accounts', accountRoutes);
  app.use('/v1/savings', savingsRoutes);
  app.use('/v1/budgets', budgetRoutes);
  app.use('/v1/analytics', analyticsRoutes);
  app.use('/v1/insights', insightsRoutes);
  app.use('/v1/dashboard', dashboardRoutes);
  app.use('/v1/cards', cardRoutes);
  app.use('/v1/rewards', rewardRoutes);
  // Admin API: separate audience, separate JWT secret, MFA-only tokens.
  app.use('/admin/v1/auth', adminAuthRoutes);
  app.use('/admin/v1', adminRoutes);
}
