import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../router/router.dart';
import '../theme/app_theme.dart';

class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  static const Color backgroundTop = Color(0xFF08111F);
  static const Color backgroundBottom = Color(0xFF111827);
  static const Color surface = Color.fromRGBO(255, 255, 255, 0.045);
  static const Color surfaceBorder = Color.fromRGBO(255, 255, 255, 0.09);
  static const Color accent = Color(0xFFFFB800);
  static const Color accentText = Color(0xFF111827);
  static const double horizontalPadding = AppThemeTokens.pageHorizontalPadding;

  static const String heroAsset = 'assets/scenes/daily_challenge_spotlight.svg';
  static const String sceneTitle = 'Confrontation sous pression';
  static const String challengeQuote =
      'Tu n\'as plus d\'excuse. Regarde-moi et dis enfin la vérité.';

  static const List<_ChallengeRuleData> _rules = [
    _ChallengeRuleData(
      icon: Icons.timer_outlined,
      label: '60 secondes max',
    ),
    _ChallengeRuleData(
      icon: Icons.theater_comedy_outlined,
      label: 'Une intention forte dès la première seconde',
    ),
    _ChallengeRuleData(
      icon: Icons.send_outlined,
      label: 'Publie ta vidéo pour entrer dans le classement',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeTokens.pageBackground(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppThemeTokens.pageGradient(context),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              right: -40,
              child: _AmbientGlow(
                size: 220,
                color: Color.fromRGBO(255, 184, 0, 0.12),
              ),
            ),
            const Positioned(
              top: 160,
              left: -70,
              child: _AmbientGlow(
                size: 180,
                color: Color.fromRGBO(0, 212, 255, 0.08),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      horizontalPadding,
                      8,
                      horizontalPadding,
                      8,
                    ),
                    child: Column(
                      children: [
                        const _DailyChallengeHeader(),
                        const SizedBox(height: 16),
                        const Expanded(
                          child: _DailyChallengeCard(),
                        ),
                        const SizedBox(height: 16),
                        _ChallengePrimaryButton(
                          onTap: () => context.go(AppRouter.record),
                        ),
                        const SizedBox(height: 16),
                        const _IosHomeIndicator(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyChallengeHeader extends StatelessWidget {
  const _DailyChallengeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '🔥',
          style: TextStyle(
            fontSize: 17,
            height: 1,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Défi du jour',
          style: GoogleFonts.dmSans(
            color: AppThemeTokens.primaryText(context),
            fontSize: 23,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.45,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppThemeTokens.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppThemeTokens.border(context),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.28),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ChallengeHeroImage(),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 184, 0, 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color.fromRGBO(255, 184, 0, 0.24),
                ),
              ),
              child: Text(
                'CHALLENGE ACTING PREMIUM',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFFFFD56B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              DailyChallengeScreen.sceneTitle,
              style: GoogleFonts.dmSans(
                color: AppThemeTokens.primaryText(context),
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.55,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DailyChallengeScreen.challengeQuote,
              style: GoogleFonts.dmSans(
                color: AppThemeTokens.primaryText(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.24,
                letterSpacing: -0.15,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Conditions',
              style: GoogleFonts.dmSans(
                color: AppThemeTokens.secondaryText(context),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                children: DailyChallengeScreen._rules
                    .map(
                      (rule) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChallengeRuleRow(rule: rule),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeHeroImage extends StatelessWidget {
  const _ChallengeHeroImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 244,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.22),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2A1B16),
                    Color(0xFF15141B),
                  ],
                ),
              ),
            ),
            SvgPicture.asset(
              DailyChallengeScreen.heroAsset,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.06),
                    Color.fromRGBO(0, 0, 0, 0.16),
                    Color.fromRGBO(0, 0, 0, 0.26),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 14,
              top: 14,
              child: _HeroBadge(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(8, 17, 31, 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.16),
        ),
      ),
      child: Text(
        'SCÈNE EXCLUSIVE',
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

class _ChallengeRuleRow extends StatelessWidget {
  const _ChallengeRuleRow({required this.rule});

  final _ChallengeRuleData rule;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 184, 0, 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              rule.icon,
              size: 18,
              color: const Color(0xFFFFD56B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rule.label,
              style: GoogleFonts.dmSans(
                color: const Color.fromRGBO(255, 255, 255, 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.24,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengePrimaryButton extends StatelessWidget {
  const _ChallengePrimaryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFD96A),
                  DailyChallengeScreen.accent,
                  Color(0xFFF2A600),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, 0.18),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(255, 184, 0, 0.22),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.22),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Relever le défi',
                        style: GoogleFonts.dmSans(
                          color: DailyChallengeScreen.accentText,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.25,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: DailyChallengeScreen.accentText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IosHomeIndicator extends StatelessWidget {
  const _IosHomeIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 132,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.45,
              spreadRadius: size * 0.1,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeRuleData {
  const _ChallengeRuleData({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}