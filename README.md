# NEXORA & MIRO
Système de supervision familiale à distance avec enregistrement d'écran.

## Bloc 1 — Serveur complet
API Node.js + TypeScript + MongoDB + WebSocket + GridFS + Cloudinary (optionnel)

## Fonctionnalités incluses
- Authentification parent/enfant
- Association sécurisée par code temporaire
- Rapports d'activité et localisation
- Gestion des règles et permissions
- Sessions en direct (WebRTC signaling)
- **Enregistrement vidéo d'écran** (GridFS par défaut, Cloudinary activable)
- Notifications et audit logs

## Démarrage (GitHub Codespaces — sans terminal)
Tout est automatisé via GitHub Actions. Voir .github/workflows/