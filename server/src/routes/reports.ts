import { Router } from 'express'; import { authMiddleware, AuthRequest } from '../middleware/authMiddleware'; import ActivityReport from '../models/ActivityReport'; import DeviceLink from '../models/DeviceLink';
const r = Router();
r.get('/:deviceId', authMiddleware, async (req:AuthRequest,res) => { if(!(await DeviceLink.findOne({userId:req.userId,deviceId:req.params.deviceId,isActive:true})))return res.status(403).json({error:'Accès refusé'}); res.json(await ActivityReport.find({deviceId:req.params.deviceId}).sort({date:-1}).limit(30)); });
export default r;