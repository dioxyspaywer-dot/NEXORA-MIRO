# NEXORA & MIRO
Système de supervision familiale à distance avec enregistrements d'écran.
## Architecture
- `/server` — API Node.js + TypeScript + MongoDB + WebSocket + GridFS + Cloudinary
- `/nexora` — Application parent Flutter
- `/miro` — Application compagnon Kotlin natif
## Compilation
Tout est automatisé via GitHub Actions. Voir `.github/workflows/build.yml`