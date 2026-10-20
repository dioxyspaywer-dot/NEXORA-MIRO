import mongoose, { Schema, Document } from 'mongoose';

export interface IDeviceLink extends Document {
  userId: mongoose.Types.ObjectId;
  deviceId: string;
  linkedAt: Date;
  isActive: boolean;
}

const deviceLinkSchema = new Schema<IDeviceLink>({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  deviceId: { type: String, required: true },
  linkedAt: { type: Date, default: Date.now },
  isActive: { type: Boolean, default: true }
});

deviceLinkSchema.index({ userId: 1, deviceId: 1 }, { unique: true });

export default mongoose.model<IDeviceLink>('DeviceLink', deviceLinkSchema);