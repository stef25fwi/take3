import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/router.dart';
import '../widgets/shared_widgets.dart';

class BadgesStatsScreen extends StatelessWidget {
  const BadgesStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrap(
      title: 'Badges & Stats',
      leading: TakeHeaderButton(
        icon: Icons.arrow_back_rounded,
        onPressed: () => context.pop(),
      ),
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: const [
            _BadgeMiniBox(symbol: '🎬', label: 'Premier'),
            _BadgeMiniBox(symbol: '🔥', label: 'Streak x5'),
            _BadgeMiniBox(symbol: '⚔️', label: 'Duelliste active'),
            _BadgeMiniBox(symbol: '🏆', label: 'Champion'),
            _BadgeMiniBox(symbol: '🎨', label: 'Cinéaste'),
            _BadgeMiniBox(symbol: '💎', label: 'Diamant', faded: true),
          ],
        ),
        const SizedBox(height: 10),
        const SectionCard(
          title: 'Takes',
          subtitle: '4/7 pour débloquer la prochaine récompense',
          child: TakeProgressBar(value: 0.57, colors: [Color(0xFFFFB800), Color(0xFFFFB800)]),
        ),
        const SectionCard(
          title: 'Temps',
          subtitle: '5h42 de création cumulée',
          child: TakeProgressBar(value: 0.68, colors: [Color(0xFF00D4FF), Color(0xFF00D4FF)]),
        ),
        const SectionCard(
          title: 'Battles',
          subtitle: '8/12 affrontements complétés',
          child: TakeProgressBar(value: 0.66, colors: [Color(0xFF6C5CE7), Color(0xFF6C5CE7)]),
        ),
      ],
    );
  }
}

class _BadgeMiniBox extends StatelessWidget {
  const _BadgeMiniBox({
    required this.symbol,
    required this.label,
    this.faded = false,
  });

  final String symbol;
  final String label;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.4 : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Column(
          children: [
            Text(symbol, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0x99FFFFFF))),
          ],
        ),
      ),
    );
  }
}
