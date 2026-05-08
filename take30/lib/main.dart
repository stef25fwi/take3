import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/providers.dart';
import 'router/router.dart';
import 'services/connectivity_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

/// Handler background FCM — doit être au niveau top-level (hors de toute classe).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}


const bool _kAppCheckEnabled = bool.fromEnvironment(
  'APP_CHECK_ENABLED',
  defaultValue: kReleaseMode,
);

const String _kAppCheckRecaptchaSiteKey = String.fromEnvironment(
  'APP_CHECK_RECAPTCHA_SITE_KEY',
  defaultValue: '',
);

const bool _kUseFirebaseEmulators = bool.fromEnvironment(
  'USE_FIREBASE_EMULATORS',
  defaultValue: false,
);

String _requiredRecaptchaSiteKey() {
  final key = _kAppCheckRecaptchaSiteKey.trim();
  if (key.isEmpty) {
    throw StateError(
      'APP_CHECK_RECAPTCHA_SITE_KEY est obligatoire sur Web quand App Check est activé.',
    );
  }
  return key;
}

Future<void> _activateAppCheckIfNeeded() async {
  if (!_kAppCheckEnabled) {
    debugPrint('⚠️ App Check désactivé par APP_CHECK_ENABLED=false');
    return;
  }

  if (_kUseFirebaseEmulators) {
    debugPrint('ℹ️ App Check ignoré en mode émulateurs Firebase.');
    return;
  }

  await FirebaseAppCheck.instance.activate(
    webProvider:
        kIsWeb ? ReCaptchaV3Provider(_requiredRecaptchaSiteKey()) : null,
    androidProvider:
        kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
    appleProvider: kReleaseMode
        ? AppleProvider.appAttestWithDeviceCheckFallback
        : AppleProvider.debug,
  );

  debugPrint('✅ Firebase App Check activé');
}

String _emulatorHost() {
  if (!kIsWeb) {
    return 'localhost';
  }

  final host = Uri.base.host;
  if (host.isEmpty || host == '0.0.0.0') {
    return 'localhost';
  }
  return host;
}

Future<void> _maybeConnectEmulators() async {
  if (!_kUseFirebaseEmulators) return;
  final host = _emulatorHost();
  try {
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFunctions.instanceFor(region: 'europe-west1')
        .useFunctionsEmulator(host, 5001);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
    debugPrint('✅ Firebase emulators connected @$host');
  } catch (e) {
    debugPrint('⚠️ Failed to connect emulators: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _activateAppCheckIfNeeded();
  await _maybeConnectEmulators();
  final prefs = await SharedPreferences.getInstance();
  final initialThemeMode = ThemeModeNotifier.initialModeFromPrefs(prefs);

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  AppTheme.syncSystemUiForMode(initialThemeMode);

  await NotificationService().initialize();
  await ConnectivityService().initialize();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const Take30App(),
    ),
  );
}

class Take30App extends ConsumerWidget {
  const Take30App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isOnline = ref.watch(connectivityProvider).isOnline;
    final themeMode = ref.watch(themeModeProvider);

    AppTheme.syncSystemUiForMode(themeMode);

    return MaterialApp.router(
      key: const Key('take30_app_root'),
      debugShowCheckedModeBanner: false,
      title: 'Take 60',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => Column(
        children: [
          if (!isOnline) ConnectivityService.offlineBanner(),
          Expanded(child: child ?? const SizedBox()),
        ],
      ),
    );
  }
}
