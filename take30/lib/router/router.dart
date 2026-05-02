import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../admin/take30_admin_scene_flow.dart';
import '../features/profile/models/take60_user_profile.dart';
import '../features/profile/providers/take60_profile_providers.dart';
import '../features/profile/screens/take60_permissions_screen.dart';
import '../features/profile/screens/take60_placeholder_screen.dart';
import '../features/profile/screens/take60_simple_settings_screen.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../screens/auth_screen.dart';
import '../screens/badges_stats_screen.dart';
import '../screens/battle_screen.dart';
import '../screens/daily_challenge_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/explorer_ranking_screen.dart';
import '../screens/home_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/main_shell.dart';
import '../screens/messages_inbox_screen.dart';
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
  static const adminAccess = '/admin-access';
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
  static const explorerRankingRegional = '/explore/ranking/regional';
  static const explorerRankingNational = '/explore/ranking/national';
  static const profileDashboard = '/profile/dashboard';
  static const profileRegionalRanking = '/profile/rankings/regional';
  static const profileCountryRanking = '/profile/rankings/country';
  static const profileGlobalRanking = '/profile/rankings/global';
  static const profileEdit = '/profile/edit';
  static const profileProjects = '/profile/projects';
  static const profileBookmarks = '/profile/bookmarks';
  static const profileComments = '/profile/comments';
  static const profileEarnings = '/profile/earnings';
  static const profileSubscription = '/profile/subscription';
  static const profileVisibility = '/profile/settings/visibility';
  static const profileVideoVisibility = '/profile/settings/video-visibility';
  static const profileDevicePermissions = '/profile/settings/device-permissions';
  static const profileSecurity = '/profile/settings/security';
  static const profileHelp = '/profile/settings/help';

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

      if (location == '/') {
        return AppRouter.splash;
      }

      if (location == AppRouter.admin) {
        if (!isAuthenticated) {
          final redirect = Uri.encodeComponent(AppRouter.admin);
          return '${AppRouter.auth}?tab=login&mode=admin&redirect=$redirect';
        }
        if (!isAdmin) {
          return AppRouter.home;
        }
        return null;
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
          final redirect = state.uri.queryParameters['redirect'];
          return AuthScreen(initialTab: tab, redirectTo: redirect);
        },
      ),
      GoRoute(
        path: AppRouter.adminAccess,
        redirect: (_, __) =>
            '${AppRouter.auth}?tab=login&mode=admin&redirect=${Uri.encodeComponent(AppRouter.admin)}',
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
            path: AppRouter.profileDashboard,
            builder: (_, __) => const BadgesStatsScreen(),
          ),
          GoRoute(
            path: AppRouter.profileRegionalRanking,
            builder: (_, __) => const ExplorerRankingScreen(
              scope: ExplorerRankingScope.regional,
            ),
          ),
          GoRoute(
            path: AppRouter.profileCountryRanking,
            builder: (_, __) => const ExplorerRankingScreen(
              scope: ExplorerRankingScope.national,
            ),
          ),
          GoRoute(
            path: AppRouter.profileGlobalRanking,
            builder: (_, __) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: AppRouter.profileEdit,
            builder: (_, __) => const Take60PlaceholderScreen(
              title: 'Modifier mon profil',
              description:
                  'La version premium de l\'edition de profil arrive. Les informations actuelles restent intactes.',
              icon: Icons.edit_rounded,
            ),
          ),
          GoRoute(
            path: AppRouter.profileProjects,
            builder: (_, __) => const Take60PlaceholderScreen(
              title: 'Mes projets Take60',
              description:
                  'Retrouvez bientot vos brouillons, enregistrements et projets en cours depuis cet espace dedie.',
              icon: Icons.folder_copy_rounded,
            ),
          ),
          GoRoute(
            path: AppRouter.profileBookmarks,
            builder: (_, __) => const Take60PlaceholderScreen(
              title: 'Mes favoris',
              description:
                  'Cette zone premium centralisera scenes, talents et castings sauvegardes.',
              icon: Icons.bookmark_rounded,
            ),
          ),
          GoRoute(
            path: AppRouter.profileComments,
            builder: (_, __) => const Take60PlaceholderScreen(
              title: 'Commentaires',
              description:
                  'Le centre de moderation des commentaires sera branche ici sans casser le profil existant.',
              icon: Icons.mode_comment_rounded,
            ),
          ),
          GoRoute(
            path: AppRouter.profileEarnings,
            builder: (_, __) => const Take60PlaceholderScreen(
              title: 'Monetisation',
              description:
                  'Le suivi des revenus, abonnements et primes Take60 sera ajoute dans cette vue premium.',
              icon: Icons.payments_rounded,
            ),
          ),
          GoRoute(
            path: AppRouter.profileSubscription,
            builder: (_, __) => const Take60PlaceholderScreen(
              title: 'Mon abonnement',
              description:
                  'La gestion de l\'offre premium, du renouvellement et des avantages sera disponible ici.',
              icon: Icons.workspace_premium_rounded,
            ),
          ),
          GoRoute(
            path: AppRouter.profileVisibility,
            builder: (_, __) => Consumer(
              builder: (context, ref, child) {
                final profile =
                    ref.watch(currentTake60UserProfileProvider).valueOrNull;
                return Take60SimpleSettingsScreen(
                  title: 'Visibilite du compte',
                  subtitle:
                      'Choisissez qui peut consulter votre profil et votre activite Take60.',
                  currentValue:
                      profile?.accountVisibility.storageValue ?? 'public',
                  options: const [
                    Take60SettingsOption(
                      value: 'public',
                      title: 'Profil public',
                      description:
                          'Visible dans tout Take60 et depuis les liens publics.',
                    ),
                    Take60SettingsOption(
                      value: 'talents_only',
                      title: 'Talents uniquement',
                      description:
                          'Visible completement seulement pour les talents connectes.',
                    ),
                    Take60SettingsOption(
                      value: 'private',
                      title: 'Profil prive',
                      description:
                          'Visible uniquement via vos acces directs et invitations.',
                    ),
                  ],
                  onSelected: (ref, value) async {
                    await ref.read(take60ProfileServiceProvider).updateAccountVisibility(
                          Take60AccountVisibilityX.fromStorage(value),
                        );
                    ref.invalidate(currentTake60UserProfileProvider);
                  },
                );
              },
            ),
          ),
          GoRoute(
            path: AppRouter.profileVideoVisibility,
            builder: (_, __) => Consumer(
              builder: (context, ref, child) {
                final profile =
                    ref.watch(currentTake60UserProfileProvider).valueOrNull;
                return Take60SimpleSettingsScreen(
                  title: 'Visibilite des videos',
                  subtitle:
                      'Definissez la diffusion par defaut de vos performances Take60.',
                  currentValue: profile?.videoVisibility.storageValue ?? 'public',
                  options: const [
                    Take60SettingsOption(
                      value: 'public',
                      title: 'Videos publiques',
                      description:
                          'Vos performances restent visibles depuis le profil et l\'exploration.',
                    ),
                    Take60SettingsOption(
                      value: 'subscribers_only',
                      title: 'Abonnes uniquement',
                      description:
                          'Les performances sont reservees a votre audience abonnee.',
                    ),
                    Take60SettingsOption(
                      value: 'private',
                      title: 'Videos privees',
                      description:
                          'Les videos ne sont visibles que si vous les partagez explicitement.',
                    ),
                  ],
                  onSelected: (ref, value) async {
                    await ref.read(take60ProfileServiceProvider).updateVideoVisibility(
                          Take60VideoVisibilityX.fromStorage(value),
                        );
                    ref.invalidate(currentTake60UserProfileProvider);
                  },
                );
              },
            ),
          ),
          GoRoute(
            path: AppRouter.profileDevicePermissions,
            builder: (_, __) => const Take60PermissionsScreen(),
          ),
          GoRoute(
            path: AppRouter.profileSecurity,
            builder: (_, __) => const Take60PlaceholderScreen(
              title: 'Confidentialite et securite',
              description:
                  'Les options de securite avancees et le journal de connexion seront ajoutes ici.',
              icon: Icons.lock_rounded,
            ),
          ),
          GoRoute(
            path: AppRouter.profileHelp,
            builder: (_, __) => const Take60PlaceholderScreen(
              title: 'Aide et support',
              description:
                  'Cette page centralisera FAQ, contact support et diagnostic rapide de votre compte.',
              icon: Icons.support_agent_rounded,
            ),
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
            path: AppRouter.messages,
            builder: (_, __) => const MessagesInboxScreen(),
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
          GoRoute(
            path: AppRouter.explorerRankingRegional,
            builder: (_, __) => const ExplorerRankingScreen(
              scope: ExplorerRankingScope.regional,
            ),
          ),
          GoRoute(
            path: AppRouter.explorerRankingNational,
            builder: (_, __) => const ExplorerRankingScreen(
              scope: ExplorerRankingScope.national,
            ),
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
