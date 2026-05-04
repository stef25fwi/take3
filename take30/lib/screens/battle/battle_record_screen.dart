import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../providers/battle_providers.dart';
import '../../providers/providers.dart';
import '../take60_guided_record_screen.dart';

class BattleRecordScreen extends ConsumerWidget {
  const BattleRecordScreen({super.key, required this.battleId, this.initialBattle});

  final String battleId;
  final BattleModel? initialBattle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final battleState = ref.watch(battleByIdProvider(battleId));
    final battle = battleState.valueOrNull ?? initialBattle;
    final sceneId = battle?.sceneId;

    if (battleState.isLoading && battle == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (battle == null || sceneId == null || sceneId.isEmpty) {
      return const Scaffold(body: Center(child: Text('La scène Battle n’a pas pu être attribuée.')));
    }

    final sceneState = ref.watch(sceneProvider(sceneId));
    return sceneState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('La scène Battle n’a pas pu être chargée.'))),
      data: (scene) {
        if (scene == null) {
          return const Scaffold(body: Center(child: Text('Scène introuvable.')));
        }
        return Take60GuidedRecordScreen(
          initialScene: scene,
          battleContext: Take60BattleRecordingContext.fromBattle(battle),
        );
      },
    );
  }
}
