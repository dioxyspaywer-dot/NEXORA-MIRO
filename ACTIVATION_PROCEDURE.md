# Procédure d'activation séquentielle NEXORA & MIRO

## Ordre d'activation
1. ✅ Association + État connexion (déjà actif)
2. Rapports d'activité → `activityReports=true` (Nexora) + `ACTIVITY_REPORTS=true` (Miro) → Push → Tester
3. Localisation → `locationTracking=true` + `LOCATION_TRACKING=true` → Push → Tester
4. Enregistrement écran → `screenRecording=true` + `SCREEN_RECORDING=true` → Push → Tester
5. Sessions en direct → `liveSessions=true` + `LIVE_SESSIONS=true` → Push → Tester
6. Règles → `rulesManagement=true` + `RULES_SYNC=true` → Push → Tester
7. Notifications → `notifications=true` → Push → Tester

## Correction d'erreurs
- Chaque push déclenche la compilation automatique via GitHub Actions
- Télécharger les APK depuis Actions → Artifacts
- Si erreur : vérifier les logs dans Actions
- Ne jamais modifier la structure, seulement les feature flags

## Configuration requise avant premier push
1. Créer un cluster MongoDB Atlas gratuit
2. Ajouter dans GitHub → Settings → Secrets → Actions :
   - `API_URL` : URL de ton serveur (ex: https://ton-app.vercel.app/api)
   - `MONGODB_URI` : URI de connexion MongoDB
   - `JWT_SECRET` : Clé secrète JWT (chaîne aléatoire 32+ caractères)
