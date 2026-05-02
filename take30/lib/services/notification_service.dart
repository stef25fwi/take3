import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../router/router.dart';
import 'api_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();

  factory NotificationService() => _instance;

  final fa.FirebaseAuth _auth = fa.FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiService _api = ApiService();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _remoteBindingsInitialized = false;
  bool _localNotificationsInitialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'take30_high_importance',
    'Notifications Take 30',
    description: 'Notifications push pour Take 30',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        return;
      }
      unawaited(_initializeForAuthenticatedUser());
    });

    if (_auth.currentUser != null) {
      await _initializeForAuthenticatedUser();
    }
  }

  Future<void> _initializeForAuthenticatedUser() async {
    try {
      await _ensureRemoteNotificationsReady();
    } catch (error, stackTrace) {
      debugPrint('Notification init skipped: $error');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'notification_service',
          context: ErrorDescription(
            'while initializing authenticated notifications',
          ),
        ),
      );
    }
  }

  Future<void> _ensureRemoteNotificationsReady() async {
    if (!kIsWeb) {
      await _ensureLocalNotificationsInitialized();
    }

    if (!_remoteBindingsInitialized) {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint(
        kIsWeb
            ? 'FCM permission web : ${settings.authorizationStatus}'
            : 'FCM permission : ${settings.authorizationStatus}',
      );

      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint(
          kIsWeb
              ? 'FCM token web rafraîchi : $newToken'
              : 'FCM token rafraîchi : $newToken',
        );
        await _syncToken(newToken);
      });

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      if (!kIsWeb) {
        final initial = await _messaging.getInitialMessage();
        if (initial != null) {
          _onMessageOpenedApp(initial);
        }
      }

      _remoteBindingsInitialized = true;
    }

    final token = await _messaging.getToken();
    debugPrint(kIsWeb ? 'FCM token web : $token' : 'FCM token : $token');
    await _syncToken(token);
  }

  Future<void> _ensureLocalNotificationsInitialized() async {
    if (_localNotificationsInitialized) {
      return;
    }

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _localNotificationsInitialized = true;
  }

  Future<void> _syncToken(String? token) async {
    final uid = _api.currentUid;
    if (uid == null || token == null || token.isEmpty) {
      return;
    }
    try {
      await _api.users.addFcmToken(uid: uid, token: token);
    } catch (error) {
      debugPrint('FCM sync skipped: $error');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('Push foreground : ${message.messageId}');

    if (kIsWeb) {
      return;
    }

    final notification = message.notification;
    final android = message.notification?.android;
    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: android.smallIcon ?? '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('App ouverte via push : ${message.data}');
    final context = appRouterNavigatorKey.currentContext;
    if (context == null) {
      return;
    }
    final data = message.data;
    final type = data['type'];
    final sceneId = data['sceneId'];
    final userId = data['userId'];

    if ((type == 'like' || type == 'comment') && sceneId is String && sceneId.isNotEmpty) {
      GoRouter.of(context).go(AppRouter.scenePath(sceneId));
      return;
    }
    if (type == 'duel') {
      GoRouter.of(context).go(AppRouter.battle);
      return;
    }
    if (type == 'achievement') {
      GoRouter.of(context).go(AppRouter.badges);
      return;
    }
    if (type == 'follow' && userId is String && userId.isNotEmpty) {
      GoRouter.of(context).go(AppRouter.profilePath(userId));
      return;
    }
    GoRouter.of(context).go(AppRouter.notifications);
  }

  Future<void> showPublishSuccessNotification({required String sceneTitle}) async {
    if (kIsWeb) {
      debugPrint('Publication réussie : $sceneTitle');
      return;
    }

    await _ensureLocalNotificationsInitialized();

    await _localNotifications.show(
      sceneTitle.hashCode,
      'Scène publiée !',
      '"$sceneTitle" est maintenant en ligne.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
