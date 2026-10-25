import mongoose, { Schema, Document } from 'mongoose';
import bcrypt from 'bcryptjs';
export interface IUser extends Document { email: string; passwordHash: string; firstName?: string; lastName?: string; role: 'parent'; comparePassword(c: string): Promise<boolean>; }
const s = new Schema<IUser>({ email: { type: String, required: true, unique: true, lowercase: true }, passwordHash: { type: String, required: true }, firstName: String, lastName: String, role: { type: String, enum: ['parent'], default: 'parent' } }, { timestamps: true });
s.pre('save', async function(n) { if (!this.isModified('passwordHash')) return n(); this.passwordHash = await bcrypt.hash(this.passwordHash, 12); n(); });
s.methods.comparePassword = async function(c: string) { return bcrypt.compare(c, this.passwordHash); };
export default mongoose.model<IUser>('User', s);