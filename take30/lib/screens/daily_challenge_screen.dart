import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/providers.dart';
import '../router/router.dart';
import '../theme/app_theme.dart';

class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChallenge = ref.watch(dailyChallengeProvider);
    return Scaffold(
      backgroundColor: ChallengeTheme.background,
      appBar: AppBar(
        backgroundColor: ChallengeTheme.appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 20),
          onPressed: () => context.go(AppRouter.home),
        ),
        title: Text(
          'Défi du jour',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: asyncChallenge.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.yellow),
        ),
        error: (_, __) => const Center(child: Text('Erreur')),
        data: (challenge) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 8),
              Text(
                challenge.sceneTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Capte une ambiance authentique en exploitant uniquement la lumière du jour.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Text(
                      'Temps restant',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Countdown(expiresAt: challenge.expiresAt),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Text(
                      'Récompenses',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: const [
                        _RewardChip(label: '+150 XP', color: AppColors.yellow),
                        _RewardChip(label: 'Badge exclusif', color: AppColors.cyan),
                        _RewardChip(label: 'Top classement', color: AppColors.purple),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRouter.record),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Relever le défi',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Countdown extends StatefulWidget {
  const _Countdown({required this.expiresAt});

  final DateTime expiresAt;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.expiresAt.difference(DateTime.now());
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _remaining = widget.expiresAt.difference(DateTime.now());
        });
        _tick();
      }
    });
  }

  String get _formatted {
    if (_remaining.isNegative) {
      return 'Expiré';
    }
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${hours}h ${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final parts = _remaining.isNegative
        ? const ['00', '00', '00']
        : [
            _remaining.inHours.toString().padLeft(2, '0'),
            _remaining.inMinutes.remainder(60).toString().padLeft(2, '0'),
            _remaining.inSeconds.remainder(60).toString().padLeft(2, '0'),
          ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CountdownBox(value: parts[0], label: 'h'),
        const SizedBox(width: 8),
        _CountdownBox(value: parts[1], label: 'm'),
        const SizedBox(width: 8),
        _CountdownBox(value: parts[2], label: 's'),
      ],
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _CountdownBox extends StatelessWidget {
  const _CountdownBox({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 64),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
