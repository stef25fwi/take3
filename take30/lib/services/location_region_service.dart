import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LocationResolutionSource {
  savedManual,
  deviceGps,
  systemLocale,
  fallbackManualRequired,
}

@immutable
class ResolvedLocationRegion {
  const ResolvedLocationRegion({
    required this.countryCode,
    required this.countryName,
    required this.regionCode,
    required this.regionName,
    required this.isAutoDetected,
    required this.isApproximate,
    required this.source,
    required this.resolvedAt,
    this.permissionDenied = false,
  });

  final String countryCode;
  final String countryName;
  final String regionCode;
  final String regionName;
  final bool isAutoDetected;
  final bool isApproximate;
  final LocationResolutionSource source;
  final DateTime resolvedAt;
  final bool permissionDenied;

  bool get hasRegion => regionCode.isNotEmpty && regionName.isNotEmpty;
  bool get requiresManualSelection =>
      source == LocationResolutionSource.fallbackManualRequired;

  ResolvedLocationRegion copyWith({
    String? countryCode,
    String? countryName,
    String? regionCode,
    String? regionName,
    bool? isAutoDetected,
    bool? isApproximate,
    LocationResolutionSource? source,
    DateTime? resolvedAt,
    bool? permissionDenied,
  }) {
    return ResolvedLocationRegion(
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      regionCode: regionCode ?? this.regionCode,
      regionName: regionName ?? this.regionName,
      isAutoDetected: isAutoDetected ?? this.isAutoDetected,
      isApproximate: isApproximate ?? this.isApproximate,
      source: source ?? this.source,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      permissionDenied: permissionDenied ?? this.permissionDenied,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ResolvedLocationRegion &&
        other.countryCode == countryCode &&
        other.regionCode == regionCode &&
        other.source == source;
  }

  @override
  int get hashCode => Object.hash(countryCode, regionCode, source);
}

String normalizeRegionCode(String countryCode, String regionName) {
  final folded = _foldDiacritics(regionName.trim().toLowerCase())
  .replaceAll(RegExp(r'[^a-z0-9\s_-]'), '')
      .replaceAll('-', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll(' ', '_');

  if (folded.isNotEmpty) {
    return folded;
  }

  return countryCode.trim().toLowerCase();
}

ResolvedLocationRegion normalizeFrenchOverseasLocation(
  ResolvedLocationRegion location,
) {
  const mappings = {
    'GP': 'Guadeloupe',
    'MQ': 'Martinique',
    'GF': 'Guyane',
    'RE': 'La Réunion',
    'YT': 'Mayotte',
  };

  final countryCode = location.countryCode.toUpperCase();
  final mappedRegion = mappings[countryCode];
  if (mappedRegion == null) {
    return location;
  }

  return location.copyWith(
    countryCode: 'FR',
    countryName: 'France',
    regionName: mappedRegion,
    regionCode: normalizeRegionCode('FR', mappedRegion),
  );
}

typedef SharedPreferencesFactory = Future<SharedPreferences> Function();
typedef LocationServiceEnabledReader = Future<bool> Function();
typedef LocationPermissionReader = Future<LocationPermission> Function();
typedef CurrentPositionReader = Future<Position> Function(LocationSettings);
typedef PlacemarkReader = Future<List<Placemark>> Function(double, double);
typedef LocaleReader = ui.Locale Function();
typedef Clock = DateTime Function();

class LocationRegionService {
  LocationRegionService({
    SharedPreferencesFactory? sharedPreferencesFactory,
    LocationServiceEnabledReader? isLocationServiceEnabled,
    LocationPermissionReader? checkPermission,
    LocationPermissionReader? requestPermission,
    CurrentPositionReader? getCurrentPosition,
    PlacemarkReader? placemarkFromCoordinates,
    LocaleReader? localeReader,
    Clock? now,
  })  : _sharedPreferencesFactory =
            sharedPreferencesFactory ?? SharedPreferences.getInstance,
        _isLocationServiceEnabled =
            isLocationServiceEnabled ?? Geolocator.isLocationServiceEnabled,
        _checkPermission = checkPermission ?? Geolocator.checkPermission,
        _requestPermission = requestPermission ?? Geolocator.requestPermission,
        _getCurrentPosition = getCurrentPosition ??
          ((settings) =>
            Geolocator.getCurrentPosition(locationSettings: settings)),
        _placemarkFromCoordinates =
          placemarkFromCoordinates ?? geo.placemarkFromCoordinates,
        _localeReader =
            localeReader ?? (() => ui.PlatformDispatcher.instance.locale),
        _now = now ?? DateTime.now;

  final SharedPreferencesFactory _sharedPreferencesFactory;
  final LocationServiceEnabledReader _isLocationServiceEnabled;
  final LocationPermissionReader _checkPermission;
  final LocationPermissionReader _requestPermission;
  final CurrentPositionReader _getCurrentPosition;
  final PlacemarkReader _placemarkFromCoordinates;
  final LocaleReader _localeReader;
  final Clock _now;

  static const _kPrefManualCountryCode = 'explorer_loc_manual_country_code';
  static const _kPrefManualCountryName = 'explorer_loc_manual_country_name';
  static const _kPrefManualRegionCode = 'explorer_loc_manual_region_code';
  static const _kPrefManualRegionName = 'explorer_loc_manual_region_name';
  static const _kPrefManualResolvedAt = 'explorer_loc_manual_resolved_at';

  static const _kPrefAutoCountryCode = 'explorer_loc_auto_country_code';
  static const _kPrefAutoCountryName = 'explorer_loc_auto_country_name';
  static const _kPrefAutoRegionCode = 'explorer_loc_auto_region_code';
  static const _kPrefAutoRegionName = 'explorer_loc_auto_region_name';
  static const _kPrefAutoResolvedAt = 'explorer_loc_auto_resolved_at';
  static const _kPrefAutoApproximate = 'explorer_loc_auto_is_approximate';

  static const supportedCountries = <CountryOption>[
    CountryOption('FR', 'France'),
    CountryOption('BE', 'Belgique'),
    CountryOption('CH', 'Suisse'),
    CountryOption('CA', 'Canada'),
    CountryOption('LU', 'Luxembourg'),
    CountryOption('US', 'États-Unis'),
    CountryOption('GB', 'Royaume-Uni'),
    CountryOption('DE', 'Allemagne'),
    CountryOption('ES', 'Espagne'),
    CountryOption('IT', 'Italie'),
    CountryOption('PT', 'Portugal'),
    CountryOption('MA', 'Maroc'),
    CountryOption('SN', 'Sénégal'),
    CountryOption('CI', 'Côte d’Ivoire'),
  ];

  static const regionsByCountry = <String, List<RegionOption>>{
    'FR': [
      RegionOption('guadeloupe', 'Guadeloupe'),
      RegionOption('martinique', 'Martinique'),
      RegionOption('guyane', 'Guyane'),
      RegionOption('la_reunion', 'La Réunion'),
      RegionOption('mayotte', 'Mayotte'),
      RegionOption('ile_de_france', 'Île-de-France'),
      RegionOption('nouvelle_aquitaine', 'Nouvelle-Aquitaine'),
      RegionOption('occitanie', 'Occitanie'),
      RegionOption('provence_alpes_cote_dazur', 'Provence-Alpes-Côte d’Azur'),
      RegionOption('auvergne_rhone_alpes', 'Auvergne-Rhône-Alpes'),
      RegionOption('bretagne', 'Bretagne'),
      RegionOption('normandie', 'Normandie'),
      RegionOption('hauts_de_france', 'Hauts-de-France'),
      RegionOption('grand_est', 'Grand Est'),
      RegionOption('pays_de_la_loire', 'Pays de la Loire'),
      RegionOption('centre_val_de_loire', 'Centre-Val de Loire'),
      RegionOption('bourgogne_franche_comte', 'Bourgogne-Franche-Comté'),
      RegionOption('corse', 'Corse'),
    ],
    'BE': [
      RegionOption('bruxelles', 'Bruxelles'),
      RegionOption('wallonie', 'Wallonie'),
      RegionOption('flandre', 'Flandre'),
    ],
    'CH': [
      RegionOption('geneve', 'Genève'),
      RegionOption('vaud', 'Vaud'),
      RegionOption('zurich', 'Zurich'),
    ],
    'CA': [
      RegionOption('quebec', 'Québec'),
      RegionOption('ontario', 'Ontario'),
      RegionOption('colombie_britannique', 'Colombie-Britannique'),
    ],
    'LU': [RegionOption('luxembourg', 'Luxembourg')],
  };

  Future<ResolvedLocationRegion?> getSavedLocation() async {
    final manual = await _readStoredLocation(isManual: true);
    if (manual != null) {
      return manual;
    }
    return _readStoredLocation(isManual: false);
  }

  Future<ResolvedLocationRegion?> getSavedManualLocation() async {
    return _readStoredLocation(isManual: true);
  }

  Future<void> saveManualLocation({
    required String countryCode,
    required String countryName,
    required String regionCode,
    required String regionName,
  }) async {
    final prefs = await _sharedPreferencesFactory();
    final resolved = ResolvedLocationRegion(
      countryCode: countryCode.trim().toUpperCase(),
      countryName: _normalizeCountryName(countryCode, countryName),
      regionCode: regionCode.trim(),
      regionName: regionName.trim(),
      isAutoDetected: false,
      isApproximate: false,
      source: LocationResolutionSource.savedManual,
      resolvedAt: _now(),
    );
    await _writeLocation(prefs, resolved, isManual: true);
  }

  Future<void> clearManualLocation() async {
    final prefs = await _sharedPreferencesFactory();
    await prefs.remove(_kPrefManualCountryCode);
    await prefs.remove(_kPrefManualCountryName);
    await prefs.remove(_kPrefManualRegionCode);
    await prefs.remove(_kPrefManualRegionName);
    await prefs.remove(_kPrefManualResolvedAt);
  }

  Future<ResolvedLocationRegion> resolveLocationRegion({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final manual = await getSavedManualLocation();
      if (manual != null) {
        return manual;
      }

      final cachedAuto = await _readStoredLocation(isManual: false);
      if (cachedAuto != null) {
        return cachedAuto;
      }
    }

    try {
      final isEnabled = await _isLocationServiceEnabled();
      if (!isEnabled) {
        return _localeOrFallback();
      }

      var permission = await _checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return _fallbackManualRequired(permissionDenied: true);
      }

      final position = await _getCurrentPosition(
        const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 8));

      final placemarks = await _placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 8));

