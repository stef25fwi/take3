import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:take30/models/models.dart';
import 'package:take30/widgets/battle/battle_preparing_card.dart';

void main() {
  testWidgets('BattlePreparingCard affiche statut et compte à rebours', (tester) async {
    final battle = BattleModel.fromMap({
      'id': 'battle_test',
      'status': 'in_preparation',
      'challengerId': 'u1',
      'opponentId': 'u2',
      'challengerName': 'Alex',
      'opponentName': 'Clara',
      'sceneTitle': 'La vérité fissure',
      'createdAt': DateTime(2026, 5, 4),
      'submissionDeadline': DateTime.now().add(const Duration(hours: 4)),
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BattlePreparingCard(battle: battle),
          ),
        ),
      ),
    );

    expect(find.text('En préparation'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Clara'), findsOneWidget);
    expect(find.text('La vérité fissure'), findsOneWidget);
    expect(find.text('Suivre cette Battle'), findsOneWidget);
  });
}
