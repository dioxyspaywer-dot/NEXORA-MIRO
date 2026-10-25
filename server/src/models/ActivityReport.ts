import mongoose, { Schema, Document } from 'mongoose';
export interface IActivityReport extends Document { deviceId: string; userId: mongoose.Types.ObjectId; date: Date; totalScreenTimeMs: number; appUsage: Array<{packageName:string;durationMs:number}>; syncedAt: Date; }
const s = new Schema<IActivityReport>({ deviceId: { type: String, required: true }, userId: { type: Schema.Types.ObjectId, ref: 'User', required: true }, date: { type: Date, required: true }, totalScreenTimeMs: { type: Number, default: 0 }, appUsage: [{ packageName: String, durationMs: Number }], syncedAt: { type: Date, default: Date.now } });
s.index({ deviceId: 1, date: 1 });
export default mongoose.model<IActivityReport>('ActivityReport', s);