      if (placemarks.isEmpty) {
        return _localeOrFallback(requireManualOnEmpty: true);
      }

      final resolved = _resolveFromPlacemark(
        placemarks.first,
        isApproximate: true,
      );

      final prefs = await _sharedPreferencesFactory();
      if (forceRefresh) {
        await clearManualLocation();
      }
      await _writeLocation(prefs, resolved, isManual: false);
      return resolved;
    } on TimeoutException {
      return _localeOrFallback();
    } on UnsupportedError {
      return _localeOrFallback();
    } catch (_) {
      return _localeOrFallback();
    }
  }

  ResolvedLocationRegion detectFromLocale() {
    try {
      final locale = _localeReader();
      final code = (locale.countryCode ?? '').trim().toUpperCase();
      if (code.isEmpty) {
        return _fallbackManualRequired();
      }

      final normalizedCountryCode = _normalizeCountryCode(code);
      return ResolvedLocationRegion(
        countryCode: normalizedCountryCode,
        countryName: _normalizeCountryName(normalizedCountryCode, ''),
        regionCode: '',
        regionName: '',
        isAutoDetected: true,
        isApproximate: true,
        source: LocationResolutionSource.systemLocale,
        resolvedAt: _now(),
      );
    } catch (_) {
      return _fallbackManualRequired();
    }
  }

  Future<ResolvedLocationRegion?> _readStoredLocation({
    required bool isManual,
  }) async {
    try {
      final prefs = await _sharedPreferencesFactory();
      final countryCode = prefs.getString(
        isManual ? _kPrefManualCountryCode : _kPrefAutoCountryCode,
      );
      final countryName = prefs.getString(
        isManual ? _kPrefManualCountryName : _kPrefAutoCountryName,
      );
      final regionCode = prefs.getString(
            isManual ? _kPrefManualRegionCode : _kPrefAutoRegionCode,
          ) ??
          '';
      final regionName = prefs.getString(
            isManual ? _kPrefManualRegionName : _kPrefAutoRegionName,
          ) ??
          '';
      if (countryCode == null || countryCode.isEmpty || countryName == null) {
        return null;
      }

      final millis = prefs.getInt(
        isManual ? _kPrefManualResolvedAt : _kPrefAutoResolvedAt,
      );
      return ResolvedLocationRegion(
        countryCode: countryCode,
        countryName: countryName,
        regionCode: regionCode,
        regionName: regionName,
        isAutoDetected: !isManual,
        isApproximate: isManual
            ? false
            : (prefs.getBool(_kPrefAutoApproximate) ?? true),
        source: isManual
            ? LocationResolutionSource.savedManual
            : LocationResolutionSource.deviceGps,
        resolvedAt: millis == null
            ? _now()
            : DateTime.fromMillisecondsSinceEpoch(millis),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeLocation(
    SharedPreferences prefs,
    ResolvedLocationRegion location, {
    required bool isManual,
  }) async {
    final countryCodeKey =
        isManual ? _kPrefManualCountryCode : _kPrefAutoCountryCode;
    final countryNameKey =
        isManual ? _kPrefManualCountryName : _kPrefAutoCountryName;
    final regionCodeKey =
        isManual ? _kPrefManualRegionCode : _kPrefAutoRegionCode;
    final regionNameKey =
        isManual ? _kPrefManualRegionName : _kPrefAutoRegionName;
    final resolvedAtKey =
        isManual ? _kPrefManualResolvedAt : _kPrefAutoResolvedAt;

    await prefs.setString(countryCodeKey, location.countryCode);
    await prefs.setString(countryNameKey, location.countryName);
    await prefs.setString(regionCodeKey, location.regionCode);
    await prefs.setString(regionNameKey, location.regionName);
    await prefs.setInt(resolvedAtKey, location.resolvedAt.millisecondsSinceEpoch);
    if (!isManual) {
      await prefs.setBool(_kPrefAutoApproximate, location.isApproximate);
    }
  }

  ResolvedLocationRegion _resolveFromPlacemark(
    Placemark placemark, {
    required bool isApproximate,
  }) {
    final sourceCountryCode = (placemark.isoCountryCode ?? '').trim().toUpperCase();
    final rawCountryCode =
        _normalizeCountryCode(sourceCountryCode);
    final rawCountryName = _normalizeCountryName(
      sourceCountryCode,
      placemark.country ?? '',
    );

    final rawRegionName = _pickRegionName(placemark, rawCountryCode);
    final normalizedRegionName = _normalizeRegionName(rawCountryCode, rawRegionName);
    final normalizedRegionCode = normalizedRegionName.isEmpty
        ? ''
        : normalizeRegionCode(rawCountryCode, normalizedRegionName);

    final resolved = ResolvedLocationRegion(
      countryCode: rawCountryCode,
      countryName: rawCountryName,
      regionCode: normalizedRegionCode,
      regionName: normalizedRegionName,
      isAutoDetected: true,
      isApproximate: isApproximate,
      source: LocationResolutionSource.deviceGps,
      resolvedAt: _now(),
    );

    return normalizeFrenchOverseasLocation(resolved);
  }

  ResolvedLocationRegion _localeOrFallback({
    bool requireManualOnEmpty = false,
  }) {
    final locale = detectFromLocale();
    if (locale.countryCode.isNotEmpty) {
      return locale;
    }
    return _fallbackManualRequired();
  }

  ResolvedLocationRegion _fallbackManualRequired({
    bool permissionDenied = false,
  }) {
    return ResolvedLocationRegion(
      countryCode: '',
      countryName: '',
      regionCode: '',
      regionName: '',
      isAutoDetected: false,
      isApproximate: true,
      source: LocationResolutionSource.fallbackManualRequired,
      resolvedAt: _now(),
      permissionDenied: permissionDenied,
    );
  }

  String _normalizeCountryCode(String code) {
    final upper = code.trim().toUpperCase();
    switch (upper) {
      case 'GP':
      case 'MQ':
      case 'GF':
      case 'RE':
      case 'YT':
        return 'FR';
      default:
        return upper;
    }
  }

  String _normalizeCountryName(String countryCode, String countryName) {
    final trimmed = countryName.trim();
    if (trimmed.isNotEmpty) {
      return _normalizeCountryCode(countryCode) == 'FR' &&
              const {'GP', 'MQ', 'GF', 'RE', 'YT'}.contains(countryCode)
          ? 'France'
          : trimmed;
    }

    final match = supportedCountries.where((item) => item.code == countryCode);
    if (match.isNotEmpty) {
      return match.first.label;
    }
    if (countryCode == 'FR') {
      return 'France';
    }
    return countryCode;
  }

  String _pickRegionName(Placemark placemark, String countryCode) {
    final candidates = <String?>[
      placemark.administrativeArea,
      placemark.subAdministrativeArea,
      placemark.locality,
      placemark.subLocality,
    ];

    for (final candidate in candidates) {
      final trimmed = candidate?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    switch ((placemark.isoCountryCode ?? '').toUpperCase()) {
      case 'GP':
        return 'Guadeloupe';
      case 'MQ':
        return 'Martinique';
      case 'GF':
        return 'Guyane';
      case 'RE':
        return 'La Réunion';
      case 'YT':
        return 'Mayotte';
      default:
        return countryCode == 'FR' ? '' : '';
    }
  }

  String _normalizeRegionName(String countryCode, String regionName) {
    final trimmed = regionName.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final supportedRegions = regionsByCountry[countryCode] ?? const [];
    for (final option in supportedRegions) {
      if (option.label.toLowerCase() == trimmed.toLowerCase() ||
          option.code == normalizeRegionCode(countryCode, trimmed)) {
        return option.label;
      }
    }
    return trimmed;
  }
}

String _foldDiacritics(String input) {
  const replacements = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'œ': 'oe',
    'æ': 'ae',
  };

  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(replacements[char] ?? char);
  }
  return buffer.toString();
}

@immutable
class CountryOption {
  const CountryOption(this.code, this.label);
  final String code;
  final String label;
}

@immutable
class RegionOption {
  const RegionOption(this.code, this.label);
  final String code;
  final String label;
}

// Alias de compatibilité pendant la transition des providers/UI Explorer.
typedef UserLocation = ResolvedLocationRegion;
