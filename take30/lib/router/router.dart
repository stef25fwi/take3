import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../admin/take30_admin_scene_flow.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../screens/auth_screen.dart';
import '../screens/badges_stats_screen.dart';
import '../screens/battle_screen.dart';
import '../screens/daily_challenge_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/home_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/main_shell.dart';
import '../screens/messages_screen.dart';
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
  static const messages = '/messages';
  static const challenge = '/challenge';
  static const battle = '/battle';
  static const badges = '/badges';
  static const leaderboard = '/leaderboard';
  static const admin = '/admin';
  static const preview = '/preview';
  static const sceneDetail = '/scene';

  static String profilePath(String userId) => '$profile/$userId';
  static String messagesPath(String userId) => '$messages/$userId';
  static String scenePath(String sceneId) => '$sceneDetail/$sceneId';
}

final appRouterNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.read(authServiceProvider);

  return GoRouter(
    navigatorKey: appRouterNavigatorKey,
    initialLocation: AppRouter.splash,
    refreshListenable: authService,
    redirect: (_, state) {
      final location = state.matchedLocation;
      final isAuthenticated = authService.isAuthenticated;
      final isAdmin = authService.currentUser?.isAdmin ?? false;
      final isPublicRoute = location == AppRouter.splash ||
          location == AppRouter.onboarding ||
          location == AppRouter.auth;

      if (location == '/') {
        return isAuthenticated ? AppRouter.home : AppRouter.splash;
      }

      if (location == AppRouter.admin) {
        if (!isAuthenticated) {
          return '${AppRouter.auth}?tab=login';
        }
        if (!isAdmin) {
          return AppRouter.home;
        }
        return null;
      }

      if (isAuthenticated && isPublicRoute) {
        return AppRouter.home;
      }

      return null;
    },
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
      GoRoute(
        path: AppRouter.admin,
        builder: (context, __) => AdminDashboardPage(
          onLogout: () => context.go(AppRouter.home),
          actionLabel: 'Retour',
        ),
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
          GoRoute(
            path: AppRouter.notifications,
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '${AppRouter.messages}/:userId',
            builder: (_, state) {
              final userId = state.pathParameters['userId']!;
              return MessagesScreen(userId: userId);
            },
          ),
          GoRoute(
            path: AppRouter.badges,
            builder: (_, __) => const BadgesStatsScreen(),
          ),
          GoRoute(
            path: AppRouter.leaderboard,
            builder: (_, __) => const LeaderboardScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRouter.challenge,
        builder: (_, __) => const DailyChallengeScreen(),
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
          return SceneDetailScreen(
            sceneId: sceneId,
            scene: state.extra is SceneModel ? state.extra as SceneModel : null,
          );
        },
      ),
    ],
  );
});
