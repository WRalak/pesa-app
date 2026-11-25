import { Errors } from './errors.js';
import mongoose from 'mongoose';

/**
 * Opaque cursor pagination over (sortField desc, _id desc). Stable under
 * concurrent inserts and O(log n) with a compound index — no skip/offset.
 */
export function encodeCursor(doc, sortField = 'createdAt') {
  const v = doc[sortField];
  return Buffer.from(JSON.stringify([v instanceof Date ? v.toISOString() : v, String(doc._id)])).toString('base64url');
}

export function decodeCursor(cursor) {
  try {
    const [v, id] = JSON.parse(Buffer.from(cursor, 'base64url').toString('utf8'));
    if (!mongoose.isValidObjectId(id)) throw new Error('bad id');
    return { value: v, id: new mongoose.Types.ObjectId(id) };
  } catch {
    throw Errors.badRequest('Invalid cursor');
  }
}

export async function paginate(Model, filter, { cursor, limit = 20, sortField = 'createdAt', projection, lean = true } = {}) {
  const size = Math.min(Math.max(Number(limit) || 20, 1), 100);
  const query = { ...filter };
  if (cursor) {
    const { value, id } = decodeCursor(cursor);
    const v = sortField === 'createdAt' || sortField.endsWith('At') ? new Date(value) : value;
    query.$or = [{ [sortField]: { $lt: v } }, { [sortField]: v, _id: { $lt: id } }];
    if (filter.$or) {
      query.$and = [{ $or: filter.$or }, { $or: query.$or }];
      delete query.$or;
    }
  }
  let q = Model.find(query, projection).sort({ [sortField]: -1, _id: -1 }).limit(size + 1);
  if (lean) q = q.lean();
  const docs = await q;
  const hasMore = docs.length > size;
  const items = hasMore ? docs.slice(0, size) : docs;
  return { items, nextCursor: hasMore ? encodeCursor(items[items.length - 1], sortField) : null, hasMore };
}
