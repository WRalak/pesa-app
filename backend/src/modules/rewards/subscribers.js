import { onDomainEvent } from '../../lib/events.js';
import { rewardTransaction, reverseTransactionRewards, registerReferral, qualifyReferral } from './service.js';

onDomainEvent('transaction.successful', async ({ transaction }) => {
  await rewardTransaction(transaction);
  await qualifyReferral(transaction);
});
onDomainEvent('transaction.reversed', async ({ transaction }) => reverseTransactionRewards(transaction));
onDomainEvent('user.activated', async ({ userId, referredBy }) => registerReferral({ userId, referredBy }));
