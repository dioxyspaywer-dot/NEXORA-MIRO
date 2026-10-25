import mongoose, { Schema, Document } from 'mongoose';
export interface IRule extends Document { userId: mongoose.Types.ObjectId; deviceId: string; type: 'screen_time_limit'|'schedule'|'bedtime'|'reminder'; config: Record<string,any>; isActive: boolean; }
const s = new Schema<IRule>({ userId: { type: Schema.Types.ObjectId, ref: 'User', required: true }, deviceId: { type: String, required: true }, type: { type: String, required: true }, config: { type: Schema.Types.Mixed, required: true }, isActive: { type: Boolean, default: true } }, { timestamps: true });
s.index({ userId: 1, deviceId: 1 });
export default mongoose.model<IRule>('Rule', s);