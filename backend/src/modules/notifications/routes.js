import { createRouter, idParams, pageQuery } from '../../lib/router.js';
import { z } from '../../lib/openapi.js';
import { Notification } from './models.js';
import { serialize } from './service.js';
import { paginate } from '../../lib/pagination.js';
import { requireAuth } from '../../middleware/auth.js';
import { Errors } from '../../lib/errors.js';

const r = createRouter({ prefix: '/v1/notifications', tags: ['Notifications'], security: 'bearerAuth' });

r.route({
  method: 'get', path: '/', summary: 'In-app notifications', middleware: [requireAuth],
  query: pageQuery.extend({ unread: z.coerce.boolean().optional(), category: z.string().max(20).optional() }),
  handler: async (req) => {
    const q = req.valid.query;
    const filter = { userId: req.user.id };
    if (q.unread) filter.readAt = null;
    if (q.category) filter.category = q.category;
    const [page, unreadCount] = await Promise.all([
      paginate(Notification, filter, q),
      Notification.countDocuments({ userId: req.user.id, readAt: null }),
    ]);
    return { ...page, items: page.items.map(serialize), unreadCount };
  },
});

r.route({
  method: 'post', path: '/:id/read', summary: 'Mark one notification read', params: idParams, middleware: [requireAuth],
  handler: async (req) => {
    const n = await Notification.findOneAndUpdate({ _id: req.valid.params.id, userId: req.user.id }, { $set: { readAt: new Date() } }, { returnDocument: 'after' }).lean();
    if (!n) throw Errors.notFound('Notification');
    return serialize(n);
  },
});

r.route({
  method: 'post', path: '/read-all', summary: 'Mark all notifications read', middleware: [requireAuth],
  handler: async (req) => {
    const r2 = await Notification.updateMany({ userId: req.user.id, readAt: null }, { $set: { readAt: new Date() } });
    return { updated: r2.modifiedCount };
  },
});

export default r.router;
