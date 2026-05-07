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
              scenesValue: '12',
              likesValue: '340',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Deviens'), findsOneWidget);
    expect(find.text('Joue. Publie. Affronte. Deviens une légende.'), findsOneWidget);
    expect(find.text('Nouvelle vidéo'), findsOneWidget);
    expect(find.text('Voir le défi'), findsOneWidget);
    expect(find.text('Format'), findsOneWidget);
    expect(find.text('Scènes'), findsOneWidget);
    expect(find.text('Likes'), findsOneWidget);
    expect(find.text('60s'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('340'), findsOneWidget);
  });

  testWidgets('Take60CinematicHero relaye les actions des CTA', (
    WidgetTester tester,
  ) async {
    var newVideoTapped = 0;
    var challengeTapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 430,
            child: Take60CinematicHero(
              onNewVideoTap: () => newVideoTapped++,
              onChallengeTap: () => challengeTapped++,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Nouvelle vidéo'));
    await tester.pump();
    await tester.tap(find.text('Voir le défi'));
    await tester.pump();

    expect(newVideoTapped, 1);
    expect(challengeTapped, 1);
  });
}