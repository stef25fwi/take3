import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
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
  static const shell = '/shell';
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
  static const sceneDetail = '/scene-detail';
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
        builder: (_, __) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRouter.shell,
        builder: (_, __) => const MainShell(),
      ),
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
        builder: (_, __) => const RecordScreen(),
      ),
      GoRoute(
        path: AppRouter.profile,
        builder: (_, __) => const ProfileScreen(),
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
        path: AppRouter.battle,
        builder: (_, __) => const BattleScreen(),
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
          final draft = state.extra is TakeDraft
              ? state.extra as TakeDraft
              : const TakeDraft(
                  title: 'Take démo',
                  description: 'Prévisualisation rapide de la scène.',
                  sceneType: 'Portrait créatif',
                  duration: 30,
                  mood: 'Énergique',
                );
          return PreviewPublishScreen(draft: draft);
        },
      ),
      GoRoute(
        path: AppRouter.sceneDetail,
        builder: (_, state) {
          final extra = state.extra;
          if (extra is SceneModel) {
            return SceneDetailScreen(title: extra.title, scene: extra);
          }
          final title = extra as String? ?? 'Détail';
          return SceneDetailScreen(title: title);
        },
      ),
    ],
  );
});
