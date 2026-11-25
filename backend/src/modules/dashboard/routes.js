import { createRouter } from '../../lib/router.js';
import { getDashboard } from './service.js';
import { requireAuth, loadActiveUser } from '../../middleware/auth.js';

const r = createRouter({ prefix: '/v1/dashboard', tags: ['Dashboard'], security: 'bearerAuth' });
r.route({ method: 'get', path: '/', summary: 'Home dashboard (balances by provenance, month summary, savings, budget)', middleware: [requireAuth, loadActiveUser], handler: (req) => getDashboard(req.userDoc) });
export default r.router;
