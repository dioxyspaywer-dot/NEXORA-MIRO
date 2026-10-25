import WebSocket, { WebSocketServer } from 'ws';
import jwt from 'jsonwebtoken';
interface CS extends WebSocket { userId?: string; deviceId?: string; }
export class WSService {
  private wss: WebSocketServer; private clients = new Map<string, CS>();
  constructor(server: any) {
    this.wss = new WebSocketServer({ server });
    this.wss.on('connection', (ws: CS, req) => {
      const t = new URL(req.url||'','http://localhost').searchParams.get('token');
      if (!t) { ws.close(); return; }
      try { const p = jwt.verify(t, process.env.JWT_SECRET!) as {userId?:string;deviceId?:string}; ws.userId=p.userId; ws.deviceId=p.deviceId; this.clients.set(p.deviceId||p.userId!,ws); } catch { ws.close(); }
      ws.on('close', () => this.clients.delete(ws.deviceId||ws.userId!));
    });
  }
  sendToDevice(id:string,d:object){const w=this.clients.get(id);if(w?.readyState===WebSocket.OPEN)w.send(JSON.stringify(d));}
  sendToUser(id:string,d:object){const w=this.clients.get(id);if(w?.readyState===WebSocket.OPEN)w.send(JSON.stringify(d));}
}