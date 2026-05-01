import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:take30/services/location_region_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('permission refusee retourne fallbackManualRequired', () async {
    final service = LocationRegionService(
      isLocationServiceEnabled: () async => true,
      checkPermission: () async => LocationPermission.denied,
      requestPermission: () async => LocationPermission.denied,
      localeReader: () => const ui.Locale.fromSubtags(
        languageCode: 'fr',
        countryCode: 'FR',
      ),
    );

    final resolved = await service.resolveLocationRegion();

    expect(resolved.source, LocationResolutionSource.fallbackManualRequired);
    expect(resolved.countryCode, isEmpty);
    expect(resolved.regionCode, isEmpty);
  });

  test('placemark Guadeloupe normalise vers France et guadeloupe', () async {
    final service = LocationRegionService(
      isLocationServiceEnabled: () async => true,
      checkPermission: () async => LocationPermission.whileInUse,
      requestPermission: () async => LocationPermission.whileInUse,
      getCurrentPosition: (_) async => _position(),
      placemarkFromCoordinates: (_, __) async => [
        const Placemark(
          isoCountryCode: 'GP',
          country: 'Guadeloupe',
          administrativeArea: 'Guadeloupe',
        ),
      ],
    );

    final resolved = await service.resolveLocationRegion();

    expect(resolved.source, LocationResolutionSource.deviceGps);
    expect(resolved.countryCode, 'FR');
    expect(resolved.countryName, 'France');
    expect(resolved.regionCode, 'guadeloupe');
    expect(resolved.regionName, 'Guadeloupe');
  });

  test('placemark Ile-de-France produit un regionCode stable', () async {
    final service = LocationRegionService(
      isLocationServiceEnabled: () async => true,
      checkPermission: () async => LocationPermission.whileInUse,
      requestPermission: () async => LocationPermission.whileInUse,
      getCurrentPosition: (_) async => _position(),
      placemarkFromCoordinates: (_, __) async => [
        const Placemark(
          isoCountryCode: 'FR',
          country: 'France',
          administrativeArea: 'Île-de-France',
        ),
      ],
    );

    final resolved = await service.resolveLocationRegion();

    expect(resolved.countryCode, 'FR');
    expect(resolved.regionCode, 'ile_de_france');
    expect(resolved.regionName, 'Île-de-France');
  });

  test('localisation manuelle sauvegardee court-circuite le GPS', () async {
    var permissionChecks = 0;
    final service = LocationRegionService(
      isLocationServiceEnabled: () async => true,
      checkPermission: () async {
        permissionChecks += 1;
        return LocationPermission.whileInUse;
      },
      requestPermission: () async => LocationPermission.whileInUse,
    );

    await service.saveManualLocation(
      countryCode: 'FR',
      countryName: 'France',
      regionCode: 'guadeloupe',
      regionName: 'Guadeloupe',
    );

    final resolved = await service.resolveLocationRegion();

    expect(resolved.source, LocationResolutionSource.savedManual);
    expect(resolved.regionCode, 'guadeloupe');
    expect(permissionChecks, 0);
  });

  test('forceRefresh ignore le manuel et relance le GPS', () async {
    var positionReads = 0;
    final service = LocationRegionService(
      isLocationServiceEnabled: () async => true,
      checkPermission: () async => LocationPermission.whileInUse,
      requestPermission: () async => LocationPermission.whileInUse,
      getCurrentPosition: (_) async {
        positionReads += 1;
        return _position();
      },
      placemarkFromCoordinates: (_, __) async => [
        const Placemark(
          isoCountryCode: 'FR',
          country: 'France',
          administrativeArea: 'Île-de-France',
        ),
      ],
    );

    await service.saveManualLocation(
      countryCode: 'FR',
      countryName: 'France',
      regionCode: 'guadeloupe',
      regionName: 'Guadeloupe',
    );

    final resolved = await service.resolveLocationRegion(forceRefresh: true);

    expect(positionReads, 1);
    expect(resolved.source, LocationResolutionSource.deviceGps);
    expect(resolved.regionCode, 'ile_de_france');
    expect(await service.getSavedManualLocation(), isNull);
  });

  test('reverse geocoding vide retombe sur la locale systeme', () async {
    final service = LocationRegionService(
      isLocationServiceEnabled: () async => true,
      checkPermission: () async => LocationPermission.whileInUse,
      requestPermission: () async => LocationPermission.whileInUse,
      getCurrentPosition: (_) async => _position(),
      placemarkFromCoordinates: (_, __) async => const [],
      localeReader: () => const ui.Locale.fromSubtags(
        languageCode: 'fr',
        countryCode: 'FR',
      ),
    );

    final resolved = await service.resolveLocationRegion();

    expect(resolved.source, LocationResolutionSource.systemLocale);
    expect(resolved.countryCode, 'FR');
  });
}

Position _position() {
  return Position(
    latitude: 16.2415,
    longitude: -61.534,
    timestamp: DateTime(2026, 4, 30),
    accuracy: 120,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}