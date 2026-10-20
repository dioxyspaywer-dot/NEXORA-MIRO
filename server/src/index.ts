import 'dotenv/config';
import express, { Request, Response, NextFunction } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { MongoClient, ObjectId } from 'mongodb';
import crypto from 'crypto';

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '32kb' }));

const port = Number(process.env.PORT || 3000);
const uri = process.env.MONGODB_URI;
const dbName = process.env.MONGODB_DB || 'nexora_miro';
const parentKey = process.env.PARENT_ACCESS_KEY;
if (!uri || !parentKey) {
  console.error('Missing MONGODB_URI or PARENT_ACCESS_KEY in environment.');
  process.exit(1);
}
const client = new MongoClient(uri);
let db: ReturnType<MongoClient['db']>;

function safeEqual(a: string, b: string): boolean {
  const aa = Buffer.from(a);
  const bb = Buffer.from(b);
  return aa.length === bb.length && crypto.timingSafeEqual(aa, bb);
}
function parentAuth(req: Request, res: Response, next: NextFunction) {
  const supplied = String(req.header('x-parent-key') || '');
  if (!safeEqual(supplied, parentKey!)) {
    return res.status(401).json({ error: 'parent_auth_required' });
  }
  next();
}
function randomCode() {
  return String(crypto.randomInt(100000, 1000000));
}
function hashToken(token: string) {
  return crypto.createHash('sha256').update(token).digest('hex');
}
app.get('/health', (_req, res) => res.json({ ok: true, service: 'nexora-miro-api' }));

app.post('/api/pairing-codes', parentAuth, async (_req, res) => {
  const code = randomCode();
  const codeHash = hashToken(code);
  const expiresAt = new Date(Date.now() + 5 * 60 * 1000);
  await db.collection('pairing_codes').insertOne({ codeHash, expiresAt, used: false, createdAt: new Date() });
  res.json({ code, expiresAt });
});

app.post('/api/pair', async (req, res) => {
  const code = String(req.body?.code || '').trim();
  const deviceName = String(req.body?.deviceName || '').trim().slice(0, 80);
  const platform = String(req.body?.platform || 'Android').slice(0, 40);
  if (!/^\d{6}$/.test(code) || !deviceName) {
    return res.status(400).json({ error: 'valid_code_and_device_name_required' });
  }
  const record = await db.collection('pairing_codes').findOne({
    codeHash: hashToken(code), used: false, expiresAt: { $gt: new Date() }
  });
  if (!record) return res.status(400).json({ error: 'invalid_or_expired_code' });
  const update = await db.collection('pairing_codes').updateOne(
    { _id: record._id, used: false },
    { $set: { used: true, usedAt: new Date() } }
  );
  if (update.modifiedCount !== 1) return res.status(409).json({ error: 'code_already_used' });

  const deviceId = new ObjectId().toHexString();
  const token = crypto.randomBytes(32).toString('hex');
  await db.collection('devices').insertOne({
    deviceId, deviceName, platform, tokenHash: hashToken(token),
    createdAt: new Date(), lastSeenAt: new Date(), revokedAt: null
  });
  res.json({ deviceId, deviceToken: token, message: 'paired' });
});

async function deviceAuth(req: Request, res: Response, next: NextFunction) {
  const token = String(req.header('x-device-token') || '');
  if (!token) return res.status(401).json({ error: 'device_auth_required' });
  const device = await db.collection('devices').findOne({ tokenHash: hashToken(token), revokedAt: null });
  if (!device) return res.status(401).json({ error: 'invalid_or_revoked_device' });
  (req as any).device = device;
  next();
}

app.post('/api/device/heartbeat', deviceAuth, async (req: Request, res: Response) => {
  const device = (req as any).device;
  const now = new Date();
  await db.collection('devices').updateOne({ _id: device._id }, { $set: { lastSeenAt: now } });
  res.json({ ok: true, serverTime: now.toISOString() });
});

app.get('/api/devices', parentAuth, async (_req, res) => {
  const rows = await db.collection('devices').find({ revokedAt: null })
    .project({ tokenHash: 0 }).sort({ createdAt: -1 }).toArray();
  const now = Date.now();
  res.json(rows.map((d: any) => ({
    deviceId: d.deviceId,
    deviceName: d.deviceName,
    platform: d.platform,
    createdAt: d.createdAt,
    lastSeenAt: d.lastSeenAt,
    status: d.lastSeenAt && now - new Date(d.lastSeenAt).getTime() < 90_000 ? 'online' : 'offline'
  })));
});

app.post('/api/devices/:deviceId/revoke', parentAuth, async (req, res) => {
  const result = await db.collection('devices').updateOne(
    { deviceId: req.params.deviceId, revokedAt: null },
    { $set: { revokedAt: new Date() } }
  );
  if (!result.matchedCount) return res.status(404).json({ error: 'device_not_found' });
  res.json({ ok: true, revoked: true });
});

async function start() {
  await client.connect();
  db = client.db(dbName);
  await db.collection('pairing_codes').createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
  await db.collection('devices').createIndex({ deviceId: 1 }, { unique: true });
  app.listen(port, () => console.log(`NEXORA & MIRO API listening on ${port}`));
}
start().catch(err => { console.error(err); process.exit(1); });
