import mongoose, { Schema, Document } from 'mongoose';

export interface IPermission extends Document {
  deviceId: string;
  permissionKey: string;
  granted: boolean;
  requestedAt: Date;
  updatedAt: Date;
}

const permissionSchema = new Schema<IPermission>({
  deviceId: { type: String, required: true },
  permissionKey: { type: String, required: true },
  granted: { type: Boolean, default: false },
  requestedAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

permissionSchema.index({ deviceId: 1, permissionKey: 1 }, { unique: true });

export default mongoose.model<IPermission>('Permission', permissionSchema);