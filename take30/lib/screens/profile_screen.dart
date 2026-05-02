import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../features/profile/models/take60_profile_stats.dart';
import '../features/profile/models/profile_activity_history.dart';
import '../features/profile/models/take60_user_profile.dart';
import '../features/profile/providers/take60_profile_providers.dart';
import '../features/profile/widgets/take60_profile_components.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../router/router.dart';
import '../theme/app_theme.dart';

// ──────────────────────────────────────────────────────────────────────────────
// PROFIL TALENT — Page 9 Pixel-Perfect
// ──────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authProvider).user;
    final profileState = ref.watch(profileProvider(userId));
    final user = profileState.user ??
        (authUser?.id == userId ? authUser : null);
    final scenes = profileState.scenes;
    final pageBackground = AppThemeTokens.pageBackground(context);
    final primaryText = AppThemeTokens.primaryText(context);

    if (user == null && profileState.isLoading) {
      return Scaffold(
        backgroundColor: pageBackground,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: pageBackground,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Profil introuvable.',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: pageBackground,
      body: _ProfileBody(userId: userId, user: user, scenes: scenes),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Body
// ──────────────────────────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({
    required this.userId,
    required this.user,
    required this.scenes,
  });

  final String userId;
  final UserModel user;
  final List<SceneModel> scenes;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isUpdatingCastingMode = false;
  bool _isUpdatingAutoInvites = false;
  bool _isUpdatingNotifications = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go(AppRouter.onboarding);
    }
  }

  Future<void> _updateCastingMode(bool enabled) async {
    setState(() => _isUpdatingCastingMode = true);
    try {
      await ref.read(take60ProfileServiceProvider).updateCastingMode(enabled);
      ref.invalidate(currentTake60UserProfileProvider);
      _showSavedMessage(
        enabled ? 'Mode casting active.' : 'Mode casting desactive.',
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingCastingMode = false);
      }
    }
  }

  Future<void> _updateAutoInvites(bool enabled) async {
    setState(() => _isUpdatingAutoInvites = true);
    try {
      await ref
          .read(take60ProfileServiceProvider)
          .updateAutoAcceptInvites(enabled);
      ref.invalidate(currentTake60UserProfileProvider);
      _showSavedMessage(
        enabled
            ? 'Invitations automatiques activees.'
            : 'Invitations automatiques desactivees.',
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAutoInvites = false);
      }
    }
  }

  Future<void> _updateNotifications(bool enabled) async {
    setState(() => _isUpdatingNotifications = true);
    try {
      await ref
          .read(take60ProfileServiceProvider)
          .updateNotificationsEnabled(enabled);
      ref.invalidate(currentTake60UserProfileProvider);
      _showSavedMessage(
        enabled ? 'Alertes push activees.' : 'Alertes push desactivees.',
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingNotifications = false);
      }
    }
  }

  void _showSavedMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authProvider.select((state) => state.user));
    final liveUser =
        ref.watch(profileProvider(widget.userId)).user ?? widget.user;
    final sceneCount = widget.scenes.length > 6 ? 6 : widget.scenes.length;
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final isOwnProfile = authUser?.id == widget.userId;
    final isDemoProfile = _isDemoProfile(liveUser);
    final canShowAdminDashboardButton = _canShowAdminDashboardButton(
      authUser,
      widget.userId,
    );
    final take60Profile = isOwnProfile
        ? (ref.watch(currentTake60UserProfileProvider).valueOrNull ??
            Take60UserProfile.fromUserModel(
              liveUser,
              darkModeEnabled: isDarkMode,
            ))
        : Take60UserProfile.fromUserModel(
            liveUser,
            darkModeEnabled: isDarkMode,
          );
    final take60Stats = isOwnProfile
        ? (ref.watch(currentTake60ProfileStatsProvider) ??
            Take60ProfileStats.fromUserModel(
              liveUser,
              scenesCount: widget.scenes.length,
            ))
        : Take60ProfileStats.fromUserModel(
            liveUser,
            scenesCount: widget.scenes.length,
          );
    final viewedHistoryAsync =
      isOwnProfile ? ref.watch(currentViewedSceneHistoryProvider) : null;
    final duelVoteHistoryAsync =
      isOwnProfile ? ref.watch(currentDuelVoteHistoryProvider) : null;
    final iconColor = AppThemeTokens.primaryText(context);
    final popupColor = AppThemeTokens.chromeSurface(context);
    final textColor = AppThemeTokens.primaryText(context);

    return Container(
      decoration: BoxDecoration(
        gradient: AppThemeTokens.pageGradient(context),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppThemeTokens.pageHorizontalPadding,
                      ),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: iconColor,
                                size: 22,
                              ),
                              color: popupColor,
                              onSelected: (value) {
                                switch (value) {
                                  case 'leaderboard':
                                    context.go(AppRouter.leaderboard);
                                  case 'badges':
                                    context.go(AppRouter.badges);
                                  case 'logout':
                                    _onLogout();
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'leaderboard',
                                  child: Text(
                                    'Voir le classement',
                                    style: GoogleFonts.dmSans(color: textColor),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'badges',
                                  child: Text(
                                    'Badges & stats',
                                    style: GoogleFonts.dmSans(color: textColor),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'logout',
                                  child: Text(
                                    'Se déconnecter',
                                    style: GoogleFonts.dmSans(
                                      color: const Color(0xFFFF6B6B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Take60ProfileHeader(
                            profile: take60Profile,
                            stats: take60Stats,
                            isOwnProfile: isOwnProfile,
                            isCastingUpdating: _isUpdatingCastingMode,
                            onCastingModeChanged:
                                isOwnProfile ? _updateCastingMode : null,
                          ),
                          const SizedBox(height: 18),
                          if (isOwnProfile)
                            _OwnProfileQuickActions(
                              onEditTap: () => context.go(AppRouter.profileEdit),
                              onMessageTap: () => context.go(AppRouter.messages),
                              onShareTap: () {
                                ref
                                    .read(profileProvider(widget.userId).notifier)
                                    .shareProfile();
                              },
                            )
                          else
                            _ActionButtons(
                              isFollowing: liveUser.isFollowing,
                              onFollowTap: () {
                                ref
                                    .read(profileProvider(widget.userId).notifier)
                                    .toggleFollow();
                              },
                              onMessageTap: () {
                                context.go(AppRouter.messages);
                              },
                              onShareTap: () {
                                ref
                                    .read(profileProvider(widget.userId).notifier)
                                    .shareProfile();
                              },
                            ),
                          if (canShowAdminDashboardButton) ...[
                            const SizedBox(height: 14),
                            _AdminDashboardButton(
                              onTap: () => context.push(AppRouter.admin),
                            ),
                          ],
                          if (isDemoProfile) ...[
                            const SizedBox(height: 14),
                            _ThemeToggleCard(
                              isDarkMode: isDarkMode,
                              onChanged: (value) {
                                ref.read(themeModeProvider.notifier).setMode(
                                      value ? ThemeMode.dark : ThemeMode.light,
                                    );
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(tabController: _tabCtrl),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppThemeTokens.pageHorizontalPadding,
                    ),
                    sliver: sceneCount == 0
                        ? SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Text(
                                'Aucune performance publiée pour l’instant.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.66),
                                ),
                              ),
                            ),
                          )
                        : SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.82,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final scene = widget.scenes[index];
                                return _PerformanceCard(
                                  scene: scene,
                                  index: index,
                                  onTap: () =>
                                      context.go(AppRouter.scenePath(scene.id)),
                                );
                              },
                              childCount: sceneCount,
                            ),
                          ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  if (isOwnProfile)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppThemeTokens.pageHorizontalPadding,
                        ),
                        child: Column(
                          children: [
                            _buildRankOverview(take60Stats),
                            const SizedBox(height: 16),
                            Take60SettingsSection(
                              title: 'Profil & activite',
                              subtitle:
                                  'Raccourcis rapides vers vos actions, statistiques et publication.',
                              children: [
                                Take60SettingsTile(
                                  icon: Icons.analytics_rounded,
                                  title: 'Tableau de bord',
                                  subtitle:
                                      'Badges, statistiques et synthese de vos performances.',
                                  trailingText: take60Stats.approvalRateLabel,
                                  onTap: () => context.go(AppRouter.profileDashboard),
                                ),
                                Take60SettingsTile(
                                  icon: Icons.video_call_rounded,
                                  title: 'Ajouter une scene',
                                  subtitle:
                                      'Demarrer un nouvel enregistrement ou une performance.',
                                  onTap: () => context.go(AppRouter.record),
                                ),
                                Take60SettingsTile(
                                  icon: Icons.folder_copy_rounded,
                                  title: 'Mes projets Take60',
                                  subtitle:
                                      'Retrouver vos brouillons, idees et travaux en cours.',
                                  onTap: () => context.go(AppRouter.profileProjects),
                                ),
                                Take60SettingsTile(
                                  icon: Icons.mail_outline_rounded,
                                  title: 'Messages',
                                  subtitle:
                                      'Consulter votre inbox et les discussions en cours.',
                                  onTap: () => context.go(AppRouter.messages),
                                ),
                                Take60SettingsTile(
                                  icon: Icons.mode_comment_outlined,
                                  title: 'Commentaires',
                                  subtitle:
                                      'Moderation et suivi des retours sur vos publications.',
                                  onTap: () => context.go(AppRouter.profileComments),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Take60SettingsSection(
                              title: 'Historique recent',
                              subtitle:
                                  'Retrouvez vos dernieres videos consultees et les duels pour lesquels vous avez vote.',
                              children: _buildHistorySectionChildren(
                                context,
                                viewedHistoryAsync,
                                duelVoteHistoryAsync,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Take60SettingsSection(
                              title: 'Classements & visibilite',
                              subtitle:
                                  'Pilotez votre presence locale, nationale et globale dans Take60.',
                              children: [
                                Take60SettingsTile(
                                  icon: Icons.place_rounded,
                                  title: 'Classement regional',
                                  subtitle:
                                      'Votre position dans votre region actuelle.',
                                  trailingText: _formatRank(take60Stats.regionalRank),
                                  onTap: () =>
                                      context.go(AppRouter.profileRegionalRanking),
                                ),
                                Take60SettingsTile(
                                  icon: Icons.flag_circle_rounded,
                                  title: 'Classement pays',
                                  subtitle:
                                      'Votre position dans votre pays sur Take60.',
                                  trailingText: _formatRank(take60Stats.countryRank),
                                  onTap: () =>
                                      context.go(AppRouter.profileCountryRanking),
                                ),
                                Take60SettingsTile(
                                  icon: Icons.public_rounded,
                                  title: 'Classement global',
                                  subtitle:
                                      'Votre position sur l\'ensemble de la plateforme.',
                                  trailingText: _formatRank(take60Stats.globalRank),
                                  onTap: () =>
                                      context.go(AppRouter.profileGlobalRanking),
                                ),
                                Take60SettingsTile(
                                  icon: Icons.visibility_outlined,
                                  title: 'Visibilite du compte',
                                  subtitle:
                                      'Choisir qui peut consulter votre profil complet.',
                                  trailingText:
                                      take60Profile.accountVisibility.label,
                                  onTap: () => context.go(AppRouter.profileVisibility),
                                ),
                                Take60SettingsTile(
                                  icon: Icons.ondemand_video_rounded,
                                  title: 'Visibilite des videos',
                                  subtitle:
                                      'Controler la diffusion par defaut de vos scenes.',
                                  trailingText:
                                      take60Profile.videoVisibility.label,
                                  onTap: () =>
                                      context.go(AppRouter.profileVideoVisibility),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Take60SettingsSection(
                              title: 'Casting & opportunites',
                              subtitle:
                                  'Activez les signaux qui vous rendent visible pour les castings.',
                              children: [
                                Take60SettingsTile(
                                  icon: Icons.movie_filter_rounded,
                                  title: 'Mode casting',
                                  subtitle:
                                      'Mettez votre profil en avant pour les opportunites.',
                                  trailing: Switch(
                                    value: take60Profile.castingModeEnabled,
                                    onChanged: _isUpdatingCastingMode
                                        ? null
                                        : _updateCastingMode,
                                  ),
                                ),
                                Take60SettingsTile(
                                  icon: Icons.auto_awesome_motion_rounded,
                                  title: 'Invitations automatiques',
                                  subtitle:
                                      'Recevoir les invitations premium sans validation manuelle.',
                                  trailing: Switch(
                                    value: take60Profile.autoAcceptInvites,
                                    onChanged: _isUpdatingAutoInvites
                                        ? null
                                        : _updateAutoInvites,
                                  ),
                                ),
                                Take60SettingsTile(
                                  icon: Icons.bookmark_added_rounded,
                                  title: 'Mes favoris',
                                  subtitle:
                                      'Scenes, talents et castings que vous avez sauvegardes.',
                                  onTap: () => context.go(AppRouter.profileBookmarks),
                                ),
                                Take60SettingsTile(
                                  icon: Icons.payments_outlined,
                                  title: 'Monetisation',
                                  subtitle:
                                      'Suivre revenus, primes et opportunites monetisees.',
                                  onTap: () => context.go(AppRouter.profileEarnings),
                                ),
                                Take60SettingsTile(
                                  icon: Icons.workspace_premium_outlined,
                                  title: 'Mon abonnement',
                                  subtitle:
                                      'Gerer votre formule premium et ses avantages.',
                                  onTap: () =>
                                      context.go(AppRouter.profileSubscription),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Take60SettingsSection(
                              title: 'Application & support',
                              subtitle:
                                  'Reglez les alertes, les permissions et l\'assistance du compte.',
                              children: [
                                Take60SettingsTile(
                                  icon: Icons.notifications_active_outlined,
                                  title: 'Alertes push',
                                  subtitle:
                                      'Activer ou couper les rappels et invitations instantanees.',
                                  trailing: Switch(
                                    value: take60Profile.notificationsEnabled,
                                    onChanged: _isUpdatingNotifications
                                        ? null
                                        : _updateNotifications,
                                  ),
                                ),
                                Take60SettingsTile(
                                  icon: Icons.notifications_none_rounded,
                                  title: 'Centre de notifications',
                                  subtitle:
                                      'Voir les alertes, nouveaux messages et activite recente.',
                                  onTap: () => context.go(AppRouter.notifications),
                                ),
                                Take60SettingsTile(
                                  icon: Icons.settings_applications_rounded,
                                  title: 'Permissions appareil',
                                  subtitle:
                                      'Verifier camera, micro, stockage et notifications.',
                                  onTap: () =>
                                      context.go(AppRouter.profileDevicePermissions),
                                ),
                                Take60SettingsTile(
                                  icon: Icons.edit_note_rounded,
                                  title: 'Modifier mon profil',
                                  subtitle:
                                      'Ajuster votre presentation, vos medias et votre univers.',
                                  onTap: () => context.go(AppRouter.profileEdit),
                                ),
                                Take60SettingsTile(
                                  icon: Icons.shield_outlined,
                                  title: 'Confidentialite & securite',
                                  subtitle:
                                      'Sessions, protection du compte et regles de confidentialite.',
                                  onTap: () => context.go(AppRouter.profileSecurity),
                                ),
                                Take60SettingsTile(
                                  icon: Icons.support_agent_rounded,
                                  title: 'Aide & support',
                                  subtitle:
                                      'FAQ, accompagnement et support Take60.',
                                  onTap: () => context.go(AppRouter.profileHelp),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Action Buttons
// ──────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isFollowing,
    required this.onFollowTap,
    required this.onMessageTap,
    required this.onShareTap,
  });

  final bool isFollowing;
  final VoidCallback onFollowTap;
  final VoidCallback onMessageTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: onFollowTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              decoration: BoxDecoration(
                color: isFollowing
                    ? AppThemeTokens.softAction(context)
                    : _C.purple,
                borderRadius: BorderRadius.circular(14),
                border: isFollowing
                    ? Border.all(
                        color: AppThemeTokens.softBorder(context))
                    : null,
              ),
              child: Center(
                child: Text(
                  isFollowing ? 'Abonné' : 'Suivre',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isFollowing
                        ? AppThemeTokens.primaryText(context)
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: onMessageTap,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppThemeTokens.softAction(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppThemeTokens.softBorder(context),
                ),
              ),
              child: Center(
                child: Text(
                  'Message',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppThemeTokens.primaryText(context),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onShareTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppThemeTokens.softAction(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppThemeTokens.softBorder(context),
              ),
            ),
            child: Icon(
              Icons.ios_share_rounded,
              color: AppThemeTokens.secondaryText(context),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _OwnProfileQuickActions extends StatelessWidget {
  const _OwnProfileQuickActions({
    required this.onEditTap,
    required this.onMessageTap,
    required this.onShareTap,
  });

  final VoidCallback onEditTap;
  final VoidCallback onMessageTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            label: 'Modifier',
            icon: Icons.edit_rounded,
            primary: true,
            onTap: onEditTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionButton(
            label: 'Messages',
            icon: Icons.mail_outline_rounded,
            onTap: onMessageTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionButton(
            label: 'Partager',
            icon: Icons.ios_share_rounded,
            onTap: onShareTap,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: primary ? accent : AppThemeTokens.softAction(context),
            borderRadius: BorderRadius.circular(16),
            border: primary
                ? null
                : Border.all(color: AppThemeTokens.softBorder(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: primary ? Colors.white : AppThemeTokens.primaryText(context),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color:
                      primary ? Colors.white : AppThemeTokens.primaryText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminDashboardButton extends StatelessWidget {
  const _AdminDashboardButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFA14A),
                Color(0xFFFF7A18),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7A18).withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard admin',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Gérer les scènes, VEO et publications',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Tab Bar Delegate (pinned)
// ──────────────────────────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate({required this.tabController});

  final TabController tabController;

  @override
  double get minExtent => 46;
  @override
  double get maxExtent => 46;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppThemeTokens.pageBackgroundAlt(context),
      child: Column(
        children: [
          Expanded(
            child: TabBar(
              controller: tabController,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorWeight: 2.0,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppThemeTokens.primaryText(context),
              labelStyle: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelColor: AppThemeTokens.tertiaryText(context),
              unselectedLabelStyle: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              dividerHeight: 0,
              tabs: const [
                Tab(text: 'Performances'),
                Tab(text: 'Activite'),
                Tab(text: 'Parametres'),
              ],
            ),
          ),
          Container(
            height: 0.5,
            color: AppThemeTokens.border(context),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      tabController != oldDelegate.tabController;
}

// ──────────────────────────────────────────────────────────────────────────────
// Performance Card
// ──────────────────────────────────────────────────────────────────────────────

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.scene,
    required this.index,
    required this.onTap,
  });

  final SceneModel scene;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final likeText = _fmtK(scene.likesCount);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            scene.thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFF1A2540)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.80),
                ],
                stops: const [0.0, 0.40, 0.70, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Row(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 14,
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.90),
                ),
                const SizedBox(width: 4),
                Text(
                  likeText,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.50),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _ThemeToggleCard extends StatelessWidget {
  const _ThemeToggleCard({
    required this.isDarkMode,
    required this.onChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppThemeTokens.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppThemeTokens.border(context)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0x120B1020),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppThemeTokens.surfaceMuted(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thème clair / sombre',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppThemeTokens.primaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDarkMode
                      ? 'Ambiance cinéma premium activée'
                      : 'Mode clair lumineux activé',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppThemeTokens.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDarkMode,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Palette
// ──────────────────────────────────────────────────────────────────────────────

class _C {
  static const purple = Color(0xFF6C5CE7);
}

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────

String _fmtK(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toString();
}

bool _isDemoProfile(UserModel user) {
  return user.id == 'demo_local' ||
      user.email == 'demo@take30.app' ||
      user.username == 'demo_take30';
}

bool _canShowAdminDashboardButton(UserModel? authUser, String profileUserId) {
  if (authUser == null) {
    return false;
  }
  if (_isDemoProfile(authUser)) {
    return false;
  }
  return authUser.isAdmin && authUser.id == profileUserId;
}

Widget _buildRankOverview(Take60ProfileStats stats) {
  return Builder(
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppThemeTokens.surface(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppThemeTokens.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Classements Take60',
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppThemeTokens.primaryText(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vue synthese de votre position regionale, pays et globale.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppThemeTokens.secondaryText(context),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Take60StatItem(
                    value: _formatRank(stats.regionalRank),
                    label: 'Region',
                    icon: Icons.place_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Take60StatItem(
                    value: _formatRank(stats.countryRank),
                    label: 'Pays',
                    icon: Icons.flag_circle_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Take60StatItem(
                    value: _formatRank(stats.globalRank),
                    label: 'Global',
                    icon: Icons.public_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

String _formatRank(int? rank) {
  if (rank == null || rank <= 0) {
    return '--';
  }
  return '#$rank';
}

List<Widget> _buildHistorySectionChildren(
  BuildContext context,
  AsyncValue<List<ProfileViewedSceneHistoryItem>>? historyAsync,
  AsyncValue<List<ProfileDuelVoteHistoryItem>>? duelHistoryAsync,
) {
  if (historyAsync == null || duelHistoryAsync == null) {
    return const [];
  }

  final viewedItems = historyAsync.valueOrNull;
  final duelItems = duelHistoryAsync.valueOrNull;

  if ((historyAsync.isLoading && viewedItems == null) ||
      (duelHistoryAsync.isLoading && duelItems == null)) {
    return const [
      _HistoryPlaceholderTile(
        icon: Icons.play_circle_outline_rounded,
        title: 'Chargement de l\'historique',
        subtitle: 'Preparation de vos dernieres activites...',
      ),
    ];
  }

  final entries = <_ProfileHistoryEntry>[
    for (final item in viewedItems ?? const <ProfileViewedSceneHistoryItem>[])
      _ViewedSceneHistoryEntry(item),
    for (final item in duelItems ?? const <ProfileDuelVoteHistoryItem>[])
      _DuelVoteHistoryEntry(item),
  ]
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  if (entries.isEmpty) {
    return const [
      _HistoryPlaceholderTile(
        icon: Icons.play_circle_outline_rounded,
        title: 'Aucune activite recente',
        subtitle: 'Vos videos vues et vos votes de duel apparaitront ici.',
      ),
    ];
  }

  final children = <Widget>[];
  String? previousDayKey;
  for (final entry in entries) {
    final dayKey = _historyDayKey(entry.timestamp);
    if (dayKey != previousDayKey) {
      children.add(
        _HistoryDateHeader(label: _formatHistoryGroupLabel(entry.timestamp)),
      );
      previousDayKey = dayKey;
    }
    children.add(entry.build(context));
  }
  return children;
}

String _historyDayKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String _formatHistoryGroupLabel(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final current = DateTime(value.year, value.month, value.day);
  final difference = today.difference(current).inDays;
  if (difference == 0) {
    return 'Aujourd\'hui';
  }
  if (difference == 1) {
    return 'Hier';
  }
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _formatHistoryTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day • $hour:$minute';
}

class _HistoryPlaceholderTile extends StatelessWidget {
  const _HistoryPlaceholderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Take60SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: null,
    );
  }
}

abstract class _ProfileHistoryEntry {
  DateTime get timestamp;
  Widget build(BuildContext context);
}

class _ViewedSceneHistoryEntry implements _ProfileHistoryEntry {
  const _ViewedSceneHistoryEntry(this.item);

  final ProfileViewedSceneHistoryItem item;

  @override
  DateTime get timestamp => item.viewedAt;

  @override
  Widget build(BuildContext context) {
    return _HistorySceneCard(item: item);
  }
}

class _DuelVoteHistoryEntry implements _ProfileHistoryEntry {
  const _DuelVoteHistoryEntry(this.item);

  final ProfileDuelVoteHistoryItem item;

  @override
  DateTime get timestamp => item.votedAt;

  @override
  Widget build(BuildContext context) {
    return _HistoryDuelCard(item: item);
  }
}

class _HistoryDateHeader extends StatelessWidget {
  const _HistoryDateHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final secondaryText = AppThemeTokens.secondaryText(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppThemeTokens.surfaceMuted(context),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppThemeTokens.border(context)),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: secondaryText,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: AppThemeTokens.border(context),
          ),
        ),
      ],
    );
  }
}

class _HistorySceneCard extends StatelessWidget {
  const _HistorySceneCard({required this.item});

  final ProfileViewedSceneHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return _HistoryCardShell(
      onTap: () => context.go(AppRouter.scenePath(item.sceneId)),
      leading: _HistoryThumbnail(
        imageUrl: item.thumbnailUrl,
        icon: Icons.play_circle_fill_rounded,
      ),
      label: 'Video vue',
      title: item.title,
      subtitle: 'par ${item.authorDisplayName}',
      meta: 'Consultee a ${_formatHistoryTime(item.viewedAt)}',
    );
  }
}

class _HistoryDuelCard extends StatelessWidget {
  const _HistoryDuelCard({required this.item});

  final ProfileDuelVoteHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return _HistoryCardShell(
      onTap: () => context.go(AppRouter.battle),
      leading: _HistoryDuelThumbnailStack(item: item),
      label: 'Duel vote',
      title: '${item.selectedSceneTitle} vs ${item.otherSceneTitle}',
      subtitle: 'Choix: ${item.votedForLabel}',
      meta: 'Vote enregistre a ${_formatHistoryTime(item.votedAt)}',
    );
  }
}

class _HistoryCardShell extends StatelessWidget {
  const _HistoryCardShell({
    required this.leading,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.meta,
    this.onTap,
  });

  final Widget leading;
  final String label;
  final String title;
  final String subtitle;
  final String meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primaryText = AppThemeTokens.primaryText(context);
    final secondaryText = AppThemeTokens.secondaryText(context);
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppThemeTokens.surfaceMuted(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppThemeTokens.border(context)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: secondaryText,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryThumbnail extends StatelessWidget {
  const _HistoryThumbnail({
    required this.imageUrl,
    required this.icon,
  });

  final String imageUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 76,
        height: 76,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _HistoryImage(imageUrl: imageUrl),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.34),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.all(6),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.48),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryDuelThumbnailStack extends StatelessWidget {
  const _HistoryDuelThumbnailStack({required this.item});

  final ProfileDuelVoteHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 76,
        height: 76,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _HistoryImage(imageUrl: item.selectedThumbnailUrl),
                  Container(
                    color: Colors.black.withValues(alpha: 0.18),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 2, color: AppThemeTokens.pageBackground(context)),
            Expanded(
              child: _HistoryImage(imageUrl: item.otherThumbnailUrl),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryImage extends StatelessWidget {
  const _HistoryImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder(context);
    }
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(context),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: AppThemeTokens.chromeSurface(context),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 22,
        color: AppThemeTokens.secondaryText(context),
      ),
    );
  }
}
