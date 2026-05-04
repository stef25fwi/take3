import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/battle_providers.dart';
import '../../providers/providers.dart';
import '../../router/router.dart';
import '../../widgets/battle/battle_candidate_faceoff.dart';
import '../../widgets/battle/battle_countdown_chip.dart';
import '../../widgets/battle/battle_status_badge.dart';
import '../../widgets/battle/candidate_follow_button.dart';
import '../../widgets/battle/follow_battle_button.dart';

class BattleDetailScreen extends ConsumerWidget {
  const BattleDetailScreen({super.key, required this.battleId});

  final String battleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(battleByIdProvider(battleId));
    return Scaffold(
      appBar: AppBar(title: const Text('Battle')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Ce duel n’est plus disponible.')),
        data: (battle) {
          if (battle == null) {
            return const Center(child: Text('Ce duel n’est plus disponible.'));
          }
          return _BattleDetailBody(battle: battle);
        },
      ),
    );
  }
}

class _BattleDetailBody extends ConsumerStatefulWidget {
  const _BattleDetailBody({required this.battle});

  final BattleModel battle;

  @override
  ConsumerState<_BattleDetailBody> createState() => _BattleDetailBodyState();
}

class _BattleDetailBodyState extends ConsumerState<_BattleDetailBody> {
  bool _loading = false;
  bool _watchedChallenger = false;
  bool _watchedOpponent = false;

