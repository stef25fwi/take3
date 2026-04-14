import '../models/models.dart';
import 'mock_data.dart';

class ApiService {
  ApiService._internal();

  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  bool _isAuthenticated = false;
  UserModel? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  UserModel? get currentUser => _currentUser;

  Future<UserModel> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _isAuthenticated = true;
    _currentUser = MockData.users.first;
    return _currentUser!;
  }

  Future<UserModel> register(String username, String email, String password) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    _isAuthenticated = true;
    _currentUser = MockData.users.first.copyWith();
    return _currentUser!;
  }

  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _isAuthenticated = false;
    _currentUser = null;
  }

  Future<List<SceneModel>> getFeed({int page = 0}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return MockData.scenes;
  }

  Future<List<SceneModel>> getPopularScenes(String category) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (category == 'all') {
      return MockData.scenes;
    }
    return MockData.scenes
        .where((scene) => scene.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  Future<List<CategoryModel>> getCategories() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return MockData.categories;
  }

  Future<bool> likeScene(String sceneId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return true;
  }

  Future<bool> followUser(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return true;
  }

  Future<List<LeaderboardEntry>> getLeaderboard(String period) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return MockData.leaderboard;
  }

  Future<UserModel> getProfile(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return MockData.users.firstWhere(
      (user) => user.id == userId,
      orElse: () => MockData.users.first,
    );
  }

  Future<List<SceneModel>> getUserScenes(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return MockData.scenes.where((scene) => scene.author.id == userId).toList();
  }

  Future<List<BadgeModel>> getBadges(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return MockData.badges;
  }

  Future<DuelModel> getCurrentDuel() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return MockData.currentDuel;
  }

  Future<DuelModel> vote(String duelId, int choice) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final duel = MockData.currentDuel;
    return duel.copyWith(
      userVote: choice,
      votesA: choice == 0 ? duel.votesA + 1 : duel.votesA,
      votesB: choice == 1 ? duel.votesB + 1 : duel.votesB,
    );
  }

  Future<List<NotificationModel>> getNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return MockData.notifications;
  }

  Future<DailyChallengeModel> getDailyChallenge() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return MockData.dailyChallenge;
  }

  Future<SceneModel> uploadScene({
    required String videoPath,
    required String title,
    required String category,
    required List<String> tags,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return SceneModel(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      thumbnailUrl: 'https://images.unsplash.com/photo-1542513217-0b0eeea7f7bc?w=400',
      videoUrl: videoPath,
      durationSeconds: 28,
      author: _currentUser ?? MockData.users.first,
      createdAt: DateTime.now(),
      tags: tags,
    );
  }
}
