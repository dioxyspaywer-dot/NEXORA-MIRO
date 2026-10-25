import mongoose from 'mongoose';
import dotenv from 'dotenv';
dotenv.config();
export const connectDB = async (): Promise<void> => {
  try { await mongoose.connect(process.env.MONGODB_URI || ''); console.log('✅ MongoDB connecté'); }
  catch (err) { console.error('❌ Erreur MongoDB:', err); process.exit(1); }
};