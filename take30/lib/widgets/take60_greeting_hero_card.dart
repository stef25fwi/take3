import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';

class Take60GreetingHeroCard extends StatelessWidget {
  const Take60GreetingHeroCard({
    super.key,
    required this.user,
    required this.scenesValue,
    required this.likesValue,
    this.formatValue = '60s',
    this.onPrimaryTap,
    this.onSecondaryTap,
    this.primaryLabel = 'Nouvelle vidéo',
    this.secondaryLabel = 'Voir le défi',
    this.showActions = true,
  });

  final UserModel user;
  final String formatValue;
  final String scenesValue;
  final String likesValue;
  final VoidCallback? onPrimaryTap;
  final VoidCallback? onSecondaryTap;
  final String primaryLabel;
  final String secondaryLabel;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeTokens.isDark(context);
    final primaryText = AppThemeTokens.primaryText(context);
    final secondaryText = AppThemeTokens.secondaryText(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color.fromRGBO(255, 184, 0, 0.20),
                  Color.fromRGBO(0, 212, 255, 0.12),
                  Color.fromRGBO(108, 92, 231, 0.18),
                ]
              : const [
                  Color(0xFFFFF7DA),
                  Color(0xFFEAF8FF),
                  Color(0xFFF2EEFF),
                ],
        ),
        border: Border.all(color: AppThemeTokens.border(context)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.20),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                url: user.avatarUrl,
                userId: user.id,
                size: 46,
                showBorder: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour ${user.displayName}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prêt à tourner une performance qui marque ?',
                      style: GoogleFonts.dmSans(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                        height: 1.05,
                        letterSpacing: -0.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroStat(value: formatValue, label: 'Format'),
              const SizedBox(width: 18),
              _HeroStat(value: scenesValue, label: 'Scènes'),
              const SizedBox(width: 18),
              _HeroStat(value: likesValue, label: 'Likes'),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _HeroPrimaryButton(
                    label: primaryLabel,
                    onTap: onPrimaryTap,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroGhostButton(
                    label: secondaryLabel,
                    onTap: onSecondaryTap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppThemeTokens.primaryText(context),
            letterSpacing: -0.25,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppThemeTokens.secondaryText(context),
          ),
        ),
      ],
    );
  }
}

class _HeroPrimaryButton extends StatelessWidget {
  const _HeroPrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFD96A), Color(0xFFFFB800), Color(0xFFF2A600)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(255, 184, 0, 0.20),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroGhostButton extends StatelessWidget {
  const _HeroGhostButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: AppThemeTokens.softAction(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeTokens.softBorder(context)),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppThemeTokens.primaryText(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
