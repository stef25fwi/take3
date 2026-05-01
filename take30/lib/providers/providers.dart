import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' show PermissionStatus;
import 'package:shared_preferences/shared_preferences.dart';

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
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main().');
});
final authServiceProvider = ChangeNotifierProvider<AuthServiceBase>((ref) => AuthService());
final cameraServiceProvider = ChangeNotifierProvider<CameraService>((ref) => CameraService());
final uploadServiceProvider = ChangeNotifierProvider<VideoUploadService>((ref) => VideoUploadService());
final notifServiceProvider = Provider<NotificationService>((ref) => NotificationService());
final notificationServiceProvider = notifServiceProvider;
final shareServiceProvider = Provider<ShareService>((ref) => ShareService());
final hapticsProvider = Provider<HapticsService>((ref) => HapticsService());
final connectivityProvider = ChangeNotifierProvider<ConnectivityService>((ref) => ConnectivityService());
final permissionProvider = Provider<PermissionService>((ref) => PermissionService());

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(initialModeFromPrefs(_prefs));

  static const String _storageKey = 'take30.theme_mode';

  final SharedPreferences _prefs;

  static ThemeMode initialModeFromPrefs(SharedPreferences prefs) {
    final storedMode = prefs.getString(_storageKey);
    if (storedMode == ThemeMode.light.name) {
      return ThemeMode.light;
    }
    return ThemeMode.dark;
  }

  bool get isDark => state == ThemeMode.dark;

  Future<void> setMode(ThemeMode mode) async {
    final resolvedMode = mode == ThemeMode.light ? ThemeMode.light : ThemeMode.dark;
    if (state == resolvedMode) {
      return;
    }
    state = resolvedMode;
    await _prefs.setString(_storageKey, resolvedMode.name);
  }

  Future<void> toggle() {
    return setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(ref.read(sharedPreferencesProvider)),
);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._auth) : super(const AuthState()) {
    _auth.addListener(_syncFromService);
    _init();
  }

  final AuthServiceBase _auth;

  Future<void> _init() async {
    await _auth.checkPersistedAuth();
    _syncFromService();
  }

  void _syncFromService() {
    state = AuthState(
      isLoading: _auth.isLoading,
      isAuthenticated: _auth.isAuthenticated,
      user: _auth.currentUser,
      error: _auth.error,
    );
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

  @override
  void dispose() {
    _auth.removeListener(_syncFromService);
    super.dispose();
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

const String _demoPublishedScenesPrefKey = 'take30.demo_published_scenes';
const String _demoSceneInteractionsPrefKey = 'take30.demo_scene_interactions';

Map<String, dynamic> _demoUserToJson(UserModel user) => {
      'id': user.id,
      'username': user.username,
      'displayName': user.displayName,
      'avatarUrl': user.avatarUrl,
      'email': user.email,
      'bio': user.bio,
      'isVerified': user.isVerified,
      'scenesCount': user.scenesCount,
      'followersCount': user.followersCount,
      'likesCount': user.likesCount,
      'totalViews': user.totalViews,
      'approvalRate': user.approvalRate,
      'sharesCount': user.sharesCount,
      'isFollowing': user.isFollowing,
      'isAdmin': user.isAdmin,
      'createdAt': user.createdAt?.toIso8601String(),
      'lastActiveAt': user.lastActiveAt?.toIso8601String(),
      'fcmTokens': user.fcmTokens,
    };

UserModel _demoUserFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      email: json['email'] as String?,
      bio: json['bio'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      scenesCount: (json['scenesCount'] as num?)?.toInt() ?? 0,
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
      approvalRate: (json['approvalRate'] as num?)?.toDouble() ?? 0,
      sharesCount: (json['sharesCount'] as num?)?.toInt() ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? false,
      isAdmin: json['isAdmin'] as bool? ?? false,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      lastActiveAt: json['lastActiveAt'] is String
          ? DateTime.tryParse(json['lastActiveAt'] as String)
          : null,
      fcmTokens: (json['fcmTokens'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
    );

Map<String, dynamic> _demoCommentToJson(CommentModel comment) => {
      'id': comment.id,
      'sceneId': comment.sceneId,
      'authorId': comment.authorId,
      'authorDenorm': comment.authorDenorm.toMap(),
      'text': comment.text,
      'createdAt': comment.createdAt.toIso8601String(),
      'likesCount': comment.likesCount,
    };

CommentModel _demoCommentFromJson(Map<String, dynamic> json) => CommentModel(
      id: json['id'] as String? ?? '',
      sceneId: json['sceneId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorDenorm: UserStub.fromMap(
        (json['authorDenorm'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _demoSceneToJson(SceneModel scene) => {
      'id': scene.id,
      'title': scene.title,
      'category': scene.category,
      'thumbnailUrl': scene.thumbnailUrl,
      'videoUrl': scene.videoUrl,
      'durationSeconds': scene.durationSeconds,
      'likesCount': scene.likesCount,
      'commentsCount': scene.commentsCount,
      'sharesCount': scene.sharesCount,
      'viewsCount': scene.viewsCount,
      'author': _demoUserToJson(scene.author),
      'createdAt': scene.createdAt.toIso8601String(),
      'isLiked': scene.isLiked,
      'tags': scene.tags,
      'status': scene.status,
    };

SceneModel _demoSceneFromJson(Map<String, dynamic> json) => SceneModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      videoUrl: json['videoUrl'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 30,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      sharesCount: (json['sharesCount'] as num?)?.toInt() ?? 0,
      viewsCount: (json['viewsCount'] as num?)?.toInt() ?? 0,
      author: _demoUserFromJson(
        (json['author'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      isLiked: json['isLiked'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      status: json['status'] as String? ?? 'published',
    );

Map<String, dynamic> _demoInteractionToJson(DemoSceneInteractionState state) => {
      'isLiked': state.isLiked,
      'likesCount': state.likesCount,
      'commentsCount': state.commentsCount,
      'comments': [for (final comment in state.comments) _demoCommentToJson(comment)],
    };

DemoSceneInteractionState _demoInteractionFromJson(Map<String, dynamic> json) =>
    DemoSceneInteractionState(
      isLiked: json['isLiked'] as bool? ?? false,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      comments: [
        for (final comment in json['comments'] as List<dynamic>? ?? const [])
          _demoCommentFromJson((comment as Map).cast<String, dynamic>()),
      ],
    );

class DemoPublishedScenesStore extends ChangeNotifier {
  DemoPublishedScenesStore() {
    _restore();
  }

  List<SceneModel> _scenes = const [];

  List<SceneModel> get scenes => _scenes;

  void add(SceneModel scene) {
    _scenes = [
      scene,
      for (final existing in _scenes)
        if (existing.id != scene.id) existing,
    ];
    _persist();
    notifyListeners();
  }

  void clear() {
    if (_scenes.isEmpty) {
      return;
    }
    _scenes = const [];
    _persist();
    notifyListeners();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_demoPublishedScenesPrefKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    _scenes = [
      for (final item in decoded) _demoSceneFromJson((item as Map).cast<String, dynamic>()),
    ];
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_scenes.isEmpty) {
      await prefs.remove(_demoPublishedScenesPrefKey);
      return;
    }
    await prefs.setString(
      _demoPublishedScenesPrefKey,
      jsonEncode([for (final scene in _scenes) _demoSceneToJson(scene)]),
    );
  }
}

class DemoSceneInteractionState {
  const DemoSceneInteractionState({
    required this.isLiked,
    required this.likesCount,
    required this.commentsCount,
    required this.comments,
  });

  final bool isLiked;
  final int likesCount;
  final int commentsCount;
  final List<CommentModel> comments;

  DemoSceneInteractionState copyWith({
    bool? isLiked,
    int? likesCount,
    int? commentsCount,
    List<CommentModel>? comments,
  }) {
    return DemoSceneInteractionState(
      isLiked: isLiked ?? this.isLiked,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      comments: comments ?? this.comments,
    );
  }
}

class DemoSceneInteractionsStore extends ChangeNotifier {
  DemoSceneInteractionsStore() {
    _restore();
  }

  final Map<String, DemoSceneInteractionState> _states = {};

  void clear() {
    if (_states.isEmpty) {
      return;
    }
    _states.clear();
    _persist();
    notifyListeners();
  }

  DemoSceneInteractionState _ensure(
    SceneModel scene,
    List<CommentModel> initialComments,
  ) {
    return _states.putIfAbsent(
      scene.id,
      () => DemoSceneInteractionState(
        isLiked: scene.isLiked,
        likesCount: scene.likesCount,
        commentsCount: scene.commentsCount,
        comments: List<CommentModel>.from(initialComments),
      ),
    );
  }

  SceneModel bindScene(SceneModel scene, List<CommentModel> initialComments) {
    final state = _ensure(scene, initialComments);
    return _applyDemoInteractionToScene(scene, state);
  }

  List<CommentModel> commentsFor(SceneModel scene, List<CommentModel> initialComments) {
    final state = _ensure(scene, initialComments);
    return state.comments;
  }

  void toggleLike(SceneModel scene, List<CommentModel> initialComments) {
    final state = _ensure(scene, initialComments);
    final nextLiked = !state.isLiked;
    _states[scene.id] = state.copyWith(
      isLiked: nextLiked,
      likesCount: nextLiked ? state.likesCount + 1 : state.likesCount - 1,
    );
    _persist();
    notifyListeners();
  }

  void addComment(
    SceneModel scene,
    UserModel author,
    String text,
    List<CommentModel> initialComments,
  ) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final state = _ensure(scene, initialComments);
    _states[scene.id] = state.copyWith(
      commentsCount: state.commentsCount + 1,
      comments: [
        ...state.comments,
        CommentModel(
          id: 'comment_demo_local_${DateTime.now().microsecondsSinceEpoch}',
          sceneId: scene.id,
          authorId: author.id,
          authorDenorm: author.toStub(),
          text: trimmed,
          createdAt: DateTime.now(),
        ),
      ],
    );
    _persist();
    notifyListeners();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_demoSceneInteractionsPrefKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
    _states
      ..clear()
      ..addAll({
        for (final entry in decoded.entries)
          entry.key: _demoInteractionFromJson(
            (entry.value as Map).cast<String, dynamic>(),
          ),
      });
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_states.isEmpty) {
      await prefs.remove(_demoSceneInteractionsPrefKey);
      return;
    }
    await prefs.setString(
      _demoSceneInteractionsPrefKey,
      jsonEncode({
        for (final entry in _states.entries)
          entry.key: _demoInteractionToJson(entry.value),
      }),
    );
  }
}

SceneModel _applyDemoInteractionToScene(
  SceneModel scene,
  DemoSceneInteractionState state,
) {
  return SceneModel(
    id: scene.id,
    title: scene.title,
    category: scene.category,
    thumbnailUrl: scene.thumbnailUrl,
    videoUrl: scene.videoUrl,
    durationSeconds: scene.durationSeconds,
    likesCount: state.likesCount,
    commentsCount: state.commentsCount,
    sharesCount: scene.sharesCount,
    viewsCount: scene.viewsCount,
    author: scene.author,
    createdAt: scene.createdAt,
    isLiked: state.isLiked,
    tags: scene.tags,
    status: scene.status,
  );
}

final demoPublishedScenesStoreProvider =
    ChangeNotifierProvider<DemoPublishedScenesStore>((ref) {
  final store = DemoPublishedScenesStore();
  ref.listen<UserModel?>(
    authProvider.select((state) => state.user),
    (_, next) {
      if (!_isDemoUser(next)) {
        store.clear();
      }
    },
  );
  return store;
});

final demoSceneInteractionsStoreProvider =
    ChangeNotifierProvider<DemoSceneInteractionsStore>((ref) {
  final store = DemoSceneInteractionsStore();
  ref.listen<UserModel?>(
    authProvider.select((state) => state.user),
    (_, next) {
      if (!_isDemoUser(next)) {
        store.clear();
      }
    },
  );
  return store;
});

class FeedNotifier extends StateNotifier<FeedState> {
  static const String _demoEmail = 'demo@take30.app';
  static const String _demoUsername = 'demo_take30';
  static const String _demoDisplayName = 'Mode Demo';

  FeedNotifier(
    this._api,
    this._haptics,
    this._demoPublishedScenesStore,
    this._demoSceneInteractionsStore,
  )
      : super(const FeedState()) {
    _demoPublishedScenesStore.addListener(_handleDemoPublishedScenesChanged);
    _demoSceneInteractionsStore.addListener(_handleDemoSceneInteractionsChanged);
    loadFeed();
  }

  final ApiService _api;
  final HapticsService _haptics;
  final DemoPublishedScenesStore _demoPublishedScenesStore;
  final DemoSceneInteractionsStore _demoSceneInteractionsStore;

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
    return _buildDemoFeedScenes(
      _api.currentUser,
      _demoPublishedScenesStore.scenes,
      _demoSceneInteractionsStore,
    );
  }

  void _handleDemoPublishedScenesChanged() {
    if (!_isDemoMode) {
      return;
    }

    state = FeedState(
      isLoading: false,
      scenes: _buildDemoFeed(),
    );
  }

  void _handleDemoSceneInteractionsChanged() {
    if (!_isDemoMode) {
      return;
    }

    state = FeedState(
      isLoading: false,
      scenes: _buildDemoFeed(),
    );
  }

  @override
  void dispose() {
    _demoPublishedScenesStore.removeListener(_handleDemoPublishedScenesChanged);
    _demoSceneInteractionsStore
        .removeListener(_handleDemoSceneInteractionsChanged);
    super.dispose();
  }
}

List<SceneModel> _mergeDemoScenes(
  List<SceneModel> priorityScenes,
  List<SceneModel> fallbackScenes,
) {
  final deduped = <String, SceneModel>{};
  for (final scene in [...priorityScenes, ...fallbackScenes]) {
    deduped[scene.id] = scene;
  }
  return deduped.values.toList();
}

List<SceneModel> _buildDemoFeedScenes(
  UserModel? currentUser,
  List<SceneModel> publishedScenes,
  DemoSceneInteractionsStore? interactionsStore,
) {
  final now = DateTime.now();
  final resolvedCurrentUser = currentUser ??
      UserModel(
        id: 'demo_local',
        username: 'demo_take30',
        displayName: 'Mode Demo',
        avatarUrl: Take30Assets.avatarCurrentUser,
        email: 'demo@take30.app',
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

  final baseScenes = [
    SceneModel(
      id: 's_demo_feed_1',
      title: 'Clash émotionnel en 60 secondes',
      category: 'drama',
      thumbnailUrl: 'assets/scenes/battle_player_a.png',
      durationSeconds: 60,
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
      durationSeconds: 60,
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
      durationSeconds: 60,
      likesCount: 96,
      commentsCount: 12,
      sharesCount: 5,
      viewsCount: 1540,
      author: resolvedCurrentUser,
      createdAt: now.subtract(const Duration(minutes: 40)),
      tags: const ['demo', 'starter', 'spotlight'],
    ),
  ];

  final mergedScenes = _mergeDemoScenes(publishedScenes, baseScenes);
  if (interactionsStore == null) {
    return mergedScenes;
  }

  return [
    for (final scene in mergedScenes)
      interactionsStore.bindScene(
        scene,
        _buildDemoSceneComments(scene.id, currentUser, publishedScenes),
      ),
  ];
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
  (ref) => FeedNotifier(
    ref.read(apiServiceProvider),
    ref.read(hapticsProvider),
    ref.read(demoPublishedScenesStoreProvider),
    ref.read(demoSceneInteractionsStoreProvider),
  ),
);

List<SceneModel> _buildDemoSceneCatalog(
  UserModel? currentUser,
  List<SceneModel> publishedScenes,
  DemoSceneInteractionsStore? interactionsStore,
) {
  final users = <UserModel>[
    _buildDemoProfileUser(currentUser?.id ?? 'demo_local', currentUser),
    _buildDemoProfileUser('u_demo_feed_a', currentUser),
    _buildDemoProfileUser('u_demo_feed_b', currentUser),
    _buildDemoProfileUser('u_rank_week_1', currentUser),
    _buildDemoProfileUser('u_rank_week_3', currentUser),
    _buildDemoProfileUser('u_rank_month_1', currentUser),
    _buildDemoProfileUser('u_rank_month_3', currentUser),
    _buildDemoProfileUser('u_rank_global_1', currentUser),
    _buildDemoProfileUser('u_rank_global_3', currentUser),
  ];

  final scenes = <SceneModel>[
    ..._buildDemoFeedScenes(
      currentUser,
      publishedScenes,
      interactionsStore,
    ),
    for (final user in users)
      ..._buildDemoProfileScenes(user, publishedScenes, interactionsStore),
  ];

  return _mergeDemoScenes(const [], scenes);
}

SceneModel? _findDemoScene(
  String sceneId,
  UserModel? currentUser,
  List<SceneModel> publishedScenes,
  DemoSceneInteractionsStore? interactionsStore,
) {
  for (final scene in _buildDemoSceneCatalog(
    currentUser,
    publishedScenes,
    interactionsStore,
  )) {
    if (scene.id == sceneId) {
      return scene;
    }
  }
  return null;
}

List<CommentModel> _buildDemoSceneComments(
  String sceneId,
  UserModel? currentUser,
  List<SceneModel> publishedScenes,
) {
  final now = DateTime.now();
  final scene = _findDemoScene(sceneId, currentUser, publishedScenes, null);
  final current = _buildDemoProfileUser(currentUser?.id ?? 'demo_local', currentUser);
  final peer = scene?.author ?? _buildDemoProfileUser('u_demo_feed_a', currentUser);

  return [
    CommentModel(
      id: 'comment_demo_1_$sceneId',
      sceneId: sceneId,
      authorId: peer.id,
      authorDenorm: peer.toStub(),
      text: 'Très bonne énergie dès la première seconde.',
      createdAt: now.subtract(const Duration(minutes: 18)),
      likesCount: 7,
    ),
    CommentModel(
      id: 'comment_demo_2_$sceneId',
      sceneId: sceneId,
      authorId: current.id,
      authorDenorm: current.toStub(),
      text: 'Merci. Je teste ici le parcours complet en mode démo.',
      createdAt: now.subtract(const Duration(minutes: 9)),
      likesCount: 2,
    ),
  ];
}

final sceneProvider = StreamProvider.family<SceneModel?, String>((ref, sceneId) async* {
  final authUser = ref.watch(authProvider.select((state) => state.user));
  if (_isDemoUser(authUser)) {
    final publishedScenes = ref.watch(demoPublishedScenesStoreProvider).scenes;
    final interactionsStore = ref.watch(demoSceneInteractionsStoreProvider);
    yield _findDemoScene(
      sceneId,
      authUser,
      publishedScenes,
      interactionsStore,
    );
    return;
  }

  final api = ref.watch(apiServiceProvider);
  yield* api.scenes.watchById(sceneId);
});

final sceneCommentsProvider =
    StreamProvider.family<List<CommentModel>, String>((ref, sceneId) async* {
  final authUser = ref.watch(authProvider.select((state) => state.user));
  if (_isDemoUser(authUser)) {
    final publishedScenes = ref.watch(demoPublishedScenesStoreProvider).scenes;
    final interactionsStore = ref.watch(demoSceneInteractionsStoreProvider);
    final scene = _findDemoScene(
      sceneId,
      authUser,
      publishedScenes,
      interactionsStore,
    );
    if (scene == null) {
      yield const <CommentModel>[];
      return;
    }
    yield interactionsStore.commentsFor(
      scene,
      _buildDemoSceneComments(sceneId, authUser, publishedScenes),
    );
    return;
  }

  final api = ref.watch(apiServiceProvider);
  yield* api.comments.watch(sceneId);
});

final demoSceneCommentsProvider = Provider.family<List<CommentModel>, String>((ref, sceneId) {
  final authUser = ref.watch(authProvider.select((state) => state.user));
  final publishedScenes = ref.watch(demoPublishedScenesStoreProvider).scenes;
  final interactionsStore = ref.watch(demoSceneInteractionsStoreProvider);
  final scene = _findDemoScene(
    sceneId,
    authUser,
    publishedScenes,
    interactionsStore,
  );
  if (scene == null) {
    return const <CommentModel>[];
  }
  return interactionsStore.commentsFor(
    scene,
    _buildDemoSceneComments(sceneId, authUser, publishedScenes),
  );
});

class CameraInitResult {
  const CameraInitResult._({
    required this.isReady,
    this.needsSettings = false,
    this.missingPermissions = const <AppPermission>[],
  });

  const CameraInitResult.ready() : this._(isReady: true);

  const CameraInitResult.denied({
    required bool needsSettings,
    required List<AppPermission> missingPermissions,
  }) : this._(
         isReady: false,
         needsSettings: needsSettings,
         missingPermissions: missingPermissions,
       );

  const CameraInitResult.unavailable() : this._(isReady: false);

  final bool isReady;
  final bool needsSettings;
  final List<AppPermission> missingPermissions;
}

bool _needsPermissionSettings(PermissionStatus status) {
  return status == PermissionStatus.permanentlyDenied ||
      status == PermissionStatus.restricted;
}

class RecordingNotifier extends StateNotifier<RecordingState> {
  RecordingNotifier(
    this._api,
    this._camera,
    this._upload,
    this._haptics,
    this._notifications,
    this._permissions,
    this._demoPublishedScenesStore,
  ) : super(const RecordingState());

  final ApiService _api;
  final CameraService _camera;
  final VideoUploadService _upload;
  final HapticsService _haptics;
  final NotificationService _notifications;
  final PermissionService _permissions;
  final DemoPublishedScenesStore _demoPublishedScenesStore;

  Future<CameraInitResult> initCamera(BuildContext context) async {
    final cameraGranted = await _permissions.requestWithExplanation(
      context,
      AppPermission.camera,
      title: 'Caméra requise',
      message: 'Take 60 a besoin de ta caméra pour enregistrer tes performances.',
    );
    if (!cameraGranted) {
      final cameraStatus = await _permissions.status(AppPermission.camera);
      return CameraInitResult.denied(
        needsSettings: _needsPermissionSettings(cameraStatus),
        missingPermissions: const [AppPermission.camera],
      );
    }

    if (!context.mounted) {
      return const CameraInitResult.unavailable();
    }

    final microphoneGranted = await _permissions.requestWithExplanation(
      context,
      AppPermission.microphone,
      title: 'Micro requis',
      message: 'Take 60 a besoin du microphone pour capturer le son.',
    );
    if (!microphoneGranted) {
      final microphoneStatus = await _permissions.status(AppPermission.microphone);
      return CameraInitResult.denied(
        needsSettings: _needsPermissionSettings(microphoneStatus),
        missingPermissions: const [AppPermission.microphone],
      );
    }

    final ready = await _camera.initialize();
    state = state.copyWith(cameraReady: ready);
    return ready
        ? const CameraInitResult.ready()
        : const CameraInitResult.unavailable();
  }

  Future<bool> startRecording({int? maxDurationSeconds}) async {
    await _haptics.recordStart();
    final started = await _camera.startRecording(
      maxDurationSeconds: maxDurationSeconds,
    );
    if (started) {
      state = state.copyWith(isRecording: true, elapsed: 0);
    }
    return started;
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

  RecordingResult? consumeCompletedRecording() {
    final result = _camera.consumeLastRecordingResult();
    if (result != null) {
      state = state.copyWith(
        isRecording: false,
        recordedPath: result.filePath,
        elapsed: result.durationSeconds,
      );
    }
    return result;
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
    final isDemoMode = _isDemoUser(_api.currentUser);
    if (state.recordedPath == null && !isDemoMode) {
      return null;
    }

    if (isDemoMode) {
      final author = _api.currentUser ??
          _buildDemoProfileUser('demo_local', _api.currentUser);
      final localScene = SceneModel(
        id: 'scene_demo_publish_${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        category: category,
        thumbnailUrl:
            state.scene?.thumbnailUrl.isNotEmpty == true
                ? state.scene!.thumbnailUrl
                : 'assets/scenes/battle_player_a.png',
        videoUrl: state.recordedPath,
        durationSeconds:
          state.elapsed > 0
            ? state.elapsed
            : CameraService.maxRecordingSeconds,
        likesCount: 0,
        commentsCount: 0,
        sharesCount: 0,
        viewsCount: 0,
        author: author,
        createdAt: DateTime.now(),
        tags: tags,
        status: 'published',
      );

      _demoPublishedScenesStore.add(localScene);
      await _haptics.success();
      await _notifications.showPublishSuccessNotification(sceneTitle: title);
      return localScene;
    }

    final scene = await _upload.uploadScene(
      videoPath: state.recordedPath!,
      title: title,
      category: category,
      authorId: 'u1',
      durationSeconds:
          state.elapsed > 0
              ? state.elapsed
              : CameraService.maxRecordingSeconds,
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
    ref.read(apiServiceProvider),
    ref.read(cameraServiceProvider),
    ref.read(uploadServiceProvider),
    ref.read(hapticsProvider),
    ref.read(notifServiceProvider),
    ref.read(permissionProvider),
    ref.read(demoPublishedScenesStoreProvider),
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
    if (_isDemoMode) {
      state = state.copyWith(
        isLoading: false,
        duel: _buildDemoDuel(),
      );
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final duel = await _api.getCurrentDuel();
      state = state.copyWith(
        isLoading: false,
        duel: duel,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        duel: null,
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
      durationSeconds: 60,
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
      durationSeconds: 60,
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
  (ref) {
    final notifier = DuelNotifier(
      ref.read(apiServiceProvider),
      ref.read(hapticsProvider),
    );
    ref.listen<UserModel?>(
      authProvider.select((state) => state.user),
      (_, __) => notifier.load(),
    );
    return notifier;
  },
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
    maxSeconds: 60,
    thumbnailUrl: 'assets/scenes/daily_challenge_spotlight.svg',
    rules: const [
      '60 secondes max',
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
      bio: 'Tu explores Take 60 en mode démo avec un profil instantané.',
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

List<SceneModel> _buildDemoProfileScenes(
  UserModel user,
  List<SceneModel> publishedScenes,
  DemoSceneInteractionsStore? interactionsStore,
) {
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
      durationSeconds: 60,
      likesCount: likesCount,
      commentsCount: commentsCount,
      sharesCount: sharesCount,
      viewsCount: viewsCount,
      author: user,
      createdAt: now.subtract(age),
      tags: tags,
    );
  }

  late final List<SceneModel> baseScenes;

  switch (user.username) {
    case 'LunaScene':
      baseScenes = [
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
      baseScenes = [
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
      baseScenes = [
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
          title: 'Monologue express en 60 secondes',
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
      baseScenes = [
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

  final authoredPublishedScenes = publishedScenes
      .where((scene) => scene.author.id == user.id)
      .toList();
  final mergedScenes = _mergeDemoScenes(authoredPublishedScenes, baseScenes);
  if (interactionsStore == null) {
    return mergedScenes;
  }

  return [
    for (final scene in mergedScenes)
      interactionsStore.bindScene(
        scene,
        _buildDemoSceneComments(scene.id, user, publishedScenes),
      ),
  ];
}

UserModel _applyDemoPublishedSceneStats(
  UserModel user,
  List<SceneModel> publishedScenes,
) {
  final authoredCount = publishedScenes
      .where((scene) => scene.author.id == user.id)
      .length;
  if (authoredCount == 0) {
    return user;
  }

  return UserModel(
    id: user.id,
    username: user.username,
    displayName: user.displayName,
    avatarUrl: user.avatarUrl,
    email: user.email,
    bio: user.bio,
    isVerified: user.isVerified,
    scenesCount: user.scenesCount + authoredCount,
    followersCount: user.followersCount,
    likesCount: user.likesCount,
    totalViews: user.totalViews,
    approvalRate: user.approvalRate,
    sharesCount: user.sharesCount,
    badges: user.badges,
    isFollowing: user.isFollowing,
    isAdmin: user.isAdmin,
    createdAt: user.createdAt,
    lastActiveAt: user.lastActiveAt,
    fcmTokens: user.fcmTokens,
  );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(
    this._api,
    this._haptics,
    this._share,
    this._demoPublishedScenesStore,
    this._demoSceneInteractionsStore,
    this.userId,
  )
      : super(const ProfileState()) {
    _demoPublishedScenesStore.addListener(_handleDemoPublishedScenesChanged);
    _demoSceneInteractionsStore.addListener(_handleDemoSceneInteractionsChanged);
    load();
  }

  final ApiService _api;
  final HapticsService _haptics;
  final ShareService _share;
  final DemoPublishedScenesStore _demoPublishedScenesStore;
  final DemoSceneInteractionsStore _demoSceneInteractionsStore;
  final String userId;

  Future<void> load() async {
    if (_isDemoUser(_api.currentUser)) {
      final user = _applyDemoPublishedSceneStats(
        _buildDemoProfileUser(userId, _api.currentUser),
        _demoPublishedScenesStore.scenes,
      );
      state = state.copyWith(
        isLoading: false,
        user: user,
        scenes: _buildDemoProfileScenes(
          user,
          _demoPublishedScenesStore.scenes,
          _demoSceneInteractionsStore,
        ),
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

  void _handleDemoPublishedScenesChanged() {
    if (_isDemoUser(_api.currentUser)) {
      load();
    }
  }

  void _handleDemoSceneInteractionsChanged() {
    if (_isDemoUser(_api.currentUser)) {
      load();
    }
  }

  @override
  void dispose() {
    _demoPublishedScenesStore.removeListener(_handleDemoPublishedScenesChanged);
    _demoSceneInteractionsStore
        .removeListener(_handleDemoSceneInteractionsChanged);
    super.dispose();
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
  (ref, userId) {
    final notifier = ProfileNotifier(
      ref.read(apiServiceProvider),
      ref.read(hapticsProvider),
      ref.read(shareServiceProvider),
      ref.read(demoPublishedScenesStoreProvider),
      ref.read(demoSceneInteractionsStoreProvider),
      userId,
    );
    ref.listen<UserModel?>(
      authProvider.select((state) => state.user),
      (_, __) => notifier.load(),
    );
    return notifier;
  },
);

class DemoChatMessage {
  const DemoChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.isFromCurrentUser,
  });

  final String id;
  final String text;
  final DateTime sentAt;
  final bool isFromCurrentUser;
}

List<DemoChatMessage> _buildDemoMessages({
  required UserModel currentUser,
  required UserModel peerUser,
}) {
  final now = DateTime.now();
  return [
    DemoChatMessage(
      id: 'msg_demo_1_${peerUser.id}',
      text: 'Ton dernier take a vraiment une bonne intensité.',
      sentAt: now.subtract(const Duration(minutes: 14)),
      isFromCurrentUser: false,
    ),
    DemoChatMessage(
      id: 'msg_demo_2_${peerUser.id}',
      text: 'Merci. Je teste le mode démo pour voir le rendu complet.',
      sentAt: now.subtract(const Duration(minutes: 11)),
      isFromCurrentUser: true,
    ),
    DemoChatMessage(
      id: 'msg_demo_3_${peerUser.id}',
      text: 'Continue, ton prochain passage peut clairement monter au classement.',
      sentAt: now.subtract(const Duration(minutes: 7)),
      isFromCurrentUser: false,
    ),
  ];
}

class DemoMessagesNotifier extends StateNotifier<List<DemoChatMessage>> {
  DemoMessagesNotifier({required UserModel currentUser, required UserModel peerUser})
      : super(_buildDemoMessages(currentUser: currentUser, peerUser: peerUser));

  void send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    state = [
      ...state,
      DemoChatMessage(
        id: 'msg_demo_local_${DateTime.now().microsecondsSinceEpoch}',
        text: trimmed,
        sentAt: DateTime.now(),
        isFromCurrentUser: true,
      ),
    ];
  }
}

final demoMessagesProvider = StateNotifierProvider.family<
    DemoMessagesNotifier,
    List<DemoChatMessage>,
    String>((ref, userId) {
  final authUser = ref.watch(authProvider.select((state) => state.user));
  final currentUser = _buildDemoProfileUser(authUser?.id ?? 'demo_local', authUser);
  final peerUser = _buildDemoProfileUser(userId, authUser);
  return DemoMessagesNotifier(currentUser: currentUser, peerUser: peerUser);
});

class DemoConversationSummary {
  const DemoConversationSummary({
    required this.peer,
    required this.lastMessage,
  });

  final UserModel peer;
  final DemoChatMessage? lastMessage;
}

const List<String> _demoConversationPeerIds = <String>[
  'u_demo_feed_a',
  'u_demo_feed_b',
  'u_rank_week_1',
  'u_rank_month_1',
  'u_rank_global_1',
];

final demoConversationsProvider =
    Provider.family<List<DemoConversationSummary>, String>((ref, viewerId) {
  final authUser = ref.watch(authProvider.select((state) => state.user));
  final peerIds =
      _demoConversationPeerIds.where((id) => id != viewerId).toList();
  return peerIds.map((peerId) {
    final peer = _buildDemoProfileUser(peerId, authUser);
    final messages = ref.watch(demoMessagesProvider(peerId));
    final last = messages.isEmpty ? null : messages.last;
    return DemoConversationSummary(peer: peer, lastMessage: last);
  }).toList();
});

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
