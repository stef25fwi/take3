import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/router.dart';
import '../widgets/shared_widgets.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  @override
  Widget build(BuildContext context) {
    return PageWrap(
      title: 'Défi du jour',
      leading: TakeHeaderButton(
        icon: Icons.arrow_back_rounded,
        onPressed: () => context.go(AppRouter.home),
      ),
      children: [
        const SizedBox(height: 8),
        const Center(child: Text('🎯', style: TextStyle(fontSize: 52))),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Lumière naturelle',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Capte une ambiance authentique en exploitant uniquement la lumière du jour.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0x99FFFFFF)),
        ),
        const SizedBox(height: 12),
        const _ChallengeCountdown(),
        const SectionCard(
          title: 'Récompenses',
          subtitle: '',
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              TakePill(label: '+150 XP', tone: TakePillTone.yellow),
              TakePill(label: 'Badge exclusif', tone: TakePillTone.cyan),
              TakePill(label: 'Top classement', tone: TakePillTone.purple),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () => context.push(AppRouter.record),
          child: const Text('🎬 Relever le défi'),
        ),
      ],
    );
  }
}

class _ChallengeCountdown extends StatefulWidget {
  const _ChallengeCountdown();

  @override
  State<_ChallengeCountdown> createState() => _ChallengeCountdownState();
}

class _ChallengeCountdownState extends State<_ChallengeCountdown> {
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Temps restant',
      subtitle: '',
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TakeCountdownBox(value: '08', label: 'h'),
          SizedBox(width: 8),
          TakeCountdownBox(value: '42', label: 'm'),
          SizedBox(width: 8),
          TakeCountdownBox(value: '15', label: 's'),
        ],
      ),
    );
  }
}
