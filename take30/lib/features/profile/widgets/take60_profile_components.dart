import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/shared_widgets.dart';
import '../models/take60_profile_stats.dart';
import '../models/take60_user_profile.dart';

class Take60ProfileHeader extends StatelessWidget {
  const Take60ProfileHeader({
    super.key,
    required this.profile,
    required this.stats,
    required this.isOwnProfile,
    required this.isCastingUpdating,
    this.onCastingModeChanged,
  });

  final Take60UserProfile profile;
  final Take60ProfileStats stats;
  final bool isOwnProfile;
  final bool isCastingUpdating;
  final ValueChanged<bool>? onCastingModeChanged;

  @override
  Widget build(BuildContext context) {
    final primaryText = AppThemeTokens.primaryText(context);
    final secondaryText = AppThemeTokens.secondaryText(context);
    final accent = Theme.of(context).colorScheme.primary;
    final location = [profile.regionName, profile.countryName]
        .where((value) => value.trim().isNotEmpty)
        .join(' • ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemeTokens.surface(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppThemeTokens.border(context)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0x180B1020),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Take60ProfileAvatar(
                userId: profile.userId,
                avatarUrl: profile.avatarUrl,
                size: 86,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${profile.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.roleLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final badge in profile.badgeLabels)
                Take60BadgeChip(label: badge),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            profile.bio,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Take60StatItem(
                  value: _formatCount(stats.scenesCount),
                  label: 'Scenes',
                  icon: Icons.movie_creation_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Take60StatItem(
                  value: _formatCount(stats.followersCount),
                  label: 'Followers',
                  icon: Icons.groups_2_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Take60StatItem(
                  value: _formatCount(stats.likesCount),
                  label: 'Likes',
                  icon: Icons.favorite_border_rounded,
                ),
              ),
            ],
          ),
          if (isOwnProfile && onCastingModeChanged != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppThemeTokens.surfaceMuted(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppThemeTokens.border(context)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.movie_filter_rounded,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode casting',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.castingModeEnabled
                              ? 'Votre profil remonte dans les opportunites et castings.'
                              : 'Activez le mode casting pour recevoir plus d\'opportunites.',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: profile.castingModeEnabled,
                    onChanged:
                        isCastingUpdating ? null : onCastingModeChanged,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class Take60BadgeChip extends StatelessWidget {
  const Take60BadgeChip({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final isAdmin = label.toLowerCase() == 'admin';
    final accent = isAdmin
        ? const Color(0xFFFF8A3D)
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings_rounded : Icons.verified_rounded,
            size: 14,
            color: accent,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class Take60StatItem extends StatelessWidget {
  const Take60StatItem({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppThemeTokens.surfaceMuted(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppThemeTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppThemeTokens.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }
}

class Take60SettingsSection extends StatelessWidget {
  const Take60SettingsSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
            title,
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppThemeTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppThemeTokens.secondaryText(context),
            ),
          ),
          const SizedBox(height: 14),
          ..._withSpacing(children),
        ],
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> widgets) {
    if (widgets.isEmpty) {
      return const [];
    }
    final result = <Widget>[];
    for (var index = 0; index < widgets.length; index++) {
      if (index > 0) {
        result.add(const SizedBox(height: 10));
      }
      result.add(widgets[index]);
    }
    return result;
  }
}

class Take60SettingsTile extends StatelessWidget {
  const Take60SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingText,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingText;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final primaryText = AppThemeTokens.primaryText(context);
    final secondaryText = AppThemeTokens.secondaryText(context);
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppThemeTokens.surfaceMuted(context),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing ??
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (trailingText != null) ...[
                        Text(
                          trailingText!,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: secondaryText,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: secondaryText,
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Take60ProfileAvatar extends StatelessWidget {
  const _Take60ProfileAvatar({
    required this.userId,
    required this.avatarUrl,
    required this.size,
  });

  final String userId;
  final String avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = avatarPhotoAssetForUserId(userId);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9A42),
            Color(0xFFFFB800),
            Color(0xFFFF6B2C),
          ],
        ),
      ),
      padding: const EdgeInsets.all(2.5),
      child: ClipOval(
        child: Container(
          color: const Color(0xFF111827),
          child: asset != null
              ? Image.asset(
                  asset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _NetworkAvatar(
                    avatarUrl: avatarUrl,
                    size: size,
                  ),
                )
              : _NetworkAvatar(avatarUrl: avatarUrl, size: size),
        ),
      ),
    );
  }
}

class _NetworkAvatar extends StatelessWidget {
  const _NetworkAvatar({
    required this.avatarUrl,
    required this.size,
  });

  final String avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      avatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF1A2540),
        child: Icon(
          Icons.person,
          size: size * 0.5,
          color: Colors.white38,
        ),
      ),
    );
  }
}

String _formatCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}