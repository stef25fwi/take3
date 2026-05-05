# Migration progressive — Feed IA vertical Take60

## Objectif

Déployer le feed vertical plein écran sans casser le feed actuel, l’admin réel, Take60 Guided Record ni les Battles existantes.

## Étapes

1. **Shadow write**
   - Activer `generateFeedCandidates` sur les scènes publiées.
   - Garder le feed actuel comme fallback client.
   - Vérifier les collections `feedCandidates`, `feedEvents`, `userFeedProfiles`.

2. **Soft launch interne**
   - Exposer `/feed` depuis l’accueil.
   - `getPersonalizedFeed` retourne un mix : 70% goûts, 20% trending, 10% exploration.
   - Toutes les interactions passent par `recordFeedEvent`.

3. **Battles dans le feed**
   - Injecter les battles `published` / `voting_open`.
   - Les votes depuis le feed redirigent vers la page Battle existante pour conserver la logique de vote actuelle.

4. **Optimisation ranking**
   - Planifier `generateFeedCandidates` après publication / toutes les heures.
   - Déclencher `computeFeedProfile` après lots d’interactions fortes.
   - Ajuster les poids après observation : complétion, rewatch, skip, share.

5. **Généralisation**
   - Remplacer progressivement les entrées du feed classique par `/feed`.
   - Conserver `ScenesRepo.getFeed()` comme fallback production.

## Sécurité

- Écritures directes client interdites sur `feedEvents`, `userFeedProfiles`, `feedCandidates`.
- Cloud Functions seulement pour l’analytics et le scoring.
- Lecture profil feed limitée à l’utilisateur propriétaire.
