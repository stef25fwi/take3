import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../services/mock_data.dart';
import '../screens/auth_screen.dart';
import '../screens/badges_stats_screen.dart';
import '../screens/battle_screen.dart';
import '../screens/daily_challenge_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/home_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/main_shell.dart';
import '../screens/notifications_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/preview_publish_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/record_screen.dart';
import '../screens/scene_detail_screen.dart';
import '../screens/splash_screen.dart';

class AppRouter {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const home = '/home';
  static const explore = '/explore';
  static const record = '/record';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const challenge = '/challenge';
  static const battle = '/battle';
  static const badges = '/badges';
  static const leaderboard = '/leaderboard';
  static const preview = '/preview';
  static const sceneDetail = '/scene';

  static String profilePath(String userId) => '$profile/$userId';
  static String scenePath(String sceneId) => '$sceneDetail/$sceneId';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRouter.splash,
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => AppRouter.splash,
      ),
      GoRoute(
        path: AppRouter.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRouter.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRouter.auth,
        builder: (_, state) {
          final tab = state.uri.queryParameters['tab'] ?? 'login';
          return AuthScreen(initialTab: tab);
        },
      ),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRouter.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRouter.explore,
            builder: (_, __) => const ExploreScreen(),
          ),
          GoRoute(
            path: AppRouter.record,
            builder: (_, state) {
              final scene = state.extra is SceneModel ? state.extra as SceneModel : null;
              return RecordScreen(scene: scene);
            },
          ),
          GoRoute(
            path: AppRouter.battle,
            builder: (_, __) => const BattleScreen(),
          ),
          GoRoute(
            path: '${AppRouter.profile}/:userId',
            builder: (_, state) {
              final userId = state.pathParameters['userId']!;
              return ProfileScreen(userId: userId);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRouter.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRouter.challenge,
        builder: (_, __) => const DailyChallengeScreen(),
      ),
      GoRoute(
        path: AppRouter.badges,
        builder: (_, __) => const BadgesStatsScreen(),
      ),
      GoRoute(
        path: AppRouter.leaderboard,
        builder: (_, __) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: AppRouter.preview,
        builder: (_, state) {
          final data = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null;
          return PreviewPublishScreen(
            videoPath: data?['videoPath'] as String?,
            scene: data?['scene'] as SceneModel?,
          );
        },
      ),
      GoRoute(
        path: '${AppRouter.sceneDetail}/:sceneId',
        builder: (_, state) {
          final sceneId = state.pathParameters['sceneId']!;
          SceneModel? scene;
          try {
            scene = MockData.scenes.firstWhere((item) => item.id == sceneId);
          } catch (_) {
            scene = null;
          }
          return SceneDetailScreen(
            title: scene?.title ?? 'Détail',
            scene: scene,
          );
        },
      ),
    ],
  );
});
