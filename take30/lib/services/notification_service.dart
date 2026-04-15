import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();

  factory NotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'take30_high_importance',
    'Notifications Take30',
    description: 'Notifications Push pour Take30',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (kIsWeb) {
      try {
        await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        final token = await _messaging.getToken();
        debugPrint('FCM token web : $token');

        _messaging.onTokenRefresh.listen((newToken) {
          debugPrint('FCM token web rafraîchi : $newToken');
        });

        FirebaseMessaging.onMessage.listen(_onForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
      } catch (error, stackTrace) {
        debugPrint('Notification init web skipped: $error');
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'notification_service',
            context: ErrorDescription('while initializing web notifications'),
          ),
        );
      }
      return;
    }

    // Demande la permission (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission : ${settings.authorizationStatus}');

    // Init notifications locales pour affichage foreground Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Token FCM
    final token = await _messaging.getToken();
    debugPrint('FCM token : $token');

    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM token rafraîchi : $newToken');
      // TODO : envoyer newToken au backend
    });

    // Push reçu en foreground → notification locale
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // App ouverte depuis une notification (background → foreground)
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // App lancée depuis une notification terminée
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _onMessageOpenedApp(initial);
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
    // TODO : naviguer vers l'écran lié aux données du message
  }

  Future<void> showPublishSuccessNotification({required String sceneTitle}) async {
    if (kIsWeb) {
      debugPrint('Publication réussie : $sceneTitle');
      return;
    }

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
