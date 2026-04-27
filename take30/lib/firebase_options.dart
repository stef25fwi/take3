// Généré par FlutterFire CLI / complété manuellement.
// Ce fichier doit être régénéré via :
//   flutterfire configure --project=take30 --platforms=android,ios,web
//
// Ils seront remplacés automatiquement quand tu lanceras flutterfire configure
// après avoir déclaré les apps Android et iOS dans Firebase Console.
// La configuration web et les IDs de sender/projet sont déjà corrects.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions non configuré pour cette plateforme : '
          '$defaultTargetPlatform',
        );
    }
  }

  // ─── Web (Vite React) + Flutter Web ────────────────────────────────────────

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBM6Wr064fmsyElN6cZEF5irLqlctcxHqc',
    appId: '1:803573468710:web:3aef887be4785feb39a0e7',
    messagingSenderId: '803573468710',
    projectId: 'take30',
    authDomain: 'take30.firebaseapp.com',
    storageBucket: 'take30.firebasestorage.app',
    measurementId: 'G-49LBD56KLW',
  );

  // Identique à la config dans apps/web/src/lib/firebase.js.

  // ─── Android ───────────────────────────────────────────────────────────────
  // TODO : déclare l'app Android dans Firebase Console, télécharge
  // google-services.json → take30/android/app/google-services.json,
  // pour l'application `app.take30`, puis lance `flutterfire configure`

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBMGwRTE9CCBIG0cB7Ted1LftzYPjEk6l8',
    appId: '1:803573468710:android:ce9222631b588d1939a0e7',
    messagingSenderId: '803573468710',
    projectId: 'take30',
    storageBucket: 'take30.firebasestorage.app',
  );

  
  // ─── iOS ───────────────────────────────────────────────────────────────────
  // TODO : déclare l'app iOS dans Firebase Console, télécharge
  // GoogleService-Info.plist → take30/ios/Runner/GoogleService-Info.plist,
  // pour le bundle `app.take30`, puis lance `flutterfire configure`

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBBt-gGlN4R02VP1MfKo-IP8wXynqGPTHc',
    appId: '1:803573468710:ios:6e4b37c4744f651739a0e7',
    messagingSenderId: '803573468710',
    projectId: 'take30',
    storageBucket: 'take30.firebasestorage.app',
    iosClientId: '803573468710-6oq2cjuqv2hfj2h6o2a40e1btaq4a3c0.apps.googleusercontent.com',
    iosBundleId: 'app.take30',
  );

  // pour remplacer les valeurs ci-dessous.
}