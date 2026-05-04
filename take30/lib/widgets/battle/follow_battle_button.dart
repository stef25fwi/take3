import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/battle_providers.dart';

class FollowBattleButton extends ConsumerStatefulWidget {
  const FollowBattleButton({super.key, required this.battleId});

  final String battleId;

  @override
  ConsumerState<FollowBattleButton> createState() => _FollowBattleButtonState();
}

class _FollowBattleButtonState extends ConsumerState<FollowBattleButton> {
  bool _loading = false;
  bool _following = false;

  Future<void> _toggle() async {
    setState(() => _loading = true);
    try {
      final service = ref.read(battleServiceProvider);
      if (_following) {
        await service.unfollowBattle(widget.battleId);
      } else {
        await service.followBattle(widget.battleId);
      }
      if (mounted) {
        setState(() => _following = !_following);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _loading ? null : _toggle,
      icon: _loading
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_following ? Icons.notifications_active : Icons.notifications_none),
      label: Text(_following ? 'Battle suivie' : 'Suivre cette Battle'),
    );
  }
}
