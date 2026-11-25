import { NotificationCampaign } from './models.js';
import { User } from '../users/models.js';
import { notify } from '../notifications/service.js';
import { registerInlineHandler, QUEUES } from '../../lib/queue.js';

/**
 * Fans a promotional campaign out to consenting users with a cursor, so
 * millions of recipients never load into memory. Only users with marketing
 * consent are targeted (Kenya DPA s.37 — direct marketing requires consent).
 */
export async function sendNotificationCampaign({ campaignId }) {
  const c = await NotificationCampaign.findOneAndUpdate({ _id: campaignId, status: 'SCHEDULED' }, { $set: { status: 'SENDING' } }, { returnDocument: 'after' });
  if (!c) return { skipped: true };
  const filter = { status: 'ACTIVE', 'consents.marketing': true };
  if (c.segment?.countries?.length) filter.country = { $in: c.segment.countries };
  if (c.segment?.kycTiers?.length) filter.kycTier = { $in: c.segment.kycTiers };
  let sent = 0;
  for await (const u of User.find(filter, { _id: 1 }).lean().cursor({ batchSize: 1000 })) {
    await notify(u._id, { category: 'PROMOTION', type: 'CAMPAIGN', title: c.title, body: c.body, campaignId: c._id, data: { route: '/rewards' } });
    sent++;
    if (sent % 1000 === 0) await NotificationCampaign.updateOne({ _id: c._id }, { $set: { sentCount: sent } });
  }
  await NotificationCampaign.updateOne({ _id: c._id }, { $set: { status: 'SENT', sentCount: sent, sentAt: new Date() } });
  return { sent };
}

registerInlineHandler(QUEUES.notifications, 'campaign', (job) => sendNotificationCampaign(job.data));
