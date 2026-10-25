import mongoose from 'mongoose';
import { Readable } from 'stream';
import { cloudinary, isConfigured } from '../config/cloudinary';
import ScreenRecording, { IScreenRecording } from '../models/ScreenRecording';
export class StorageService {
  private useCloud = process.env.STORAGE_BACKEND === 'cloudinary' && isConfigured;
  async uploadVideo(buf: Buffer, m: {sessionId:string;deviceId:string;userId:mongoose.Types.ObjectId;durationMs:number;resolution?:string}): Promise<IScreenRecording> {
    const exp = new Date(Date.now() + parseInt(process.env.RECORDING_RETENTION_DAYS||'30')*86400000);
    if (this.useCloud) {
      const r = await new Promise<any>((res,rej)=>{const s=cloudinary.uploader.upload_stream({resource_type:'video',folder:`nexora/${m.deviceId}`},(e,r)=>e?rej(e):res(r));const rd=new Readable();rd.push(buf);rd.push(null);rd.pipe(s);});
      return ScreenRecording.create({sessionId:m.sessionId,deviceId:m.deviceId,userId:m.userId,storageBackend:'cloudinary',cloudinaryPublicId:r.public_id,cloudinarySecureUrl:r.secure_url,durationMs:m.durationMs,fileSizeBytes:buf.length,resolution:m.resolution,recordedAt:new Date(),expiresAt:exp});
    }
    const bucket = new mongoose.mongo.GridFSBucket(mongoose.connection.db!,{bucketName:'screen_recordings'});
    const us = bucket.openUploadStream(`rec_${m.sessionId}_${Date.now()}.mp4`,{metadata:{sessionId:m.sessionId,deviceId:m.deviceId}});
    const rd = new Readable(); rd.push(buf); rd.push(null);
    await new Promise<void>((res,rej)=>{rd.pipe(us).on('finish',()=>res()).on('error',rej);});
    return ScreenRecording.create({sessionId:m.sessionId,deviceId:m.deviceId,userId:m.userId,storageBackend:'gridfs',gridFsFileId:us.id,durationMs:m.durationMs,fileSizeBytes:buf.length,resolution:m.resolution,recordedAt:new Date(),expiresAt:exp});
  }
  async getDownloadStream(r: IScreenRecording): Promise<Readable> {
    if (r.storageBackend==='cloudinary') throw new Error('Use cloudinarySecureUrl');
    return new mongoose.mongo.GridFSBucket(mongoose.connection.db!,{bucketName:'screen_recordings'}).openDownloadStream(r.gridFsFileId!);
  }
  async deleteRecording(r: IScreenRecording): Promise<void> {
    if (r.storageBackend==='cloudinary'&&r.cloudinaryPublicId) await cloudinary.uploader.destroy(r.cloudinaryPublicId,{resource_type:'video'});
    else if (r.storageBackend==='gridfs'&&r.gridFsFileId) await new mongoose.mongo.GridFSBucket(mongoose.connection.db!,{bucketName:'screen_recordings'}).delete(r.gridFsFileId);
    await ScreenRecording.findByIdAndDelete(r._id);
  }
}
export const storageService = new StorageService();