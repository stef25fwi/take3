import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Localisation utilisateur résolue (région + pays) pour l'Explorer.
@immutable
class UserLocation {
  const UserLocation({
    required this.countryCode,
    required this.countryName,
    this.regionCode,
    this.regionName,
    this.source = LocationSource.unknown,
  });

  final String countryCode;
  final String countryName;
  final String? regionCode;
  final String? regionName;
  final LocationSource source;

  bool get hasRegion =>
      (regionCode?.isNotEmpty ?? false) && (regionName?.isNotEmpty ?? false);

  UserLocation copyWith({
    String? countryCode,
    String? countryName,
    String? regionCode,
    String? regionName,
    LocationSource? source,
  }) {
    return UserLocation(
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      regionCode: regionCode ?? this.regionCode,
      regionName: regionName ?? this.regionName,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserLocation &&
      other.countryCode == countryCode &&
      other.regionCode == regionCode;

  @override
  int get hashCode => Object.hash(countryCode, regionCode);
}

enum LocationSource {
  /// Détectée automatiquement depuis la locale système.
  autoLocale,

  /// Choisie manuellement par l'utilisateur.
  manual,

  /// Valeur par défaut (aucune détection).
  unknown,
}

/// Service léger de détection / persistance de la région utilisateur.
///
/// Stratégie :
/// 1. Lire la sélection manuelle stockée (SharedPreferences).
/// 2. Sinon, dériver le pays depuis la locale système (sans plugin GPS).
/// 3. Sinon, retourner un fallback neutre (France métropolitaine).
class LocationRegionService {
  LocationRegionService();

  static const _kPrefCountryCode = 'explorer_loc_country_code';
  static const _kPrefCountryName = 'explorer_loc_country_name';
  static const _kPrefRegionCode = 'explorer_loc_region_code';
  static const _kPrefRegionName = 'explorer_loc_region_name';

  /// Pays supportés (UI sélecteur manuel + auto-détection).
  static const supportedCountries = <CountryOption>[
    CountryOption('FR', 'France'),
    CountryOption('BE', 'Belgique'),
    CountryOption('CH', 'Suisse'),
    CountryOption('CA', 'Canada'),
    CountryOption('LU', 'Luxembourg'),
    CountryOption('GP', 'Guadeloupe'),
    CountryOption('MQ', 'Martinique'),
    CountryOption('GF', 'Guyane'),
    CountryOption('RE', 'La Réunion'),
    CountryOption('YT', 'Mayotte'),
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

  /// Régions par pays (sous-sélection représentative).
  static const regionsByCountry = <String, List<RegionOption>>{
    'FR': [
      RegionOption('IDF', 'Île-de-France'),
      RegionOption('PACA', 'Provence-Alpes-Côte d’Azur'),
      RegionOption('AURA', 'Auvergne-Rhône-Alpes'),
      RegionOption('OCC', 'Occitanie'),
      RegionOption('NAQ', 'Nouvelle-Aquitaine'),
      RegionOption('HDF', 'Hauts-de-France'),
      RegionOption('GES', 'Grand Est'),
      RegionOption('BFC', 'Bourgogne-Franche-Comté'),
      RegionOption('BRE', 'Bretagne'),
      RegionOption('NOR', 'Normandie'),
      RegionOption('PDL', 'Pays de la Loire'),
      RegionOption('CVL', 'Centre-Val de Loire'),
      RegionOption('COR', 'Corse'),
    ],
    'BE': [
      RegionOption('BRU', 'Bruxelles'),
      RegionOption('WAL', 'Wallonie'),
      RegionOption('FLA', 'Flandre'),
    ],
    'CH': [
      RegionOption('GE', 'Genève'),
      RegionOption('VD', 'Vaud'),
      RegionOption('ZH', 'Zurich'),
    ],
    'CA': [
      RegionOption('QC', 'Québec'),
      RegionOption('ON', 'Ontario'),
      RegionOption('BC', 'Colombie-Britannique'),
    ],
    'LU': [RegionOption('LU', 'Luxembourg')],
    'GP': [RegionOption('GP', 'Guadeloupe')],
    'MQ': [RegionOption('MQ', 'Martinique')],
    'GF': [RegionOption('GF', 'Guyane')],
    'RE': [RegionOption('RE', 'La Réunion')],
    'YT': [RegionOption('YT', 'Mayotte')],
  };

  /// Charge la localisation persistée si elle existe.
  Future<UserLocation?> readSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final country = prefs.getString(_kPrefCountryCode);
      final countryName = prefs.getString(_kPrefCountryName);
      if (country == null || country.isEmpty || countryName == null) {
        return null;
      }
      return UserLocation(
        countryCode: country,
        countryName: countryName,
        regionCode: prefs.getString(_kPrefRegionCode),
        regionName: prefs.getString(_kPrefRegionName),
        source: LocationSource.manual,
      );
    } catch (_) {
      return null;
    }
  }

  /// Détecte la localisation à partir de la locale système.
  /// Sans plugin GPS — purement heuristique sur `countryCode` de la locale.
  UserLocation detectFromLocale() {
    try {
      final locale = ui.PlatformDispatcher.instance.locale;
      final code = (locale.countryCode ?? '').toUpperCase();
      if (code.isNotEmpty) {
        final country = supportedCountries.firstWhere(
          (c) => c.code == code,
          orElse: () => const CountryOption('FR', 'France'),
        );
        return UserLocation(
          countryCode: country.code,
          countryName: country.label,
          source: LocationSource.autoLocale,
        );
      }
    } catch (_) {
      // ignore
    }
    return const UserLocation(
      countryCode: 'FR',
      countryName: 'France',
      source: LocationSource.unknown,
    );
  }

  /// Persiste un choix utilisateur.
  Future<void> save(UserLocation location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefCountryCode, location.countryCode);
      await prefs.setString(_kPrefCountryName, location.countryName);
      if (location.regionCode != null) {
        await prefs.setString(_kPrefRegionCode, location.regionCode!);
      } else {
        await prefs.remove(_kPrefRegionCode);
      }
      if (location.regionName != null) {
        await prefs.setString(_kPrefRegionName, location.regionName!);
      } else {
        await prefs.remove(_kPrefRegionName);
      }
    } catch (_) {
      // ignore
    }
  }

  /// Workflow complet : saved > auto-locale > fallback.
  Future<UserLocation> resolve() async {
    final saved = await readSaved();
    if (saved != null) return saved;
    return detectFromLocale();
  }
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
