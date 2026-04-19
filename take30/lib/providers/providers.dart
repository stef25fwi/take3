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

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _auth.loginWithEmail(email: email, password: password);
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
  FeedNotifier(this._api, this._haptics) : super(const FeedState()) {
    loadFeed();
  }

  final ApiService _api;
  final HapticsService _haptics;

  Future<void> loadFeed({bool refresh = false}) async {
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
    await _api.likeScene(sceneId);
  }

  void refresh() {
    loadFeed(refresh: true);
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
    state = state.copyWith(isLoading: true, period: period);
    try {
      final entries = await _api.getLeaderboard(period);
      state = state.copyWith(isLoading: false, entries: entries);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
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
  DuelNotifier(this._api, this._haptics) : super(const DuelState()) {
    load();
  }

  final ApiService _api;
  final HapticsService _haptics;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final duel = await _api.getCurrentDuel();
      state = state.copyWith(isLoading: false, duel: duel);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> vote(int choice) async {
    if (state.duel == null) {
      return;
    }

    await _haptics.heavy();
    final updated = await _api.vote(state.duel!.id, choice);
    state = state.copyWith(duel: updated);
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

final notificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) async* {
  final api = ref.watch(apiServiceProvider);
  final uid = api.currentUid;
  if (uid == null) {
    yield const <NotificationModel>[];
    return;
  }
  yield* api.notifications.watchForUser(uid);
});

final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.when(
    data: (items) => items.where((item) => !item.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final dailyChallengeProvider =
    StreamProvider<DailyChallengeModel?>((ref) async* {
  final api = ref.watch(apiServiceProvider);
  yield* api.dailyChallenge.watchToday();
});

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
