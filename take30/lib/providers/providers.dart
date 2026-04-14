import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/camera_service.dart';
import '../services/connectivity_service.dart';
import '../services/haptics_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../services/share_service.dart';
import '../services/upload_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final authServiceProvider = ChangeNotifierProvider<AuthService>(
  (ref) => AuthService(),
);

final cameraServiceProvider = ChangeNotifierProvider<CameraService>(
  (ref) => CameraService(),
);

final uploadServiceProvider = ChangeNotifierProvider<VideoUploadService>(
  (ref) => VideoUploadService(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final shareServiceProvider = Provider<ShareService>((ref) => ShareService());

final hapticsProvider = Provider<HapticsService>((ref) => HapticsService());

final permissionProvider = Provider<PermissionService>((ref) => PermissionService());

final connectivityProvider = ChangeNotifierProvider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

final dashboardProvider = FutureProvider<List<FeatureItem>>(
  (ref) => ref.read(apiServiceProvider).fetchDashboard(),
);

final exploreCategoryProvider = StateProvider<String>((ref) => 'all');

final categoriesProvider = FutureProvider<List<CategoryModel>>(
  (ref) => ref.read(apiServiceProvider).getCategories(),
);

final exploreScenesProvider = FutureProvider<List<SceneModel>>((ref) {
  final category = ref.watch(exploreCategoryProvider);
  return ref.read(apiServiceProvider).getPopularScenes(category);
});

final notificationsProvider = FutureProvider<List<NotificationModel>>(
  (ref) => ref.read(apiServiceProvider).getNotifications(),
);

final dailyChallengeProvider = FutureProvider<DailyChallengeModel>(
  (ref) => ref.read(apiServiceProvider).getDailyChallenge(),
);

final leaderboardPeriodProvider = StateProvider<String>((ref) => 'week');

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  final period = ref.watch(leaderboardPeriodProvider);
  return ref.read(apiServiceProvider).getLeaderboard(period);
});

final currentProfileIdProvider = StateProvider<String>((ref) => 'u1');

final profileProvider = FutureProvider<UserModel>((ref) {
  final userId = ref.watch(currentProfileIdProvider);
  return ref.read(apiServiceProvider).getProfile(userId);
});

final profileScenesProvider = FutureProvider<List<SceneModel>>((ref) {
  final userId = ref.watch(currentProfileIdProvider);
  return ref.read(apiServiceProvider).getUserScenes(userId);
});

final profileBadgesProvider = FutureProvider<List<BadgeModel>>((ref) {
  final userId = ref.watch(currentProfileIdProvider);
  return ref.read(apiServiceProvider).getBadges(userId);
});

class DuelNotifier extends StateNotifier<AsyncValue<DuelModel>> {
  DuelNotifier(this._api) : super(const AsyncLoading()) {
    load();
  }

  final ApiService _api;

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_api.getCurrentDuel);
  }

  Future<void> vote(int choice) async {
    final duel = state.valueOrNull;
    if (duel == null || duel.userVote != null) {
      return;
    }
    state = await AsyncValue.guard(() => _api.vote(duel.id, choice));
  }
}

final duelProvider = StateNotifierProvider<DuelNotifier, AsyncValue<DuelModel>>(
  (ref) => DuelNotifier(ref.read(apiServiceProvider)),
);
