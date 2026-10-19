# Tests manuels V1

1. Démarrer l'API avec MongoDB configuré.
2. Ouvrir NEXORA et saisir la valeur `PARENT_ACCESS_KEY` dans le champ parent.
3. Créer un code d'association.
4. Ouvrir MIRO et saisir ce code avec un nom d'appareil.
5. Appuyer sur « Vérifier la connexion ».
6. Retourner dans NEXORA et actualiser la liste : l'appareil devrait apparaître en ligne si un heartbeat récent a été reçu.
7. Révoquer l'appareil dans NEXORA.
8. Vérifier que MIRO ne peut plus envoyer de heartbeat avec son ancien jeton.

## Limites du prototype
- Le heartbeat est déclenché manuellement par un bouton ; il n'y a pas encore de service d'arrière-plan.
- L'authentification parent utilise une clé partagée de prototype ; avant production, remplacer par une authentification robuste et des jetons courts.
- Pour un téléphone réel, remplacer l'URL API de développement par une URL HTTPS accessible.
- Le trafic HTTP clair est uniquement pour le développement local. Ne pas utiliser cette configuration en production.
