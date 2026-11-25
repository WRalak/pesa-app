import { connectDb, disconnectDb } from '../src/lib/db.js';
import { verifyAuditChain } from '../src/modules/audit/service.js';
import { closeRedis } from '../src/lib/redis.js';

await connectDb();
const r = await verifyAuditChain();
console.log(JSON.stringify(r));
await disconnectDb();
await closeRedis();
process.exit(r.valid ? 0 : 2);
