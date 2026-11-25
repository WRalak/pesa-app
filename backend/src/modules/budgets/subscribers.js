import { onDomainEvent } from '../../lib/events.js';
import { evaluateBudgetAlerts } from './service.js';

onDomainEvent('transaction.successful', async ({ transaction }) => {
  if (transaction.direction === 'DEBIT') await evaluateBudgetAlerts(transaction.userId);
});
