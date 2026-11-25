/**
 * Mongoose plugin that makes a collection append-only at the ODM layer:
 * any attempt to update or delete documents throws. Combined with MongoDB
 * role restrictions (no update/remove privileges for the app user on these
 * collections in production) this provides an immutable audit trail.
 */
const BLOCKED = [
  'updateOne', 'updateMany', 'findOneAndUpdate', 'findOneAndReplace', 'replaceOne',
  'deleteOne', 'deleteMany', 'findOneAndDelete',
];

export function appendOnly(schema) {
  for (const op of BLOCKED) {
    schema.pre(op, { document: false, query: true }, function block() {
      throw new Error(`${this.model?.modelName ?? 'Collection'} is append-only: ${op} is not permitted`);
    });
  }
  schema.pre('deleteOne', { document: true, query: false }, function block() {
    throw new Error('Append-only documents cannot be deleted');
  });
  schema.pre('save', function blockResave() {
    if (!this.isNew) throw new Error('Append-only documents cannot be modified');
  });
}
