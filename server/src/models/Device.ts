import mongoose, { Schema, Document } from 'mongoose';

export interface IDevice extends Document {
  deviceId: string;
  name: string;
  manufacturer?: string;
  model?: string;
  androidVersion?: string;
  status: 'online' | 'offline' | 'syncing' | 'revoked';
  lastSeenAt?: Date;
  permissions: Record<string, boolean>;
  supportsScreenRecording: boolean;
}

const deviceSchema = new Schema<IDevice>({
  deviceId: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  manufacturer: String,
  model: String,
  androidVersion: String,
  status: { type: String, enum: ['online','offline','syncing','revoked'], default: 'offline' },
  lastSeenAt: Date,
  permissions: { type: Map, of: Boolean, default: {} },
  supportsScreenRecording: { type: Boolean, default: false }
}, { timestamps: true });

export default mongoose.model<IDevice>('Device', deviceSchema);