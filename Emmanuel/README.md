# NEXORA & MIRO — dépôt de démarrage V1

Ce dépôt fournit une base de projet organisée pour développer NEXORA (parent), MIRO (compagnon Android) et une API centrale. La V1 cible en priorité l'association sécurisée et l'état de connexion des appareils.

## Contenu
- `server/` : API Node.js + TypeScript + MongoDB.
- `apps/nexora-android/` : application Android native Kotlin côté parent.
- `apps/miro-android/` : application Android native Kotlin côté compagnon.
- `.github/workflows/android.yml` : compilation CI des deux APK sur GitHub Actions.
- `docs/` : cahier de route, limites de compatibilité et procédure de test.

## Important
Ce ZIP est une base de développement V1, pas un produit de surveillance prêt pour une utilisation réelle sans configuration et tests. Les fonctions futures (localisation, statistiques d'utilisation, partage d'écran, caméra/micro) ne sont pas activées dans cette V1. Elles exigent des autorisations explicites, une validation sur les appareils ciblés et des tests de sécurité. Aucune capture secrète n'est implémentée.

## Prérequis
- Compte GitHub.
- Un dépôt privé recommandé.
- Pour l'API : Node.js 20+ et une instance MongoDB (locale ou hébergée).
- Pour compiler Android : GitHub Actions peut construire les APK à partir du dépôt. Vérifier le résultat du workflow dans l'onglet **Actions**.
- Pour tester réellement : deux appareils Android compatibles, ou un appareil et un émulateur.

## Démarrage de l'API
1. Copier `server/.env.example` vers `server/.env`.
2. Renseigner `MONGODB_URI` et `PAIRING_SECRET` (une longue valeur aléatoire).
3. Dans `server/` :
   ```bash
   npm install
   npm run dev
   ```
4. Santé API : `GET /health`.

## Association V1
1. Dans NEXORA, créer un code d'association à usage unique.
2. Dans MIRO, saisir le code et un nom d'appareil.
3. MIRO échange le code contre un identifiant et un jeton d'appareil.
4. MIRO envoie périodiquement un heartbeat.
5. NEXORA affiche les appareils associés et la dernière communication.
6. Le parent peut révoquer un appareil.

L'API de développement est volontairement simple. Avant un déploiement réel, ajouter HTTPS derrière un proxy/plateforme, limitation de débit, tests de sécurité, sauvegardes et gestion robuste des secrets.

## Compilation Android
Après avoir poussé le dépôt sur GitHub, ouvrir **Actions** et lancer le workflow **Build Android APKs** (ou pousser un commit). Les APK sont publiés comme artefacts du workflow. Il faudra configurer l'URL de l'API dans les applications pour tester avec un serveur déployé.

## Configuration de l'URL API
Les applications utilisent par défaut `http://10.0.2.2:3000` pour les émulateurs Android. Pour un téléphone physique, remplacer cette URL par l'URL HTTPS publique de l'API dans les fichiers `BuildConfig`/configuration concernés. Ne pas exposer une API de production en HTTP.

## État
- V1 : association + état de connexion, structure Android + API.
- À faire avant usage réel : déployer l'API, régler l'URL, tests sur appareils, renforcer la sécurité opérationnelle.
