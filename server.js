require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const rateLimit = require('express-rate-limit');
const connectDB = require('./config/db');

const app = express();

app.set('trust proxy', 1);

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.static(path.join(__dirname, 'public')));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Trop de requêtes, veuillez réessayer plus tard." }
});
app.use('/api/', limiter);

// Route de santé (sans DB)
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'ABCJ Server is running on Vercel' });
});

// ⚠️ CORRECTION BUFFERING : on ATTEND la connexion MongoDB avant toute requête API
app.use('/api', async (req, res, next) => {
  try {
    await connectDB();
    next();
  } catch (error) {
    console.error("❌ Erreur middleware DB:", error.message);
    res.status(503).json({ error: "Base de données injoignable. Réessayez dans quelques secondes." });
  }
});

try {
  app.use('/api/auth', require('./routes/authRoutes'));
  app.use('/api/user', require('./routes/userRoutes'));
  app.use('/api/notifications', require('./routes/notificationRoutes'));
  app.use('/api/admin', require('./routes/adminRoutes'));
} catch (err) {
  console.error("❌ Erreur chargement routes:", err.message);
}

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: "Erreur interne serveur" });
});

module.exports = app;
