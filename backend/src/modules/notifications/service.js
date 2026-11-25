import { Notification } from './models.js';
import { UserProfile } from '../users/models.js';
import { Device } from '../auth/models.js';
import { enqueue, QUEUES, registerInlineHandler } from '../../lib/queue.js';
import { emitToUser } from '../../lib/realtime.js';
import { sendPush } from './push.js';

const PREF_FOR_CATEGORY = {
  TRANSACTION: 'transactions', PAYMENT: 'transactions', SAVINGS: 'savings', BUDGET: 'budgets',
  PROMOTION: 'promotions', REWARD: 'promotions', SECURITY: 'security', SYSTEM: null,
};

/**
 * Creates an in-app notification (always, except for opted-out promotions)
 * and queues a push notification if the user's preferences allow it.
 * Security alerts cannot be suppressed.
 */
export async function notify(userId, { category, type, title, body, data, campaignId }) {
  const profile = await UserProfile.findOne({ userId }, { notificationPreferences: 1 }).lean();
  const prefs = profile?.notificationPreferences ?? {};
  const prefKey = PREF_FOR_CATEGORY[category];
  const categoryEnabled = category === 'SECURITY' || !prefKey || prefs[prefKey] !== false;
  if (!categoryEnabled && (category === 'PROMOTION' || category === 'REWARD')) return null;

  const notification = await Notification.create({ userId, category, type, title, body, data, campaignId });
  emitToUser(String(userId), 'notification', serialize(notification));
  if (categoryEnabled && (category === 'SECURITY' || prefs.push !== false)) {
    await enqueue(QUEUES.notifications, 'push', { notificationId: String(notification._id) }, { jobId: `push-${notification._id}` });
  }
  return notification;
}

export async function deliverPush({ notificationId }) {
  const n = await Notification.findById(notificationId).lean();
  if (!n) return;
  const devices = await Device.find({ userId: n.userId, revokedAt: null, pushToken: { $ne: null } }).select('+pushToken').lean();
  let sent = false;
  for (const d of devices) {
    const r = await sendPush(d.pushToken, { title: n.title, body: n.body, data: { type: n.type, id: String(n._id), ...(n.data ?? {}) } });
    if (r === 'INVALID_TOKEN') await Device.updateOne({ _id: d._id }, { $unset: { pushToken: 1 } });
    if (r === 'SENT') sent = true;
  }
  if (sent) await Notification.collection.updateOne({ _id: n._id }, { $addToSet: { deliveredChannels: 'PUSH' } });
}

registerInlineHandler(QUEUES.notifications, 'push', (job) => deliverPush(job.data));

export function serialize(n) {
  return {
    id: String(n._id),
    category: n.category,
    type: n.type,
    title: n.title,
    body: n.body,
    data: n.data ?? null,
    read: Boolean(n.readAt),
    createdAt: n.createdAt,
  };
}
