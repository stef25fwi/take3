class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();

  factory NotificationService() => _instance;

  Future<void> initialize() async {}

  Future<void> showPublishSuccessNotification({required String sceneTitle}) async {}
}