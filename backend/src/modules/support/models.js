import mongoose from 'mongoose';

const { Schema } = mongoose;

const messageSchema = new Schema({
  authorType: { type: String, enum: ['USER', 'ADMIN', 'SYSTEM'], required: true },
  authorId: Schema.Types.ObjectId,
  body: { type: String, required: true, maxlength: 4000 },
  internal: { type: Boolean, default: false }, // admin-only notes
  createdAt: { type: Date, default: Date.now },
}, { _id: true });

const supportTicketSchema = new Schema({
  reference: { type: String, required: true },
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  category: { type: String, enum: ['PAYMENT', 'ACCOUNT', 'KYC', 'CARD', 'SECURITY', 'ACCOUNT_RECOVERY', 'FEEDBACK', 'OTHER'], required: true },
  subject: { type: String, required: true, maxlength: 140 },
  status: { type: String, enum: ['OPEN', 'IN_PROGRESS', 'AWAITING_USER', 'RESOLVED', 'CLOSED'], default: 'OPEN' },
  priority: { type: String, enum: ['LOW', 'NORMAL', 'HIGH', 'URGENT'], default: 'NORMAL' },
  transactionId: { type: Schema.Types.ObjectId, ref: 'Transaction' },
  assignedTo: { type: Schema.Types.ObjectId, ref: 'AdminUser' },
  metadata: Schema.Types.Mixed,
  messages: { type: [messageSchema], default: [] },
  resolvedAt: Date,
}, { timestamps: true });
supportTicketSchema.index({ reference: 1 }, { unique: true });
supportTicketSchema.index({ userId: 1, createdAt: -1 });
supportTicketSchema.index({ status: 1, priority: -1, createdAt: 1 });

export const SupportTicket = mongoose.model('SupportTicket', supportTicketSchema);
