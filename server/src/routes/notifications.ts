import { Router } from 'express'; import { authMiddleware, AuthRequest } from '../middleware/authMiddleware'; import Notification from '../models/Notification';
const r = Router();
r.get('/', authMiddleware, async (req:AuthRequest,res) => res.json(await Notification.find({userId:req.userId}).sort({createdAt:-1}).limit(50)));
r.patch('/:id/read', authMiddleware, async (req:AuthRequest,res) => { await Notification.updateOne({_id:req.params.id,userId:req.userId},{read:true}); res.json({success:true}); });
export default r;