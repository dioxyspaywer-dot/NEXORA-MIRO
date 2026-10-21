import mongoose, { Schema, Document } from 'mongoose';
export interface ILocationRecord extends Document { deviceId: string; userId: mongoose.Types.ObjectId; latitude: number; longitude: number; accuracy?: number; recordedAt: Date; expiresAt: Date; }
const s = new Schema<ILocationRecord>({ deviceId: { type: String, required: true }, userId: { type: Schema.Types.ObjectId, ref: 'User', required: true }, latitude: { type: Number, required: true }, longitude: { type: Number, required: true }, accuracy: Number, recordedAt: { type: Date, required: true }, expiresAt: { type: Date, required: true } });
s.index({ deviceId: 1, recordedAt: -1 });
s.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
export default mongoose.model<ILocationRecord>('LocationRecord', s);