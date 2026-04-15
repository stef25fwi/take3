# Audit Firebase et tuto de cablage complet

## Resume rapide

Le depot contient deja un branchement Firebase fonctionnel sur la surface web React/Vite, mais l'application Flutter principale n'est pas cablee a Firebase malgre la presence des dependances.

En l'etat actuel :

- la web app secondaire initialise bien Firebase, Firestore et Analytics
- l'app Flutter ne fait jamais `Firebase.initializeApp()`
- aucun fichier natif Firebase n'est present pour Android et iOS
- le push FCM et l'auth Firebase ne peuvent pas fonctionner cote Flutter
- le projet mobile utilise encore les identifiants par defaut `com.example.take30`

## Audit de l'existant

### 1. Surface web React/Vite : branchement present

Constat :

- `apps/web/src/lib/firebase.js` initialise `initializeApp`, `getFirestore` et `getAnalytics`
- `apps/web/src/main.jsx` lance l'initialisation Analytics
- la configuration web Firebase est codee en dur dans `apps/web/src/lib/firebase.js`

Impact :

- cette surface est deja connectee au projet Firebase `take30`
- l'API key web est visible dans le code et dans le build, ce qui est normal pour une configuration Firebase web
- la securite ne repose pas sur cette cle mais sur les Firebase Rules, App Check et les restrictions GCP

Point d'attention :

- `apps/web/package.json` utilise `firebase: latest`, ce qui rend les builds moins reproductibles
- si cette surface reste active, mieux vaut basculer la config vers des variables `VITE_FIREBASE_*`

### 2. Surface Flutter principale : branchement absent

Constat :

- `take30/pubspec.yaml` declare `firebase_core`, `firebase_messaging`, `firebase_auth` et `google_sign_in`
- `take30/lib/main.dart` ne charge ni `firebase_core` ni `firebase_options.dart`
- aucune occurrence de `Firebase.initializeApp`, `FirebaseAuth`, `FirebaseMessaging` ou `DefaultFirebaseOptions` n'est utilisee dans `take30/lib`

Impact :

- les dependances sont installees mais inutilisees
- tout appel Firebase futur cassera au runtime tant que l'init globale n'est pas faite

### 3. Android Flutter : blocage natif

Constat :

- `take30/android/app/google-services.json` est absent
- `take30/android/settings.gradle.kts` ne declare pas le plugin `com.google.gms.google-services`
- `take30/android/app/build.gradle.kts` n'applique pas `com.google.gms.google-services`
- `take30/android/app/build.gradle.kts` utilise encore `namespace = "com.example.take30"` et `applicationId = "com.example.take30"`

Impact :

- Firebase ne peut pas etre configure proprement sur Android
- Google Sign-In et FCM ne pourront pas etre valides avec un package id provisoire

### 4. iOS Flutter : blocage natif

Constat :

- `take30/ios/Runner/GoogleService-Info.plist` est absent
- `take30/ios/Runner.xcodeproj/project.pbxproj` utilise encore `PRODUCT_BUNDLE_IDENTIFIER = com.example.take30`
- `take30/ios/Runner/Info.plist` n'a pas de `CFBundleURLTypes` pour Google Sign-In
- `take30/ios/Runner/AppDelegate.swift` est standard Flutter et ne montre aucun branchement notification iOS specifique

Impact :

- Firebase iOS n'est pas configure
- Google Sign-In iOS restera incomplet
- le push iOS requerra aussi APNs + capabilities Xcode

### 5. Notifications : cablage metier manquant

Constat :

