import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
export interface AuthRequest extends Request { userId?: string; }
export const authMiddleware = (req: AuthRequest, res: Response, next: NextFunction) => {
  const h = req.headers.authorization;
  if (!h?.startsWith('Bearer ')) return res.status(401).json({ error: 'Token manquant' });
  try { req.userId = (jwt.verify(h.split(' ')[1], process.env.JWT_SECRET!) as {userId:string}).userId; next(); }
  catch { return res.status(401).json({ error: 'Token invalide' }); }
};