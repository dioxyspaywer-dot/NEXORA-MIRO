import http from 'http'; import app from './app'; import { connectDB } from './config/database'; import { WSService } from './services/websocket';
const PORT = parseInt(process.env.PORT||'3000');
(async()=>{await connectDB();const s=http.createServer(app);new WSService(s);s.listen(PORT,()=>console.log(`🚀 NEXORA serveur port ${PORT}`));})();