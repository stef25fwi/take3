import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

const bool _kUseFirebaseEmulators = bool.fromEnvironment(
  'USE_FIREBASE_EMULATORS',
  defaultValue: false,
);

Future<void> _maybeConnectEmulators() async {
  if (!_kUseFirebaseEmulators) return;
  const host = 'localhost';
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
  await _maybeConnectEmulators();

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.dark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await NotificationService().initialize();
  await ConnectivityService().initialize();

  runApp(const ProviderScope(child: Take30App()));
}

class Take30App extends ConsumerWidget {
  const Take30App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isOnline = ref.watch(connectivityProvider).isOnline;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Take 60',
      theme: AppTheme.darkTheme,
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
