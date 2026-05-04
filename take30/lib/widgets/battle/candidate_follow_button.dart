import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/battle_providers.dart';

class CandidateFollowButton extends ConsumerStatefulWidget {
  const CandidateFollowButton({super.key, required this.candidateId});

  final String candidateId;

  @override
  ConsumerState<CandidateFollowButton> createState() => _CandidateFollowButtonState();
}

class _CandidateFollowButtonState extends ConsumerState<CandidateFollowButton> {
  bool _loading = false;
  bool _following = false;

  Future<void> _toggle() async {
    setState(() => _loading = true);
    try {
      final service = ref.read(battleServiceProvider);
      if (_following) {
        await service.unfollowCandidate(widget.candidateId);
      } else {
        await service.followCandidate(widget.candidateId);
      }
      if (mounted) setState(() => _following = !_following);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _toggle,
      icon: Icon(_following ? Icons.check_circle_outline : Icons.person_add_alt_1),
      label: Text(_following ? 'Suivi' : 'Suivre'),
    );
  }
}
