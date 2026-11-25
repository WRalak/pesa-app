import { onDomainEvent } from '../../lib/events.js';
import { notify } from '../notifications/service.js';
import { fromMinor } from '../../lib/money.js';

const fmt = (t) => `${t.currency} ${Number(fromMinor(t.amountMinor, t.currency)).toLocaleString('en-KE', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`;
const who = (t) => t.counterparty?.name ?? t.counterparty?.phone ?? t.counterparty?.shortcode ?? '';

onDomainEvent('transaction.successful', async ({ transaction: t }) => {
  await notify(t.userId, {
    category: 'PAYMENT',
    type: 'PAYMENT_SUCCESSFUL',
    title: t.direction === 'CREDIT' ? 'Money added' : 'Payment successful',
    body: t.direction === 'CREDIT' ? `${fmt(t)} was added. Ref ${t.externalRef ?? t.reference}.` : `${fmt(t)} paid${who(t) ? ` to ${who(t)}` : ''}. Ref ${t.externalRef ?? t.reference}.`,
    data: { route: `/activity/${t._id}`, transactionId: String(t._id) },
  });
});

onDomainEvent('transaction.failed', async ({ transaction: t }) => {
  await notify(t.userId, {
    category: 'PAYMENT',
    type: 'PAYMENT_FAILED',
    title: 'Payment failed',
    body: `Your payment of ${fmt(t)} did not go through${t.statusReason ? `: ${t.statusReason}` : ''}. If money left your account, contact support with ref ${t.reference}.`,
    data: { route: `/activity/${t._id}`, transactionId: String(t._id) },
  });
});

onDomainEvent('transaction.reversed', async ({ transaction: t }) => {
  await notify(t.userId, {
    category: 'PAYMENT',
    type: 'PAYMENT_REVERSED',
    title: 'Payment reversed',
    body: `Your payment of ${fmt(t)} (${t.reference}) was reversed by the provider.`,
    data: { route: `/activity/${t._id}`, transactionId: String(t._id) },
  });
});
