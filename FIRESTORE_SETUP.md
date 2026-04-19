# Câblage Firestore Take30 — Récapitulatif

## ✅ Ce qui est en place

### Racine projet
- `firebase.json` : config Firestore / Storage / Functions / émulateurs (auth 9099, firestore 8080, functions 5001, storage 9199, UI 4000)
- `.firebaserc` : projet `take30`
- `firestore.rules` : règles strictes par rôle, compteurs réservés aux Cloud Functions
- `firestore.indexes.json` : index composites (scenes par status+createdAt / status+likesCount / category+createdAt / authorId+createdAt + collectionGroup `items`)
- `storage.rules` : scenes ≤50 Mo (video/*), thumbnails et avatars ≤2 Mo (image/*), écriture propriétaire uniquement
- `.gitignore` mis à jour (functions/lib, firebase-debug.log, serviceAccountKey*.json …)

### `take30/` (Flutter)
- `pubspec.yaml` : ajout `cloud_firestore`, `firebase_storage`, `cloud_functions`, `sign_in_with_apple`
- `lib/models/models.dart` : réécriture avec `fromFirestore` / `toFirestore` + nouveaux `UserStub`, `CommentModel`, `FollowEdge`, `LikeRecord`, `VoteRecord`
- `lib/services/firebase/` : couche repositories typés
  - `firestore_refs.dart` — références typées `.withConverter`
  - `users_repo.dart`, `scenes_repo.dart`, `comments_repo.dart`
  - `notifications_repo.dart`, `duels_repo.dart`, `daily_challenge_repo.dart`
  - `leaderboard_repo.dart`, `storage_service.dart`
- `lib/services/api_service.dart` : refactoré en **façade** (singleton), délègue aux repos
- `lib/services/auth_service.dart` : réécrit avec **FirebaseAuth + Google + Apple**, sync `users/{uid}` à la création, gestion `fcmTokens`
- `lib/providers/providers.dart` : `notificationsProvider` et `dailyChallengeProvider` passent en `StreamProvider`, `AuthNotifier` délègue à `AuthService`
- `lib/main.dart` : flag `--dart-define=USE_FIREBASE_EMULATORS=true` pour basculer sur l'émulateur

### `functions/` (Cloud Functions v2 TypeScript, Node 20, region `europe-west1`)
- `onSceneCreate` / `onSceneDelete` : compteurs `scenesCount` + fan-out feed aux abonnés
- `onLikeWrite` : maj `likesCount` + notification au créateur
- `onCommentCreate` : maj `commentsCount` + notification
- `toggleFollow` (callable) : crée / supprime les arêtes `followers|following` + compteurs + notif
- `onDuelVote` : maj `votesA|votesB`
- `pingSceneView` (callable) : incrément `viewsCount` throttlé 5 min par user
- `sendPushOnNotificationCreate` : FCM multicast + purge tokens invalides
- `computeLeaderboard` (scheduled 1 h) : agrège day/week/month/global

### `scripts/seed/`
- `seed_firestore.js` idempotent (option `--force`)
- Données JSON : categories, users, scenes, badges, duel, dailyChallenge, leaderboard
- `README.md` avec instructions emulator/prod

## ⚠️ Étapes manuelles restantes (à faire par toi)

1. **Dépendances Flutter** :
   ```bash
   cd take30 && flutter pub get
   ```

2. **FlutterFire Android/iOS** — les placeholders `REMPLACE_MOI` dans `lib/firebase_options.dart` doivent être remplacés :
   ```bash
   cd take30 && flutterfire configure --project=take30
   ```

3. **Service account Admin** pour le seed :
   - Firebase Console → Paramètres projet → Comptes de service → Générer une clé privée
   - Déposer dans `scripts/seed/serviceAccountKey.json` (déjà gitignoré)

4. **Émulateurs + seed local** :
   ```bash
   firebase emulators:start --only firestore,auth,functions,storage
   # autre terminal
   cd scripts && npm install && npm run seed:emulator
   ```

5. **Lancer l'app sur émulateur** :
   ```bash
   cd take30
   flutter run --dart-define=USE_FIREBASE_EMULATORS=true
   ```

6. **Déploiement prod** :
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes,storage
   cd functions && npm install && npm run build
   firebase deploy --only functions
   cd ../scripts && npm run seed
   ```

## 🚧 Hors scope (à traiter plus tard)

- Les écrans (`explore_screen.dart`, `record_screen.dart`, `preview_publish_screen.dart`, `scene_detail_screen.dart`, `leaderboard_screen.dart`, `badges_stats_screen.dart`, `router/router.dart`, `widgets/shared_widgets.dart`) **utilisent encore `MockData` en fallback d'affichage** (widget.scene ?? MockData.scenes.first, MockData.formatCount, etc.). Le chemin données principal passe désormais par Firestore via les providers ; ces fallbacks ne se déclenchent qu'en l'absence de donnée. Un suivi pourra remplacer ces `MockData.*` par des états vides / placeholders.
- `upload_service.dart` conserve un mock `MockData.users.firstWhere(...)` — à substituer par `apiServiceProvider.currentUser` quand l'upload réel sera câblé.
- Notification tap routing (`notification_service.dart`) reste à enrichir avec GoRouter (lire `message.data['type']` / `sceneId`).
- Déploiement Firebase Functions nécessite un plan **Blaze** (pubsub scheduler + FCM multicast).
