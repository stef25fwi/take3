import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:take30/providers/explorer_providers.dart';

void main() {
  test('le classement regional garde uniquement la meme region', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final entries = container.read(
      regionalRankingProvider(
        (countryCode: 'FR', regionCode: 'ile_de_france'),
      ),
    );

    expect(entries, isNotEmpty);
    expect(
      entries.every(
        (entry) =>
            entry.countryCode == 'FR' && entry.regionCode == 'ile_de_france',
      ),
      isTrue,
    );
  });

  test('le classement national garde uniquement le meme pays', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final entries = container.read(nationalRankingProvider('FR'));

    expect(entries, isNotEmpty);
    expect(entries.every((entry) => entry.countryCode == 'FR'), isTrue);
    expect(entries.any((entry) => entry.regionCode == 'guadeloupe'), isTrue);
  });

  test('le classement global reste visible sans filtre geographique', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final entries = container.read(globalRankingProvider);

    expect(entries.length, greaterThan(3));
    expect(entries.first.rank, 1);
  });
}