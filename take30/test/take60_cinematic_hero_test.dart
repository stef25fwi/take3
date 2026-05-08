import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:take30/widgets/take60_hero_section.dart';

void main() {
  testWidgets('Take60CinematicHero affiche le contenu attendu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 430,
            child: Take60CinematicHero(
              formatValue: '60s',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Prêt à tourner\nune performance ?'), findsOneWidget);
    expect(
      find.text('Joue. Publie. Affronte. Deviens une légende.'),
      findsOneWidget,
    );
    expect(find.text('Nouvelle vidéo'), findsOneWidget);
    expect(find.text('Format'), findsOneWidget);
    expect(find.text('60s'), findsOneWidget);

    // Le bouton « Voir le défi » et les cartes Scènes / Likes ont été retirés.
    expect(find.text('Voir le défi'), findsNothing);
    expect(find.text('Scènes'), findsNothing);
    expect(find.text('Likes'), findsNothing);
    expect(find.text('Deviens'), findsNothing);
    expect(
      find.text('l’acteur principal', findRichText: true),
      findsNothing,
    );
  });

  testWidgets("Take60CinematicHero relaye l'action Nouvelle vidéo", (
    WidgetTester tester,
  ) async {
    var newVideoTapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 430,
            child: Take60CinematicHero(
              onNewVideoTap: () => newVideoTapped++,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Nouvelle vidéo'));
    await tester.pump();

    expect(newVideoTapped, 1);
  });
}