import { Router } from 'express'; import { authMiddleware, AuthRequest } from '../middleware/authMiddleware'; import LocationRecord from '../models/LocationRecord'; import DeviceLink from '../models/DeviceLink';
const r = Router();
r.get('/:deviceId', authMiddleware, async (req:AuthRequest,res) => { if(!(await DeviceLink.findOne({userId:req.userId,deviceId:req.params.deviceId,isActive:true})))return res.status(403).json({error:'Accès refusé'}); res.json(await LocationRecord.find({deviceId:req.params.deviceId}).sort({recordedAt:-1}).limit(50)); });
export default r;