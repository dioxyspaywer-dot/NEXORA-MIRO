import mongoose, { Schema, Document } from 'mongoose';
export interface IAuditLog extends Document { userId?: mongoose.Types.ObjectId; deviceId?: string; action: string; details?: Record<string,any>; timestamp: Date; }
const s = new Schema<IAuditLog>({ userId: Schema.Types.ObjectId, deviceId: String, action: { type: String, required: true }, details: Schema.Types.Mixed, timestamp: { type: Date, default: Date.now } });
s.index({ userId: 1, timestamp: -1 });
export default mongoose.model<IAuditLog>('AuditLog', s);