  String _formatFeaturedUntil(DateTime? value) {
    if (value == null) {
      return 'Mise en avant inactive.';
    }
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year;
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return 'À la une jusqu’au $day/$month/$year à $hour:$minute';
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      }
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
    final battle = widget.battle;
    final authUser = ref.watch(authProvider).user;
    final uid = authUser?.id ?? '';
    final isAdmin = authUser?.isAdmin ?? false;
    final isOpponent = uid == battle.opponentId;
    final isParticipant = battle.participantIds.contains(uid);
    final canVote = battle.canVote(uid) && _watchedChallenger && _watchedOpponent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BattleStatusBadge(status: battle.status),
                    const Spacer(),
                    BattleCountdownChip(remaining: battle.timeRemaining),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '${battle.challengerName} vs ${battle.opponentName}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(battle.shareSubtitle.isEmpty
                    ? 'Même scène. Même délai. Deux interprétations. Un seul gagnant.'
                    : battle.shareSubtitle),
                const SizedBox(height: 18),
                BattleCandidateFaceoff(
                  battle: battle,
                  onTapChallenger: () => context.go(AppRouter.profilePath(battle.challengerId)),
                  onTapOpponent: () => context.go(AppRouter.profilePath(battle.opponentId)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CandidateFollowButton(candidateId: battle.challengerId),
                    const SizedBox(width: 8),
                    CandidateFollowButton(candidateId: battle.opponentId),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  battle.sceneTitle ?? 'Scène Battle Take60',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(battle.themeTitle ?? 'La scène est tombée.'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    if (battle.sceneCategory != null) Chip(label: Text(battle.sceneCategory!)),
                    if (battle.sceneDifficulty != null) Chip(label: Text(battle.sceneDifficulty!)),
                    if (battle.isFeatured) const Chip(label: Text('À la une')),
                    if (battle.watchersCount > 0) Chip(label: Text('${battle.watchersCount} en vue')),
                    Chip(label: Text('${battle.followersCount} suivent')),
                    if (battle.battleScore > 0) Chip(label: Text('Score ${battle.battleScore.toStringAsFixed(0)}')),
                    if (battle.trendingScore > 0) Chip(label: Text('Tendance ${battle.trendingScore.toStringAsFixed(0)}')),
                    Chip(label: Text('${battle.totalVotes} votes')),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isAdmin) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Curation admin',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(_formatFeaturedUntil(battle.featuredUntil)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _loading
                            ? null
                            : () => _run(
                                  () => ref
                                      .read(battleServiceProvider)
                                      .setBattleFeatured(
                                        battleId: battle.id,
                                        isFeatured: true,
                                        featuredHours: 72,
                                      ),
                                  battle.isFeatured
                                      ? 'Mise en avant prolongée pour 72h.'
                                      : 'Battle mise à la une pour 72h.',
                                ),
                        icon: const Icon(Icons.workspace_premium_rounded),
                        label: Text(
                          battle.isFeatured
                              ? 'Prolonger 72h'
                              : 'Mettre à la une 72h',
                        ),
                      ),
                      if (battle.isFeatured)
                        OutlinedButton.icon(
                          onPressed: _loading
                              ? null
                              : () => _run(
                                    () => ref
                                        .read(battleServiceProvider)
                                        .setBattleFeatured(
                                          battleId: battle.id,
                                          isFeatured: false,
                                        ),
                                    'Mise en avant retirée.',
                                  ),
                          icon: const Icon(Icons.remove_circle_outline),
                          label: const Text('Retirer de la une'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (battle.isPending)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isOpponent ? 'Nouveau défi reçu' : 'Défi en attente'),
                  const SizedBox(height: 8),
                  const Text('Un acteur de ton niveau veut t’affronter.'),
                  if (isOpponent) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: _loading
                              ? null
                              : () => _run(
                                    () => ref.read(battleServiceProvider).respondToChallenge(
                                          battleId: battle.id,
                                          accept: true,
                                        ),
                                    'Duel accepté. La scène est tombée.',
                                  ),
                          child: const Text('Accepter'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () => _run(
                                    () => ref.read(battleServiceProvider).respondToChallenge(
                                          battleId: battle.id,
                                          accept: false,
                                        ),
                                    'Le candidat n’est pas disponible pour ce duel.',
                                  ),
                          child: const Text('Refuser'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (battle.isInPreparation)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Les deux candidats préparent leur performance.'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FollowBattleButton(battleId: battle.id),
                      OutlinedButton.icon(
                        onPressed: _loading
                            ? null
                            : () => _run(
                                  () => ref.read(battleServiceProvider).predictBattleWinner(
                                        battleId: battle.id,
                                        predictedWinnerId: battle.challengerId,
                                      ),
                                  'Pronostic enregistré.',
                                ),
                        icon: const Icon(Icons.auto_graph),
                        label: const Text('Faire mon pronostic'),
                      ),
                      if (isParticipant)
                        FilledButton.icon(
                          onPressed: () => context.go(AppRouter.battleRecordPath(battle.id), extra: battle),
                          icon: const Icon(Icons.videocam),
                          label: const Text('Créer ma vidéo'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (battle.isVotingOpen)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Regarde les deux performances, puis choisis ton interprétation préférée.'),
                  CheckboxListTile(
                    value: _watchedChallenger,
                    onChanged: (value) => setState(() => _watchedChallenger = value ?? false),
                    title: Text('Performance de ${battle.challengerName} vue'),
                  ),
                  CheckboxListTile(
                    value: _watchedOpponent,
                    onChanged: (value) => setState(() => _watchedOpponent = value ?? false),
                    title: Text('Performance de ${battle.opponentName} vue'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: canVote
                              ? () => _run(
                                    () => ref.read(battleServiceProvider).voteBattle(
                                          battleId: battle.id,
                                          votedForUserId: battle.challengerId,
                                          watchProgressChallenger: 1,
                                          watchProgressOpponent: 1,
                                        ),
                                    'Vote enregistré.',
                                  )
                              : null,
                          child: Text('Voter ${battle.challengerName}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: canVote
                              ? () => _run(
                                    () => ref.read(battleServiceProvider).voteBattle(
                                          battleId: battle.id,
                                          votedForUserId: battle.opponentId,
                                          watchProgressChallenger: 1,
                                          watchProgressOpponent: 1,
                                        ),
                                    'Vote enregistré.',
                                  )
                              : null,
                          child: Text('Voter ${battle.opponentName}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (battle.isEnded)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Le public a tranché.'),
                  Text('Gagnant : ${battle.winnerId ?? 'égalité officielle'}'),
                  if (battle.isRevengeAvailable)
                    OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : () => _run(
                                () => ref.read(battleServiceProvider).requestRevenge(battle.id),
                                'Revanche demandée.',
                              ),
                      icon: const Icon(Icons.replay),
                      label: const Text('Demander une revanche'),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => ref.read(battleServiceProvider).shareBattle(battle),
          icon: const Icon(Icons.ios_share),
          label: const Text('Inviter à voter'),
        ),
      ],
    );
  }
}
