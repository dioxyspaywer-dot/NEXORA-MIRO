# Cahier de route NEXORA & MIRO

## Objectif
Projet privé de contrôle parental, à usage personnel. NEXORA est l'application parent ; MIRO est le compagnon Android. La V1 est limitée à l'association sécurisée et à l'état de connexion.

## Architecture
- NEXORA Android (Kotlin) : création d'un code de liaison, liste des appareils, révocation.
- MIRO Android (Kotlin) : association par code, état de liaison, heartbeat.
- API Node.js/TypeScript : authentification, codes temporaires, gestion des appareils.
- MongoDB : utilisateurs parent, codes de liaison, appareils.

## V1
1. Génération d'un code à durée limitée.
2. Association d'un appareil après saisie du code.
3. Jeton individuel pour l'appareil.
4. Heartbeat périodique et date de dernière communication.
5. Liste parent des appareils.
6. Révocation d'un appareil.

## Principes de sécurité
- Ne pas mettre de secrets de production dans le code.
- Utiliser HTTPS en production.
- Codes temporaires à usage unique.
- Révocation immédiate des jetons d'appareil.
- Pas de collecte de contenu privé, caméra, microphone ou écran en arrière-plan.
- Toute fonction sensible future devra suivre les autorisations et confirmations Android.

## Compatibilité
NEXORA est destiné à être testé sur Huawei Y9 2019 / Android 9. Le modèle du premier téléphone enfant n'est pas encore connu. MIRO est structuré pour Android, mais les fonctions spécifiques dépendront du modèle, de la version Android et des politiques du fabricant.

## Étapes suivantes
- Déployer l'API sur une plateforme HTTPS.
- Configurer `API_BASE_URL` dans les deux apps.
- Compiler avec GitHub Actions.
- Tester association, heartbeat, coupure réseau et révocation.
- Ajouter ensuite les rapports autorisés et les autres fonctions une par une.
