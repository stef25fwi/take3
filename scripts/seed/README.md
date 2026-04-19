# Seed Firestore — Take30

## Pré-requis

1. `cd scripts && npm install`
2. Télécharger le service account JSON depuis Firebase Console → Paramètres projet → Comptes de service → Générer une nouvelle clé privée.
3. Déposer le fichier dans `scripts/seed/serviceAccountKey.json` (déjà ignoré par git).

## Emulateur local

```bash
# Terminal 1 : démarrer l'émulateur Firestore
firebase emulators:start --only firestore,auth,functions,storage

# Terminal 2 : seed (force réécrit toutes les collections seed)
cd scripts && npm run seed:emulator
```

## Production

```bash
cd scripts
npm install
npm run seed            # idempotent (skip si doc existe)
npm run seed:force      # force — écrase tout
```

## Collections produites

- `categories` — 8 catégories principales
- `users` — 4 profils de démonstration
- `scenes` — 3 scènes publiées démo
- `users/{uid}/badges` — badges imbriqués
- `duels/duel_current` — duel actif
- `dailyChallenges/{yyyy-mm-dd}` — challenge du jour (clé = date UTC)
- `leaderboards/{day|week|month|global}/entries` — top 4 initial (recalculé ensuite par la Cloud Function `computeLeaderboard`)

## Après le seed

1. Déployer les règles et index : `firebase deploy --only firestore:rules,firestore:indexes,storage`
2. Déployer les fonctions : `cd functions && npm install && npm run build && firebase deploy --only functions`
3. L'app Flutter peut démarrer avec `flutter run --dart-define=USE_FIREBASE_EMULATORS=true` pour pointer sur les émulateurs.
