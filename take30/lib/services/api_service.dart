import '../models/models.dart';
import 'mock_data.dart';

class ApiService {
  Future<List<FeatureItem>> fetchDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return dashboardItems;
  }

  Future<List<NotificationItem>> fetchNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return notifications;
  }

  Future<List<SceneIdea>> fetchScenes() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return sceneIdeas;
  }

  Future<UserStats> fetchProfileStats() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return profileStats;
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return leaderboard;
  }
}
