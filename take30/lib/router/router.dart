import 'package:flutter/material.dart';

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
  static const splash = '/';
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

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case auth:
        return MaterialPageRoute(builder: (_) => const AuthScreen());
      case shell:
        return MaterialPageRoute(builder: (_) => const MainShell());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case explore:
        return MaterialPageRoute(builder: (_) => const ExploreScreen());
      case record:
        return MaterialPageRoute(builder: (_) => const RecordScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case challenge:
        return MaterialPageRoute(builder: (_) => const DailyChallengeScreen());
      case battle:
        return MaterialPageRoute(builder: (_) => const BattleScreen());
      case badges:
        return MaterialPageRoute(builder: (_) => const BadgesStatsScreen());
      case leaderboard:
        return MaterialPageRoute(builder: (_) => const LeaderboardScreen());
      case preview:
        final draft = settings.arguments is TakeDraft
            ? settings.arguments as TakeDraft
            : const TakeDraft(
                title: 'Take démo',
                description: 'Prévisualisation rapide de la scène.',
                sceneType: 'Portrait créatif',
                duration: 30,
                mood: 'Énergique',
              );
        return MaterialPageRoute(builder: (_) => PreviewPublishScreen(draft: draft));
      case sceneDetail:
        final title = settings.arguments as String? ?? 'Détail';
        return MaterialPageRoute(builder: (_) => SceneDetailScreen(title: title));
      case splash:
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
