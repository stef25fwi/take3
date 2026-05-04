import 'package:flutter/material.dart';

class BattleCountdownChip extends StatelessWidget {
  const BattleCountdownChip({super.key, required this.remaining});

  final Duration? remaining;

  @override
  Widget build(BuildContext context) {
    final value = remaining;
    final label = value == null
        ? 'Délai à venir'
        : value == Duration.zero
            ? 'Délai écoulé'
            : _format(value);
    return Chip(
      avatar: const Icon(Icons.timer_outlined, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }

  String _format(Duration value) {
    final hours = value.inHours;
    if (hours >= 24) {
      return '${value.inDays}j ${hours % 24}h restantes';
    }
    if (hours > 0) {
      return '${hours}h ${value.inMinutes % 60}min restantes';
    }
    return '${value.inMinutes}min restantes';
  }
}
