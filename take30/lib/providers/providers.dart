import 'package:flutter/material.dart';
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
import '../utils/assets.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) => AuthService());
final cameraServiceProvider = ChangeNotifierProvider<CameraService>((ref) => CameraService());
final uploadServiceProvider = ChangeNotifierProvider<VideoUploadService>((ref) => VideoUploadService());
final notifServiceProvider = Provider<NotificationService>((ref) => NotificationService());
final notificationServiceProvider = notifServiceProvider;
final shareServiceProvider = Provider<ShareService>((ref) => ShareService());
final hapticsProvider = Provider<HapticsService>((ref) => HapticsService());
final connectivityProvider = ChangeNotifierProvider<ConnectivityService>((ref) => ConnectivityService());
final permissionProvider = Provider<PermissionService>((ref) => PermissionService());

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._auth) : super(const AuthState()) {
    _init();
  }

  final AuthService _auth;

  Future<void> _init() async {
    await _auth.checkPersistedAuth();
    final user = _auth.currentUser;
    if (user != null) {
      state = state.copyWith(user: user, isAuthenticated: true);
    }
  }

  Future<void> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _auth.loginWithIdentifier(
      identifier: identifier,
      password: password,
    );
    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        user: result.user,
        isAuthenticated: true,
        error: null,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  Future<void> loginDemo() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _auth.loginDemo();
    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        user: result.user,
        isAuthenticated: true,
        error: null,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  Future<void> register(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _auth.registerWithEmail(
      username: username,
      email: email,
      password: password,
    );
    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        user: result.user,
        isAuthenticated: true,
        error: null,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _auth.loginWithGoogle();
    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        user: result.user,
        isAuthenticated: true,
        error: null,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  Future<void> loginWithApple() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _auth.loginWithApple();
    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        user: result.user,
        isAuthenticated: true,
        error: null,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? error;

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);

class FeedNotifier extends StateNotifier<FeedState> {
  static const String _demoEmail = 'demo@take30.app';
  static const String _demoUsername = 'demo_take30';
  static const String _demoDisplayName = 'Mode Demo';

  FeedNotifier(this._api, this._haptics) : super(const FeedState()) {
    loadFeed();
  }

  final ApiService _api;
  final HapticsService _haptics;

  Future<void> loadFeed({bool refresh = false}) async {
    if (_isDemoMode) {
      state = FeedState(
        isLoading: false,
        scenes: _buildDemoFeed(),
      );
      return;
    }

    if (refresh) {
      state = const FeedState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true);
    }