- `take30/lib/services/notification_service.dart` est un stub vide
- `AndroidManifest.xml` contient deja les permissions utiles (`INTERNET`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`)

Impact :

- FCM n'est pas encore branche dans le code applicatif
- les notifications locales ou push ne sont pas encore gerees par le service

### 6. Backend API : pas de Firebase Admin

Constat :

- aucun branchement `firebase-admin` n'apparait dans `apps/api`

Impact :

- tout besoin serveur privilegie (verification d'ID token, ecriture admin, cron, moderation) reste a implementer separement

## Ce qu'il faut faire pour un cablage complet

## Etape 1 - figer les identifiants d'application

Avant de toucher Firebase, remplace les identifiants generiques :

- Android package name : remplace `com.example.take30`
- iOS bundle id : remplace `com.example.take30`

Exemple coherent :

- Android : `app.take30.mobile`
- iOS : `app.take30.mobile`

Dans ce projet, le point Android a changer est `take30/android/app/build.gradle.kts`.

Pour iOS, change le bundle identifier dans Xcode ou dans `take30/ios/Runner.xcodeproj/project.pbxproj`.

Pourquoi c'est obligatoire : Firebase enregistre chaque application par package id / bundle id exact. Si tu cables Firebase avec `com.example.take30` puis que tu changes plus tard, il faudra tout refaire.

## Etape 2 - creer ou reutiliser le projet Firebase

Le projet web existant pointe deja vers le projet Firebase `take30`.

Recommande :

- reutiliser ce meme projet Firebase si tu veux partager Auth, Firestore, Analytics et Messaging
- verifier dans Firebase Console que les apps Android et iOS n'existent pas deja avec les bons identifiants

## Etape 3 - enregistrer les apps dans Firebase Console

Dans Firebase Console > Project settings :

1. Ajoute l'app Android avec le package id final
2. Ajoute l'app iOS avec le bundle id final
3. Ajoute l'app Web Flutter si tu comptes utiliser Flutter Web en plus de la web app Vite

Pour Android si tu actives Google Sign-In :

- ajoute les empreintes SHA-1 et SHA-256

Pour iOS si tu actives FCM :

- configure APNs dans Apple Developer
- charge la cle APNs dans Firebase Console

## Etape 4 - recuperer les fichiers natifs

Place ensuite les fichiers au bon endroit :

- Android : `take30/android/app/google-services.json`
- iOS : `take30/ios/Runner/GoogleService-Info.plist`

Sans ces fichiers, le cablage natif FlutterFire ne peut pas fonctionner.

## Etape 5 - installer les outils

Commandes recommandees :

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
export PATH="$PATH:$HOME/.pub-cache/bin"
```

Depuis `take30/` :

```bash
flutter pub get
```

## Etape 6 - generer firebase_options.dart

Depuis `take30/`, lance :

```bash
flutterfire configure \
  --project=take30 \
  --platforms=android,ios,web \
  --out=lib/firebase_options.dart
```

Si besoin, force les identifiants explicitement :

```bash
flutterfire configure \
  --project=take30 \
  --platforms=android,ios,web \
  --android-package-name=app.take30.mobile \
  --ios-bundle-id=app.take30.mobile \
  --out=lib/firebase_options.dart
```

Resultat attendu :

- creation de `take30/lib/firebase_options.dart`
- verification de la coherence entre Firebase Console et tes apps locales

## Etape 7 - brancher Firebase au demarrage Flutter

Ajoute l'initialisation dans `take30/lib/main.dart` avant les autres services qui peuvent dependre de Firebase.

Exemple :

```dart
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await NotificationService().initialize();
  await ConnectivityService().initialize();

  runApp(const ProviderScope(child: Take30App()));
}
```

Ordre conseille :

- `WidgetsFlutterBinding.ensureInitialized()`
- `Firebase.initializeApp(...)`
- `FirebaseMessaging.onBackgroundMessage(...)` si tu utilises FCM
- init des services applicatifs

## Etape 8 - completer Android Gradle

Dans `take30/android/settings.gradle.kts`, ajoute le plugin Google Services :

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

Dans `take30/android/app/build.gradle.kts`, applique le plugin :

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
```

Profite-en pour remplacer :

```kotlin
namespace = "app.take30.mobile"
applicationId = "app.take30.mobile"
```

## Etape 9 - cabler Firebase Messaging proprement

`take30/lib/services/notification_service.dart` est vide aujourd'hui. Pour un vrai cablage FCM, il faut au minimum :

- demander la permission notification
- recuperer le token FCM
- ecouter `FirebaseMessaging.onMessage`
- ecouter `FirebaseMessaging.onMessageOpenedApp`
- gerer le background handler
- relayer vers `flutter_local_notifications` si tu veux afficher une notification locale en foreground

Exemple minimal :

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();

  factory NotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission();
    debugPrint('Notification permission: ${settings.authorizationStatus}');

    final token = await _messaging.getToken();
    debugPrint('FCM token: $token');

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground push: ${message.messageId}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Opened from push: ${message.messageId}');
    });
  }
}
```

Important : pour iOS, le push ne sera complet qu'apres la configuration APNs et l'activation des capabilities dans Xcode.

## Etape 10 - completer Google Sign-In

Tu as deja `firebase_auth` et `google_sign_in` dans `pubspec.yaml`, mais rien n'est branche.

Checklist Google Sign-In :

- Android : SHA-1 et SHA-256 ajoutes dans Firebase Console
- iOS : `GoogleService-Info.plist` present
- iOS : `CFBundleURLTypes` ajoute dans `Info.plist`

Exemple iOS a ajouter dans `take30/ios/Runner/Info.plist` :

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.xxxxx</string>
    </array>
  </dict>
</array>
```

La valeur a utiliser est `REVERSED_CLIENT_ID` venant de `GoogleService-Info.plist`.

## Etape 11 - clarifier la question de la cle API

### Pour Flutter mobile

La cle API est portee par :

- `google-services.json` sur Android
- `GoogleService-Info.plist` sur iOS
- `firebase_options.dart` pour l'init cross-platform

Tu ne la saisis pas a la main dans le code mobile si tu utilises FlutterFire correctement.

### Pour la web app React/Vite

La configuration actuelle est dans `apps/web/src/lib/firebase.js`.

Recommande : remplacer la config hardcodee par des variables d'environnement :

```js
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
  measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID,
};
```

Puis definir un `.env` local non committe avec ces valeurs.

Important : une cle API Firebase web n'est pas un secret serveur. Elle doit toutefois etre encadree par :

- des Firestore Rules strictes
- App Check si possible
- des restrictions d'API cote Google Cloud

## Etape 12 - validation finale

Checklist de validation :

```bash
cd take30
flutter pub get
flutter analyze
flutter run -d chrome
```

Puis selon la plateforme :

- Android physique ou emulateur Google Play pour tester Auth / FCM
- iPhone physique pour tester APNs / FCM

Verification attendue :

- l'app demarre sans erreur `[core/no-app]`
- `firebase_options.dart` est pris en compte
- `FirebaseAuth.instance` fonctionne
- le token FCM est recupere
- les notifications foreground et background arrivent

## Priorites recommandees pour ce depot

Ordre d'implementation conseille :

1. changer package id / bundle id definitifs
2. generer `firebase_options.dart`
3. ajouter les fichiers natifs Firebase
4. initialiser Firebase dans `main.dart`
5. cabler `NotificationService`
6. brancher `firebase_auth` et `google_sign_in`
7. durcir la surface web Vite avec variables d'env + rules + App Check

## Conclusion

Le web secondaire est branche a Firebase, mais l'application Flutter principale est seulement preparee au niveau dependances. Le vrai blocage n'est pas la cle API elle-meme : c'est l'absence du triptyque configuration console + fichiers natifs + initialisation FlutterFire.

Tant que ces trois couches ne sont pas faites ensemble, Firebase restera partiellement branche dans le depot.