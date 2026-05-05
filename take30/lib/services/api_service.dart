import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_storage/firebase_storage.dart';

import '../models/models.dart';
import 'firebase/comments_repo.dart';
import 'firebase/daily_challenge_repo.dart';
import 'firebase/duels_repo.dart';
import 'firebase/firestore_refs.dart';
import 'firebase/leaderboard_repo.dart';
import 'firebase/notifications_repo.dart';
import 'firebase/scenes_repo.dart';
import 'firebase/storage_service.dart';
import 'firebase/users_repo.dart';

/// Façade unifiée pour la couche données Firestore/Storage/Functions.
/// Garde `ApiService()` comme singleton, utilisé par les providers.
class ApiService {
  ApiService._internal() {
    _db = FirebaseFirestore.instance;
    _auth = fa.FirebaseAuth.instance;
    _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
    _storage = FirebaseStorage.instance;

    refs = FirestoreRefs(_db);
    users = UsersRepo(refs, _functions);
    scenes = ScenesRepo(refs, _functions);
    comments = CommentsRepo(refs);
    notifications = NotificationsRepo(refs);
    duels = DuelsRepo(refs);
    dailyChallenge = DailyChallengeRepo(refs);
    leaderboard = LeaderboardRepo(refs);
    storage = StorageService(_storage);
  }

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final FirebaseFirestore _db;
  late final fa.FirebaseAuth _auth;
  late final FirebaseFunctions _functions;
  late final FirebaseStorage _storage;

  late final FirestoreRefs refs;
  late final UsersRepo users;
  late final ScenesRepo scenes;
  late final CommentsRepo comments;
  late final NotificationsRepo notifications;
  late final DuelsRepo duels;
  late final DailyChallengeRepo dailyChallenge;
  late final LeaderboardRepo leaderboard;
  late final StorageService storage;

  UserModel? _currentUser;

  bool get isAuthenticated => _auth.currentUser != null;
  UserModel? get currentUser => _currentUser;
  String? get currentUid => _auth.currentUser?.uid;

  Future<UserModel?> refreshCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _currentUser = null;
      return null;
    }
    _currentUser = await users.getById(uid);
    return _currentUser;
  }

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
  }

  // ─── Compat (anciennes signatures) ────────────────────────────────────────

  Future<List<SceneModel>> getFeed({int page = 0}) =>
      scenes.getFeed(limit: 30);

  Future<List<SceneModel>> getPopularScenes(String category) =>
      scenes.getPopular(category: category == 'all' ? null : category);

  Future<List<CategoryModel>> getCategories() async {
    final snap = await refs.categories.orderBy('order').get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<bool> likeScene(String sceneId) async {
    final uid = currentUid;
    if (uid == null) return false;
    return scenes.toggleLike(sceneId, uid);
  }

  Future<bool> followUser(String userId) => users.toggleFollow(userId);

  Future<List<LeaderboardEntry>> getLeaderboard(String period) =>
      leaderboard.list(period);

  Future<UserModel?> getProfile(String userId) => users.getById(userId);

  Future<List<SceneModel>> getUserScenes(String userId) =>
      scenes.getByAuthor(userId);

  Future<List<BadgeModel>> getBadges(String userId) async {
    final snap = await refs.userDoc(userId).collection('badges').get();
    return snap.docs.map((d) => BadgeModel.fromFirestore(d)).toList();
  }

  Future<DuelModel?> getCurrentDuel() => duels.getCurrent();

  Future<DuelModel?> vote(String duelId, int choice) async {
    final uid = currentUid;
    if (uid == null) return null;
    await duels.vote(duelId: duelId, uid: uid, choice: choice);
    return duels.getById(duelId);
  }

  Future<List<NotificationModel>> getNotifications() async {
    final uid = currentUid;
    if (uid == null) return const [];
    return notifications.listForUser(uid);
  }

  Future<DailyChallengeModel?> getDailyChallenge() =>
      dailyChallenge.getToday();

  Future<Take60VideoModel?> getTake60Video(String videoId) async {
    final snap = await refs.take60VideoDoc(videoId).get();
    return snap.exists ? snap.data() : null;
  }

  Future<String> getTake60PlayableUrl({required String videoId}) async {
    try {
      final result = await _functions
          .httpsCallable('getTake60PlayableUrl')
          .call({'videoId': videoId});
      final data = result.data;
      if (data is Map && data['playableUrl'] is String) {
        return data['playableUrl'] as String;
      }
    } on FirebaseFunctionsException {
      rethrow;
    }

    final video = await getTake60Video(videoId);
    if (video == null) {
      throw StateError('Vidéo Take60 introuvable: $videoId');
    }
    final user = _currentUser ?? (currentUid == null ? null : await users.getById(currentUid!));
    if (user?.plan == UserPlan.premium) {
      return video.hlsMasterUrl ?? video.hlsPremiumUrl ?? video.hlsBaseUrl ?? '';
    }
    return video.hlsBaseUrl ?? video.hlsMasterUrl ?? video.hlsPremiumUrl ?? '';
  }

  Future<void> requestTake60VideoTranscode({required String videoId}) async {
    await _functions.httpsCallable('requestTake60VideoTranscode').call({
      'videoId': videoId,
    });
  }

  /// Upload vidéo + création doc `scenes/{id}`.
  /// Les compteurs sont tenus côté Cloud Function `onSceneCreate`.
  Future<SceneModel?> uploadScene({
    required String videoPath,
    required String title,
    required String category,
    required int durationSeconds,
    required List<String> tags,
  }) async {
    final uid = currentUid;
    if (uid == null) return null;
    final user = _currentUser ?? await users.getById(uid);
    if (user == null) return null;

    final sceneId = refs.scenes.doc().id;
    final videoId = refs.take60Videos.doc().id;
    final rawUpload = await storage.uploadTake60RawVideo(
      storagePath: StorageService.buildTake60RawUploadPath(
        uid: uid,
        videoId: videoId,
      ),
      file: File(videoPath),
    );

    final createdAt = DateTime.now();
    final take60Video = Take60VideoModel(
      id: videoId,
      ownerId: uid,
      sceneId: sceneId,
      title: title,
      status: 'processing',
      qualityBase: '720p',
      premiumQuality: '1080p',
      isPremiumLocked: true,
      durationSec: durationSeconds,
      createdAt: createdAt,
      rawStoragePath: rawUpload.storagePath,
    );

    await refs.take60VideoDoc(videoId).set(take60Video);

    final scene = SceneModel(
      id: sceneId,
      title: title,
      category: category,
      thumbnailUrl: '',
      videoUrl: rawUpload.downloadUrl,
      durationSeconds: durationSeconds,
      author: user,
      createdAt: createdAt,
      tags: tags,
      take60VideoId: videoId,
      videoProcessingStatus: 'processing',
      isPremiumLocked: true,
    );

    await scenes.create(scene);
    return scene;
  }
}
