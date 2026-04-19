// Généré par FlutterFire CLI / complété manuellement.
// Ce fichier doit être régénéré via :
//   flutterfire configure --project=take30 --platforms=android,ios,web
//
// Les appId Android et iOS ci-dessous sont des PLACEHOLDERS.
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
  // Identique à la config dans apps/web/src/lib/firebase.js.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBM6Wr064fmsyElN6cZEF5irLqlctcxHqc',
    authDomain: 'take30.firebaseapp.com',
    projectId: 'take30',
    storageBucket: 'take30.firebasestorage.app',
    messagingSenderId: '803573468710',
    appId: '1:803573468710:web:3aef887be4785feb39a0e7',
    measurementId: 'G-49LBD56KLW',
  );

  // ─── Android ───────────────────────────────────────────────────────────────
  // TODO : déclare l'app Android dans Firebase Console, télécharge
  // google-services.json → take30/android/app/google-services.json,
  // pour l'application `app.take30`, puis lance `flutterfire configure`
  // pour remplacer l'appId ci-dessous.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBM6Wr064fmsyElN6cZEF5irLqlctcxHqc',
    projectId: 'take30',
    storageBucket: 'take30.firebasestorage.app',
    messagingSenderId: '803573468710',
    // Placeholder — remplace par l'appId Firebase Android réel.
    appId: '1:803573468710:android:REMPLACE_MOI',
  );

  // ─── iOS ───────────────────────────────────────────────────────────────────
  // TODO : déclare l'app iOS dans Firebase Console, télécharge
  // GoogleService-Info.plist → take30/ios/Runner/GoogleService-Info.plist,
  // pour le bundle `app.take30`, puis lance `flutterfire configure`
  // pour remplacer les valeurs ci-dessous.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBM6Wr064fmsyElN6cZEF5irLqlctcxHqc',
    projectId: 'take30',
    storageBucket: 'take30.firebasestorage.app',
    messagingSenderId: '803573468710',
    // Placeholder — remplace par l'appId Firebase iOS réel.
    appId: '1:803573468710:ios:REMPLACE_MOI',
    // iosClientId vient de REVERSED_CLIENT_ID dans GoogleService-Info.plist.
    // Nécessaire pour Google Sign-In iOS.
    iosClientId: null,
    iosBundleId: 'app.take30',
  );
}
