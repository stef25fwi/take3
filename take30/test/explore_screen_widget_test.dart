import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:take30/providers/explorer_providers.dart';
import 'package:take30/screens/explore_screen.dart';
import 'package:take30/services/location_region_service.dart';

void main() {
  testWidgets('Explorer affiche un message explicite si la permission est refusee',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        locationRegionServiceProvider.overrideWithValue(
          _FakeLocationRegionService(
            initial: _fallback(permissionDenied: true),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: ExplorerLocationBanner(
              onChange: () {},
              onRedetect: () {},
              isDetecting: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Localisation refusée. Vous pouvez choisir votre région manuellement.'),
      findsOneWidget,
    );
    expect(find.text('Choisir ma région'), findsOneWidget);
  });

  testWidgets('Explorer permet de choisir une region manuellement',
      (tester) async {
    final service = _FakeLocationRegionService(initial: _fallback());
    final container = ProviderContainer(
      overrides: [
        locationRegionServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: ExplorerLocationPickerSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ma région'), findsWidgets);

    await tester.tap(find.byType(DropdownButtonFormField<CountryOption>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('France').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<RegionOption?>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guadeloupe').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final filter = container.read(explorerFilterProvider);
    expect(filter.countryCode, 'FR');
    expect(filter.regionCode, 'guadeloupe');
    expect(filter.hasUserModifiedLocationFilter, isTrue);
  });
}

class _FakeLocationRegionService extends LocationRegionService {
  _FakeLocationRegionService({required ResolvedLocationRegion initial})
      : _resolved = initial;

  ResolvedLocationRegion _resolved;
  ResolvedLocationRegion? _manual;

  @override
  Future<ResolvedLocationRegion> resolveLocationRegion({bool forceRefresh = false}) async {
    return _manual ?? _resolved;
  }

  @override
  Future<void> saveManualLocation({
    required String countryCode,
    required String countryName,
    required String regionCode,
    required String regionName,
  }) async {
    _manual = ResolvedLocationRegion(
      countryCode: countryCode,
      countryName: countryName,
      regionCode: regionCode,
      regionName: regionName,
      isAutoDetected: false,
      isApproximate: false,
      source: LocationResolutionSource.savedManual,
      resolvedAt: DateTime(2026, 4, 30),
    );
    _resolved = _manual!;
  }

  @override
  Future<ResolvedLocationRegion?> getSavedManualLocation() async => _manual;
}

ResolvedLocationRegion _fallback({bool permissionDenied = false}) {
  return ResolvedLocationRegion(
    countryCode: '',
    countryName: '',
    regionCode: '',
    regionName: '',
    isAutoDetected: false,
    isApproximate: true,
    source: LocationResolutionSource.fallbackManualRequired,
    resolvedAt: DateTime(2026, 4, 30),
    permissionDenied: permissionDenied,
  );
}