import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:take30/models/explorer_filter.dart';
import 'package:take30/providers/explorer_providers.dart';
import 'package:take30/services/location_region_service.dart';

void main() {
  test('localisation detectee initialise automatiquement le filtre region',
      () async {
    final container = ProviderContainer(
      overrides: [
        locationRegionServiceProvider.overrideWithValue(
          _StubLocationRegionService([
            _location(
              countryCode: 'FR',
              countryName: 'France',
              regionCode: 'guadeloupe',
              regionName: 'Guadeloupe',
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(resolvedLocationProvider.future);
    await Future<void>.delayed(Duration.zero);

    final filter = container.read(explorerFilterProvider);
    expect(filter.countryCode, 'FR');
    expect(filter.regionCode, 'guadeloupe');
    expect(filter.locationScope, ExplorerLocationScope.region);
    expect(filter.locationFilterAppliedAutomatically, isTrue);
  });

  test('une modification utilisateur bloque le reappli automatique suivant',
      () async {
    final service = _StubLocationRegionService([
      _location(
        countryCode: 'FR',
        countryName: 'France',
        regionCode: 'ile_de_france',
        regionName: 'Île-de-France',
      ),
      _location(
        countryCode: 'FR',
        countryName: 'France',
        regionCode: 'guadeloupe',
        regionName: 'Guadeloupe',
      ),
    ]);
    final container = ProviderContainer(
      overrides: [locationRegionServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await container.read(resolvedLocationProvider.future);
    await Future<void>.delayed(Duration.zero);

    final notifier = container.read(explorerFilterProvider.notifier);
    notifier.setRegion(null, name: null);
    notifier.setCountry('CA', name: 'Canada');
    notifier.setRegion('quebec', name: 'Québec');

    container.read(locationResolutionRefreshTokenProvider.notifier).state++;
    await container.read(resolvedLocationProvider.future);
    await Future<void>.delayed(Duration.zero);

    final filter = container.read(explorerFilterProvider);
    expect(filter.countryCode, 'CA');
    expect(filter.regionCode, 'quebec');
    expect(filter.hasUserModifiedLocationFilter, isTrue);
  });

  test('logique du chip Ma region applique pays et region', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(explorerFilterProvider.notifier);
    notifier.setCountry('FR', name: 'France');
    notifier.setRegion('guadeloupe', name: 'Guadeloupe');

    final filter = container.read(explorerFilterProvider);
    expect(filter.countryCode, 'FR');
    expect(filter.regionCode, 'guadeloupe');
    expect(filter.locationScope, ExplorerLocationScope.region);
  });

  test('logique du chip Mon pays applique seulement le pays', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(explorerFilterProvider.notifier);
    notifier.setCountry('FR', name: 'France');
    notifier.setRegion('ile_de_france', name: 'Île-de-France');
    notifier.setRegion(null, name: null);
    notifier.setCountry('FR', name: 'France');

    final filter = container.read(explorerFilterProvider);
    expect(filter.countryCode, 'FR');
    expect(filter.regionCode, isNull);
    expect(filter.locationScope, ExplorerLocationScope.country);
  });
}

class _StubLocationRegionService extends LocationRegionService {
  _StubLocationRegionService(List<ResolvedLocationRegion> responses)
      : _responses = Queue.of(responses);

  final Queue<ResolvedLocationRegion> _responses;

  @override
  Future<ResolvedLocationRegion> resolveLocationRegion({
    bool forceRefresh = false,
  }) async {
    if (_responses.length > 1) {
      return _responses.removeFirst();
    }
    return _responses.first;
  }
}

ResolvedLocationRegion _location({
  required String countryCode,
  required String countryName,
  required String regionCode,
  required String regionName,
  LocationResolutionSource source = LocationResolutionSource.deviceGps,
}) {
  return ResolvedLocationRegion(
    countryCode: countryCode,
    countryName: countryName,
    regionCode: regionCode,
    regionName: regionName,
    isAutoDetected: true,
    isApproximate: true,
    source: source,
    resolvedAt: DateTime(2026, 4, 30),
  );
}