    try {
      final scenes = await _api.getFeed();
      state = state.copyWith(isLoading: false, scenes: scenes, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleLike(String sceneId) async {
    await _haptics.like();
    final scenes = state.scenes.map((scene) {
      if (scene.id == sceneId) {
        return scene.copyWith(
          isLiked: !scene.isLiked,
          likesCount: scene.isLiked ? scene.likesCount - 1 : scene.likesCount + 1,
        );
      }
      return scene;
    }).toList();
    state = state.copyWith(scenes: scenes);
    if (_isDemoMode) {
      return;
    }
    await _api.likeScene(sceneId);
  }

  void refresh() {
    loadFeed(refresh: true);
  }

  bool get _isDemoMode {
    final user = _api.currentUser;
    if (user == null) {
      return false;
    }

    return user.username == _demoUsername ||
        user.displayName == _demoDisplayName ||
        user.email == _demoEmail;
  }

  List<SceneModel> _buildDemoFeed() {
    final now = DateTime.now();
    final currentUser = _api.currentUser ??
        UserModel(
          id: 'demo_local',
          username: _demoUsername,
          displayName: _demoDisplayName,
          avatarUrl: Take30Assets.avatarCurrentUser,
          email: _demoEmail,
          isVerified: true,
          scenesCount: 3,
          likesCount: 128,
          createdAt: now,
        );

    final guestA = UserModel(
      id: 'u_demo_feed_a',
      username: 'LunaScene',
      displayName: 'Luna Scene',
      avatarUrl: 'assets/avatars/avatar_ia_female_alt.webp',
      isVerified: true,
      createdAt: now.subtract(const Duration(days: 3)),
    );

    final guestB = UserModel(
      id: 'u_demo_feed_b',
      username: 'MaxShot',
      displayName: 'Max Shot',
      avatarUrl: 'assets/avatars/avatar_ia_male_lead.webp',
      isVerified: true,
      createdAt: now.subtract(const Duration(days: 4)),
    );

    return [
      SceneModel(
        id: 's_demo_feed_1',
        title: 'Clash émotionnel en 30 secondes',
        category: 'drama',
        thumbnailUrl: 'assets/scenes/battle_player_a.png',
        durationSeconds: 30,
        likesCount: 184,
        commentsCount: 23,
        sharesCount: 9,
        viewsCount: 3200,
        author: guestA,
        createdAt: now.subtract(const Duration(hours: 2)),
        tags: const ['demo', 'drama', 'battle'],
      ),
      SceneModel(
        id: 's_demo_feed_2',
        title: 'Réplique culte, version face cam',
        category: 'comedy',
        thumbnailUrl: 'assets/scenes/battle_player_b.png',
        durationSeconds: 30,
        likesCount: 172,
        commentsCount: 19,
        sharesCount: 11,
        viewsCount: 2980,
        author: guestB,
        createdAt: now.subtract(const Duration(hours: 3)),
        tags: const ['demo', 'comedy', 'viral'],
      ),
      SceneModel(
        id: 's_demo_feed_3',
        title: 'Ton premier take peut déjà percer',
        category: 'spotlight',
        thumbnailUrl: 'assets/avatars/avatar_ia_female_lead.webp',
        durationSeconds: 30,
        likesCount: 96,
        commentsCount: 12,
        sharesCount: 5,
        viewsCount: 1540,
        author: currentUser,
        createdAt: now.subtract(const Duration(minutes: 40)),
        tags: const ['demo', 'starter', 'spotlight'],
      ),
    ];
  }
}

class FeedState {
  const FeedState({
    this.isLoading = false,
    this.scenes = const [],
    this.error,
  });

  final bool isLoading;
  final List<SceneModel> scenes;
  final String? error;

  FeedState copyWith({
    bool? isLoading,
    List<SceneModel>? scenes,
    String? error,
  }) {
    return FeedState(
      isLoading: isLoading ?? this.isLoading,
      scenes: scenes ?? this.scenes,
      error: error,
    );
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>(
  (ref) => FeedNotifier(ref.read(apiServiceProvider), ref.read(hapticsProvider)),
);

final sceneProvider = StreamProvider.family<SceneModel?, String>((ref, sceneId) {
  final api = ref.watch(apiServiceProvider);
  return api.scenes.watchById(sceneId);
});

final sceneCommentsProvider =
    StreamProvider.family<List<CommentModel>, String>((ref, sceneId) {
  final api = ref.watch(apiServiceProvider);
  return api.comments.watch(sceneId);
});

class RecordingNotifier extends StateNotifier<RecordingState> {
  RecordingNotifier(
    this._camera,
    this._upload,
    this._haptics,
    this._notifications,
    this._permissions,
  ) : super(const RecordingState());

  final CameraService _camera;
  final VideoUploadService _upload;
  final HapticsService _haptics;
  final NotificationService _notifications;
  final PermissionService _permissions;

  Future<bool> initCamera(BuildContext context) async {
    final granted = await _permissions.requestWithExplanation(
      context,
      AppPermission.camera,
      title: 'Caméra requise',
      message: 'Take 60 a besoin de ta caméra pour enregistrer tes performances.',
    );
    if (!granted) {
      return false;
    }

    if (!context.mounted) {
      return false;
    }

    await _permissions.requestWithExplanation(
      context,
      AppPermission.microphone,
      title: 'Micro requis',
      message: 'Take 60 a besoin du microphone pour capturer le son.',
    );

    final ready = await _camera.initialize();
    state = state.copyWith(cameraReady: ready);
    return ready;
  }

  Future<void> startRecording() async {
    await _haptics.recordStart();
    await _camera.startRecording();
    state = state.copyWith(isRecording: true, elapsed: 0);
  }

  Future<String?> stopRecording() async {
    await _haptics.recordStop();
    final result = await _camera.stopRecording();
    if (result != null) {
      state = state.copyWith(
        isRecording: false,
        recordedPath: result.filePath,
        elapsed: result.durationSeconds,
      );
    }
    return result?.filePath;
  }

  void flipCamera() {
    _camera.flipCamera();
  }

  void setScene(SceneModel scene) {
    state = state.copyWith(scene: scene);
  }

  Future<SceneModel?> publishScene({
    required String title,
    required String category,
    required List<String> tags,
  }) async {
    if (state.recordedPath == null) {
      return null;
    }

    final scene = await _upload.uploadScene(
      videoPath: state.recordedPath!,
      title: title,
      category: category,
      authorId: 'u1',
      tags: tags,
    );

    if (scene != null) {
      await _haptics.success();
      await _notifications.showPublishSuccessNotification(sceneTitle: title);
    }

    return scene;
  }

  void reset() {
    _camera.resetForNewRecording();
    _upload.reset();
    state = const RecordingState();
  }
}

class RecordingState {
  const RecordingState({
    this.isRecording = false,
    this.cameraReady = false,
    this.elapsed = 0,
    this.recordedPath,
    this.scene,
  });

  final bool isRecording;
  final bool cameraReady;
  final int elapsed;
  final String? recordedPath;
  final SceneModel? scene;

  RecordingState copyWith({
    bool? isRecording,
    bool? cameraReady,
    int? elapsed,
    String? recordedPath,
    SceneModel? scene,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      cameraReady: cameraReady ?? this.cameraReady,
      elapsed: elapsed ?? this.elapsed,
      recordedPath: recordedPath ?? this.recordedPath,
      scene: scene ?? this.scene,
    );
  }
}

final recordingProvider = StateNotifierProvider<RecordingNotifier, RecordingState>(
  (ref) => RecordingNotifier(
    ref.read(cameraServiceProvider),
    ref.read(uploadServiceProvider),
    ref.read(hapticsProvider),
    ref.read(notifServiceProvider),
    ref.read(permissionProvider),
  ),
);

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  LeaderboardNotifier(this._api, this._haptics) : super(const LeaderboardState()) {
    load('day');
  }

  final ApiService _api;
  final HapticsService _haptics;

  Future<void> load(String period) async {
    await _haptics.selection();

    if (_isDemoUser(_api.currentUser)) {
      state = state.copyWith(
        isLoading: false,
        period: period,
        entries: _buildDemoLeaderboard(period),
      );
      return;
    }

    state = state.copyWith(isLoading: true, period: period);
    try {
      final entries = await _api.getLeaderboard(period);
      state = state.copyWith(isLoading: false, entries: entries);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  List<LeaderboardEntry> _buildDemoLeaderboard(String period) {
    final currentUser = _api.currentUser ??
        UserModel(
          id: 'demo_local',
          username: 'demo_take30',
          displayName: 'Mode Demo',
          avatarUrl: Take30Assets.avatarCurrentUser,
          email: 'demo@take30.app',
          isVerified: true,
          followersCount: 124,
          createdAt: DateTime.now(),
        );

    final topThree = switch (period) {
      'day' => [
            const LeaderboardEntry(
            rank: 1,
            user: UserModel(
              id: 'u_rank_day_1',
              username: 'LunaScene',
              displayName: 'Luna Scene',
              avatarUrl: 'assets/avatars/avatar_ia_female_alt.webp',
              isVerified: true,
              followersCount: 1820,
            ),
            score: 9820,
            scoreLabel: '9.8K pts',
          ),
          const LeaderboardEntry(
            rank: 2,
            user: UserModel(
              id: 'u_rank_day_2',
              username: 'ModeDemo',
              displayName: 'Mode Demo',
              avatarUrl: Take30Assets.avatarCurrentUser,
              email: 'demo@take30.app',
              isVerified: true,
              followersCount: 124,
            ),
            score: 8640,
            scoreLabel: '8.6K pts',
          ),
          const LeaderboardEntry(
            rank: 3,
            user: UserModel(
              id: 'u_rank_day_3',
              username: 'MaxShot',
              displayName: 'Max Shot',
              avatarUrl: 'assets/avatars/avatar_ia_male_lead.webp',
              isVerified: true,
              followersCount: 1540,
            ),
            score: 7990,
            scoreLabel: '8.0K pts',
          ),
        ],
      'week' => [
          const LeaderboardEntry(
            rank: 1,
            user: UserModel(
              id: 'u_rank_week_1',
              username: 'NoraAct',
              displayName: 'Nora Act',
              avatarUrl: 'assets/avatars/avatar_ia_female_lead.webp',
              isVerified: true,
              followersCount: 4200,
            ),
            score: 32400,
            scoreLabel: '32.4K pts',
          ),
          LeaderboardEntry(
            rank: 2,
            user: currentUser,
            score: 28750,
            scoreLabel: '28.8K pts',
          ),
          const LeaderboardEntry(
            rank: 3,
            user: UserModel(
              id: 'u_rank_week_3',
              username: 'LeoFrame',
              displayName: 'Leo Frame',
              avatarUrl: 'assets/avatars/avatar_ia_male_lead.webp',
              isVerified: true,
              followersCount: 3610,
            ),
            score: 25110,
            scoreLabel: '25.1K pts',
          ),
        ],
      'month' => [
          const LeaderboardEntry(
            rank: 1,
            user: UserModel(
              id: 'u_rank_month_1',
              username: 'StarLuna',
              displayName: 'Star Luna',
              avatarUrl: 'assets/avatars/avatar_ia_female_alt.webp',
              isVerified: true,
              followersCount: 9200,
            ),
            score: 118000,
            scoreLabel: '118K pts',
          ),
          const LeaderboardEntry(
            rank: 2,
            user: UserModel(
              id: 'u_rank_month_2',
              username: 'ModeDemo',
              displayName: 'Mode Demo',
              avatarUrl: Take30Assets.avatarCurrentUser,
              email: 'demo@take30.app',
              isVerified: true,
              followersCount: 124,
            ),
            score: 109500,
            scoreLabel: '109.5K pts',
          ),
          const LeaderboardEntry(
            rank: 3,
            user: UserModel(
              id: 'u_rank_month_3',
              username: 'KaiLine',
              displayName: 'Kai Line',
              avatarUrl: 'assets/avatars/avatar_ia_male_lead.webp',
              isVerified: true,
              followersCount: 8100,
            ),
            score: 104200,
            scoreLabel: '104.2K pts',
          ),
        ],
      _ => [
          const LeaderboardEntry(
            rank: 1,
            user: UserModel(
              id: 'u_rank_global_1',
              username: 'IrisPrime',
              displayName: 'Iris Prime',
              avatarUrl: 'assets/avatars/avatar_ia_female_lead.webp',
              isVerified: true,
              followersCount: 18400,
            ),
            score: 250000,
            scoreLabel: '250K pts',
          ),
          const LeaderboardEntry(
            rank: 2,
            user: UserModel(
              id: 'u_rank_global_2',
              username: 'ModeDemo',
              displayName: 'Mode Demo',
              avatarUrl: Take30Assets.avatarCurrentUser,
              email: 'demo@take30.app',
              isVerified: true,
              followersCount: 124,
            ),
            score: 231400,
            scoreLabel: '231.4K pts',
          ),
          const LeaderboardEntry(
            rank: 3,
            user: UserModel(
              id: 'u_rank_global_3',
              username: 'NovaClip',
              displayName: 'Nova Clip',
              avatarUrl: 'assets/avatars/avatar_ia_female_alt.webp',
              isVerified: true,
              followersCount: 16100,
            ),
            score: 226900,
            scoreLabel: '226.9K pts',
          ),
        ],
    };

    return topThree;
  }
}

class LeaderboardState {
  const LeaderboardState({
    this.isLoading = false,
    this.entries = const [],
    this.period = 'day',
  });

  final bool isLoading;
  final List<LeaderboardEntry> entries;
  final String period;

  LeaderboardState copyWith({
    bool? isLoading,
    List<LeaderboardEntry>? entries,
    String? period,
  }) {
    return LeaderboardState(
      isLoading: isLoading ?? this.isLoading,
      entries: entries ?? this.entries,
      period: period ?? this.period,
    );
  }
}

final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier, LeaderboardState>(
  (ref) => LeaderboardNotifier(ref.read(apiServiceProvider), ref.read(hapticsProvider)),
);

class DuelNotifier extends StateNotifier<DuelState> {
  static const String _demoDuelId = 'duel_demo_local';
  static const String _demoEmail = 'demo@take30.app';
  static const String _demoUsername = 'demo_take30';
  static const String _demoDisplayName = 'Mode Demo';

  DuelNotifier(this._api, this._haptics) : super(const DuelState()) {
    load();
  }

  final ApiService _api;
  final HapticsService _haptics;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final duel = await _api.getCurrentDuel();
      state = state.copyWith(
        isLoading: false,
        duel: duel ?? (_isDemoMode ? _buildDemoDuel() : null),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        duel: _isDemoMode ? _buildDemoDuel() : null,
      );
    }
  }

  Future<void> vote(int choice) async {
    if (state.duel == null) {
      return;
    }

    await _haptics.heavy();

    if (state.duel!.id == _demoDuelId) {
      final updated = state.duel!.copyWith(
        userVote: choice,
        votesA: choice == 0 ? state.duel!.votesA + 1 : state.duel!.votesA,
        votesB: choice == 1 ? state.duel!.votesB + 1 : state.duel!.votesB,
      );
      state = state.copyWith(duel: updated);
      return;
    }

    final updated = await _api.vote(state.duel!.id, choice);
    state = state.copyWith(duel: updated);
  }

  bool get _isDemoMode {
    final user = _api.currentUser;
    if (user == null) {
      return false;
    }
    return user.username == _demoUsername ||
        user.displayName == _demoDisplayName ||
        user.email == _demoEmail;
  }

  DuelModel _buildDemoDuel() {
    final now = DateTime.now();

    const authorA = UserModel(
      id: 'u_demo_a',
      username: 'LunaDemo',
      displayName: 'Luna Demo',
      avatarUrl: 'assets/scenes/battle_player_a.png',
      isVerified: true,
    );

    const authorB = UserModel(
      id: 'u_demo_b',
      username: 'MaxDemo',
      displayName: 'Max Demo',
      avatarUrl: 'assets/scenes/battle_player_b.png',
      isVerified: true,
    );

    final sceneA = SceneModel(
      id: 's_demo_battle_a',
      title: 'Take 60 — Spotlight A',
      category: 'drama',
      thumbnailUrl: 'assets/scenes/battle_player_a.png',
      durationSeconds: 30,
      likesCount: 184,
      commentsCount: 23,
      viewsCount: 3200,
      author: authorA,
      createdAt: now.subtract(const Duration(hours: 3)),
      tags: const ['battle', 'demo', 'drama'],
    );

    final sceneB = SceneModel(
      id: 's_demo_battle_b',
      title: 'Take 60 — Spotlight B',
      category: 'comedy',
      thumbnailUrl: 'assets/scenes/battle_player_b.png',
      durationSeconds: 30,
      likesCount: 172,
      commentsCount: 19,
      viewsCount: 2980,
      author: authorB,
      createdAt: now.subtract(const Duration(hours: 2)),
      tags: const ['battle', 'demo', 'comedy'],
    );

    return DuelModel(
      id: _demoDuelId,
      sceneA: sceneA,
      sceneB: sceneB,
      votesA: 42,
      votesB: 39,
      expiresAt: now.add(const Duration(hours: 12)),
      status: 'active',
    );
  }
}

class DuelState {
  const DuelState({this.isLoading = false, this.duel});

  final bool isLoading;
  final DuelModel? duel;

  DuelState copyWith({bool? isLoading, DuelModel? duel}) {
    return DuelState(
      isLoading: isLoading ?? this.isLoading,
      duel: duel ?? this.duel,
    );
  }
}

final duelProvider = StateNotifierProvider<DuelNotifier, DuelState>(
  (ref) => DuelNotifier(
    ref.read(apiServiceProvider),
    ref.read(hapticsProvider),
  ),
);

class DemoNotificationsNotifier extends StateNotifier<List<NotificationModel>> {
  DemoNotificationsNotifier() : super(const []);

  void resetForUser(UserModel? user) {
    state = _isDemoUser(user) ? _buildDemoNotifications() : const [];
  }

  void markRead(String notificationId) {
    state = [
      for (final notification in state)
        if (notification.id == notificationId)
          NotificationModel(
            id: notification.id,
            message: notification.message,
            subMessage: notification.subMessage,
            type: notification.type,
            time: notification.time,
            isRead: true,
            avatarUrl: notification.avatarUrl,
            sceneId: notification.sceneId,
            userId: notification.userId,
          )
        else
          notification,
    ];
  }

  void markAllRead() {
    state = [
      for (final notification in state)
        NotificationModel(
          id: notification.id,
          message: notification.message,
          subMessage: notification.subMessage,
          type: notification.type,
          time: notification.time,
          isRead: true,
          avatarUrl: notification.avatarUrl,
          sceneId: notification.sceneId,
          userId: notification.userId,
        ),
    ];
  }
}

List<NotificationModel> _buildDemoNotifications() {
  final now = DateTime.now();
  return [
    NotificationModel(
      id: 'n_demo_duel',
      message: 'Ta battle démo est prête',
      subMessage: 'Vote maintenant pour voir le duel Take 60 en action.',
      type: NotificationType.duel,
      time: now.subtract(const Duration(minutes: 2)),
      avatarUrl: 'assets/scenes/battle_player_a.png',
    ),
    NotificationModel(
      id: 'n_demo_badge',
      message: 'Un badge premium t\'attend',
      subMessage: 'Découvre tes récompenses et stats dans l\'espace badges.',
      type: NotificationType.achievement,
      time: now.subtract(const Duration(minutes: 18)),
      isRead: true,
      avatarUrl: Take30Assets.avatarCurrentUser,
    ),
    NotificationModel(
      id: 'n_demo_system',
      message: 'Mode démo activé',
      subMessage: 'Explore l\'application instantanément sans attendre le réseau.',
      type: NotificationType.system,
      time: now.subtract(const Duration(minutes: 35)),
      avatarUrl: Take30Assets.avatarCurrentUser,
    ),
  ];
}

final demoNotificationsProvider =
    StateNotifierProvider<DemoNotificationsNotifier, List<NotificationModel>>(
  (ref) {
    final notifier = DemoNotificationsNotifier();
    notifier.resetForUser(ref.read(authProvider).user);
    ref.listen<UserModel?>(
      authProvider.select((state) => state.user),
      (_, next) => notifier.resetForUser(next),
    );
    return notifier;
  },
);

final _liveNotificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) async* {
  final api = ref.watch(apiServiceProvider);
  final uid = api.currentUid;
  if (uid == null) {
    yield const <NotificationModel>[];
    return;
  }
  yield* api.notifications.watchForUser(uid);
});

final notificationsProvider = Provider<AsyncValue<List<NotificationModel>>>((ref) {
  final authUser = ref.watch(authProvider.select((state) => state.user));
  if (_isDemoUser(authUser)) {
    return AsyncValue.data(ref.watch(demoNotificationsProvider));
  }
  return ref.watch(_liveNotificationsProvider);
});

final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.when(
    data: (items) => items.where((item) => !item.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

bool _isDemoUser(UserModel? user) {
  if (user == null) {
    return false;
  }

  return user.username == 'demo_take30' ||
      user.displayName == 'Mode Demo' ||
      user.email == 'demo@take30.app';
}

DailyChallengeModel _buildDemoDailyChallenge() {
  final now = DateTime.now();
  return DailyChallengeModel(
    id: 'daily_demo_local',
    sceneTitle: 'Confrontation sous pression',
    quote: 'Tu n\'as plus d\'excuse. Regarde-moi et dis enfin la vérité.',
    maxSeconds: 30,
    thumbnailUrl: 'assets/scenes/daily_challenge_spotlight.svg',
    rules: const [
      '30 secondes max',
      'Une intention forte dès la première seconde',
      'Publie ta vidéo pour entrer dans le classement',
    ],
    expiresAt: now.add(const Duration(hours: 12)),
    participantsCount: 128,
  );
}

final dailyChallengeProvider =
    StreamProvider<DailyChallengeModel?>((ref) async* {
  final authUser = ref.watch(authProvider.select((state) => state.user));
  if (_isDemoUser(authUser)) {
    yield _buildDemoDailyChallenge();
    return;
  }

  final api = ref.watch(apiServiceProvider);
  yield* api.dailyChallenge.watchToday();
});

UserModel _buildDemoProfileUser(String userId, UserModel? currentUser) {
  final now = DateTime.now();

  UserModel buildUser({
    required String id,
    required String username,
    required String displayName,
    required String avatarUrl,
    String? email,
    required String bio,
    required int scenesCount,
    required int followersCount,
    required int likesCount,
    required int totalViews,
    required double approvalRate,
    required int sharesCount,
    bool isFollowing = false,
  }) {
    return UserModel(
      id: id,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      email: email,
      bio: bio,
      isVerified: true,
      scenesCount: scenesCount,
      followersCount: followersCount,
      likesCount: likesCount,
      totalViews: totalViews,
      approvalRate: approvalRate,
      sharesCount: sharesCount,
      isFollowing: isFollowing,
      createdAt: now.subtract(const Duration(days: 5)),
      lastActiveAt: now.subtract(const Duration(minutes: 8)),
    );
  }

  if (currentUser != null && _isDemoUser(currentUser) && currentUser.id == userId) {
    return buildUser(
      id: currentUser.id,
      username: currentUser.username,
      displayName: currentUser.displayName,
      avatarUrl: currentUser.avatarUrl,
      email: currentUser.email,
      bio: 'Tu explores Take 30 en mode démo avec un profil instantané.',
      scenesCount: 3,
      followersCount: 124,
      likesCount: 418,
      totalViews: 12600,
      approvalRate: 92,
      sharesCount: 18,
    );
  }

  switch (userId) {
    case 'u_demo_feed_a':
    case 'u_rank_day_1':
      return buildUser(
        id: userId,
        username: 'LunaScene',
        displayName: 'Luna Scene',
        avatarUrl: Take30Assets.avatarIaFemaleAlt,
        bio: 'Spécialiste des répliques tendues et des regards qui claquent.',
        scenesCount: 6,
        followersCount: 1820,
        likesCount: 9420,
        totalViews: 58400,
        approvalRate: 96,
        sharesCount: 210,
      );
    case 'u_demo_feed_b':
    case 'u_rank_day_3':
      return buildUser(
        id: userId,
        username: 'MaxShot',
        displayName: 'Max Shot',
        avatarUrl: Take30Assets.avatarIaMaleLead,
        bio: 'Punchlines rapides, énergie caméra et timing comédie.',
        scenesCount: 5,
        followersCount: 1540,
        likesCount: 7210,
        totalViews: 47100,
        approvalRate: 93,
        sharesCount: 154,
      );
    case 'u_rank_week_1':
      return buildUser(
        id: userId,
        username: 'NoraAct',
        displayName: 'Nora Act',
        avatarUrl: Take30Assets.avatarIaFemaleLead,
        bio: 'Jeu intense, précision émotionnelle, zéro temps mort.',
        scenesCount: 8,
        followersCount: 4200,
        likesCount: 18300,
        totalViews: 99400,
        approvalRate: 97,
        sharesCount: 332,
      );
    case 'u_rank_week_3':
      return buildUser(
        id: userId,
        username: 'LeoFrame',
        displayName: 'Leo Frame',
        avatarUrl: Take30Assets.avatarIaMaleLead,
        bio: 'Cadre, respiration, montée en tension: chaque seconde compte.',
        scenesCount: 7,
        followersCount: 3610,
        likesCount: 15980,
        totalViews: 86100,
        approvalRate: 95,
        sharesCount: 284,
      );
    case 'u_rank_month_1':
      return buildUser(
        id: userId,
        username: 'StarLuna',
        displayName: 'Star Luna',
        avatarUrl: Take30Assets.avatarIaFemaleAlt,
        bio: 'Talent régulier, présence premium et takes ultra mémorables.',
        scenesCount: 12,
        followersCount: 9200,
        likesCount: 42800,
        totalViews: 188000,
        approvalRate: 98,
        sharesCount: 610,
      );
    case 'u_rank_month_3':
      return buildUser(
        id: userId,
        username: 'KaiLine',
        displayName: 'Kai Line',
        avatarUrl: Take30Assets.avatarIaMaleLead,
        bio: 'Interprétation propre, rythme sec, impact immédiat.',
        scenesCount: 10,
        followersCount: 8100,
        likesCount: 36600,
        totalViews: 164000,
        approvalRate: 96,
        sharesCount: 540,
      );
    case 'u_rank_global_1':
      return buildUser(
        id: userId,
        username: 'IrisPrime',
        displayName: 'Iris Prime',
        avatarUrl: Take30Assets.avatarIaFemaleLead,
        bio: 'Top créatrice Take 30, connue pour ses scènes ultra nettes.',
        scenesCount: 18,
        followersCount: 18400,
        likesCount: 76200,
        totalViews: 326000,
        approvalRate: 99,
        sharesCount: 980,
      );
    case 'u_rank_global_3':
      return buildUser(
        id: userId,
        username: 'NovaClip',
        displayName: 'Nova Clip',
        avatarUrl: Take30Assets.avatarIaFemaleAlt,
        bio: 'Scènes nettes, placement précis et finition premium.',
        scenesCount: 17,
        followersCount: 16100,
        likesCount: 68800,
        totalViews: 301000,
        approvalRate: 98,
        sharesCount: 904,
      );
    case 'u_rank_day_2':
    case 'u_rank_month_2':
    case 'u_rank_global_2':
    case 'demo_local':
      return buildUser(
        id: userId,
        username: 'demo_take30',
        displayName: 'Mode Demo',
        avatarUrl: Take30Assets.avatarCurrentUser,
        email: 'demo@take30.app',
        bio: 'Profil démo instantané pour parcourir Take 30 sans attendre.',
        scenesCount: 3,
        followersCount: 124,
        likesCount: 418,
        totalViews: 12600,
        approvalRate: 92,
        sharesCount: 18,
      );
    default:
      return buildUser(
        id: userId,
        username: 'TalentTake30',
        displayName: 'Talent Take 30',
        avatarUrl: Take30Assets.avatarCurrentUser,
        bio: 'Profil de démonstration généré localement.',
        scenesCount: 3,
        followersCount: 320,
        likesCount: 1180,
        totalViews: 8400,
        approvalRate: 90,
        sharesCount: 42,
      );
  }
}

List<SceneModel> _buildDemoProfileScenes(UserModel user) {
  final now = DateTime.now();

  SceneModel buildScene({
    required String id,
    required String title,
    required String category,
    required String thumbnailUrl,
    required Duration age,
    required int likesCount,
    required int commentsCount,
    required int sharesCount,
    required int viewsCount,
    List<String> tags = const [],
  }) {
    return SceneModel(
      id: id,
      title: title,
      category: category,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: 30,
      likesCount: likesCount,
      commentsCount: commentsCount,
      sharesCount: sharesCount,
      viewsCount: viewsCount,
      author: user,
      createdAt: now.subtract(age),
      tags: tags,
    );
  }

  switch (user.username) {
    case 'LunaScene':
      return [
        buildScene(
          id: 'scene_profile_luna_1',
          title: 'Face-à-face sous tension',
          category: 'drama',
          thumbnailUrl: 'assets/scenes/battle_player_a.png',
          age: const Duration(hours: 3),
          likesCount: 248,
          commentsCount: 31,
          sharesCount: 14,
          viewsCount: 4120,
          tags: const ['demo', 'drama'],
        ),
        buildScene(
          id: 'scene_profile_luna_2',
          title: 'Le regard qui change tout',
          category: 'emotion',
          thumbnailUrl: Take30Assets.avatarIaFemaleAlt,
          age: const Duration(days: 1),
          likesCount: 193,
          commentsCount: 22,
          sharesCount: 9,
          viewsCount: 3380,
          tags: const ['demo', 'emotion'],
        ),
      ];
    case 'MaxShot':
      return [
        buildScene(
          id: 'scene_profile_max_1',
          title: 'Réplique sèche, effet immédiat',
          category: 'comedy',
          thumbnailUrl: 'assets/scenes/battle_player_b.png',
          age: const Duration(hours: 5),
          likesCount: 221,
          commentsCount: 17,
          sharesCount: 16,
          viewsCount: 3960,
          tags: const ['demo', 'comedy'],
        ),
        buildScene(
          id: 'scene_profile_max_2',
          title: 'One-liner caméra frontale',
          category: 'punchline',
          thumbnailUrl: Take30Assets.avatarIaMaleLead,
          age: const Duration(days: 1),
          likesCount: 174,
          commentsCount: 14,
          sharesCount: 10,
          viewsCount: 2870,
          tags: const ['demo', 'viral'],
        ),
      ];
    case 'demo_take30':
      return [
        buildScene(
          id: 'scene_profile_demo_1',
          title: 'Premier take instantané',
          category: 'starter',
          thumbnailUrl: Take30Assets.avatarCurrentUser,
          age: const Duration(minutes: 42),
          likesCount: 96,
          commentsCount: 12,
          sharesCount: 5,
          viewsCount: 1540,
          tags: const ['demo', 'starter'],
        ),
        buildScene(
          id: 'scene_profile_demo_2',
          title: 'Monologue express en 30 secondes',
          category: 'acting',
          thumbnailUrl: 'assets/scenes/battle_player_a.png',
          age: const Duration(hours: 6),
          likesCount: 82,
          commentsCount: 8,
          sharesCount: 4,
          viewsCount: 1190,
          tags: const ['demo', 'acting'],
        ),
        buildScene(
          id: 'scene_profile_demo_3',
          title: 'Take premium, rendu immédiat',
          category: 'spotlight',
          thumbnailUrl: 'assets/scenes/battle_player_b.png',
          age: const Duration(days: 1),
          likesCount: 140,
          commentsCount: 16,
          sharesCount: 6,
          viewsCount: 2040,
          tags: const ['demo', 'spotlight'],
        ),
      ];
    default:
      return [
        buildScene(
          id: 'scene_profile_generic_1',
          title: 'Performance démo premium',
          category: 'showcase',
          thumbnailUrl: 'assets/scenes/battle_player_a.png',
          age: const Duration(hours: 8),
          likesCount: 118,
          commentsCount: 13,
          sharesCount: 6,
          viewsCount: 1860,
          tags: const ['demo'],
        ),
        buildScene(
          id: 'scene_profile_generic_2',
          title: 'Extrait à fort impact',
          category: 'showcase',
          thumbnailUrl: 'assets/scenes/battle_player_b.png',
          age: const Duration(days: 1),
          likesCount: 101,
          commentsCount: 11,
          sharesCount: 5,
          viewsCount: 1680,
          tags: const ['demo'],
        ),
      ];
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._api, this._haptics, this._share, this.userId)
      : super(const ProfileState()) {
    load();
  }

  final ApiService _api;
  final HapticsService _haptics;
  final ShareService _share;
  final String userId;

  Future<void> load() async {
    if (_isDemoUser(_api.currentUser)) {
      final user = _buildDemoProfileUser(userId, _api.currentUser);
      state = state.copyWith(
        isLoading: false,
        user: user,
        scenes: _buildDemoProfileScenes(user),
      );
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final user = await _api.getProfile(userId);
      final scenes = await _api.getUserScenes(userId);
      state = state.copyWith(isLoading: false, user: user, scenes: scenes);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggleFollow() async {
    if (state.user == null) {
      return;
    }

    await _haptics.medium();
    final updated = state.user!.copyWith(
      isFollowing: !state.user!.isFollowing,
      followersCount: state.user!.isFollowing
          ? state.user!.followersCount - 1
          : state.user!.followersCount + 1,
    );
    state = state.copyWith(user: updated);
    if (_isDemoUser(_api.currentUser)) {
      return;
    }
    await _api.followUser(userId);
  }

  Future<void> shareProfile() async {
    if (state.user == null) {
      return;
    }

    await _share.shareProfile(state.user!);
  }
}

class ProfileState {
  const ProfileState({
    this.isLoading = false,
    this.user,
    this.scenes = const [],
  });

  final bool isLoading;
  final UserModel? user;
  final List<SceneModel> scenes;

  ProfileState copyWith({
    bool? isLoading,
    UserModel? user,
    List<SceneModel>? scenes,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      scenes: scenes ?? this.scenes,
    );
  }
}

final profileProvider = StateNotifierProvider.family<ProfileNotifier, ProfileState, String>(
  (ref, userId) => ProfileNotifier(
    ref.read(apiServiceProvider),
    ref.read(hapticsProvider),
    ref.read(shareServiceProvider),
    userId,
  ),
);

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
