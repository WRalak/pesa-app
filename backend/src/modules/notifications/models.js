import mongoose from 'mongoose';

const { Schema } = mongoose;

export const NOTIFICATION_CATEGORIES = ['TRANSACTION', 'PAYMENT', 'SAVINGS', 'BUDGET', 'SECURITY', 'PROMOTION', 'REWARD', 'SYSTEM'];

const notificationSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  category: { type: String, enum: NOTIFICATION_CATEGORIES, required: true },
  type: { type: String, required: true }, // e.g. PAYMENT_SUCCESSFUL, BUDGET_EXCEEDED
  title: { type: String, required: true, maxlength: 120 },
  body: { type: String, required: true, maxlength: 500 },
  data: { type: Schema.Types.Mixed }, // deep-link payload, never secrets
  readAt: Date,
  deliveredChannels: { type: [String], default: [] },
  campaignId: { type: Schema.Types.ObjectId },
}, { timestamps: { createdAt: true, updatedAt: false }, versionKey: false });
notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, readAt: 1 });
notificationSchema.index({ createdAt: 1 }, { expireAfterSeconds: 60 * 60 * 24 * 180 });

export const Notification = mongoose.model('Notification', notificationSchema);
