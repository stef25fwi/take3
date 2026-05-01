import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/take30_admin_scene_flow.dart'
  show SceneDraftRepository, SceneFormData, SceneStatus;
import '../models/explorer_filter.dart';
import '../models/ranking_entry.dart';
import '../services/location_region_service.dart';
import '../utils/assets.dart';

// ─── Service singletons ─────────────────────────────────────────────────────

final locationRegionServiceProvider = Provider<LocationRegionService>((ref) {
  return LocationRegionService();
});

final locationResolutionRefreshTokenProvider = StateProvider<int>((ref) => 0);

final resolvedLocationProvider = FutureProvider<ResolvedLocationRegion>((ref) async {
  ref.watch(locationResolutionRefreshTokenProvider);
  return ref.read(locationRegionServiceProvider).resolveLocationRegion();
});

// ─── Localisation utilisateur ────────────────────────────────────────────────

class ExplorerLocationState {
  const ExplorerLocationState({
    required this.location,
    this.isResolving = false,
  });

  final UserLocation? location;
  final bool isResolving;

  ExplorerLocationState copyWith({
    UserLocation? location,
    bool? isResolving,
  }) {
    return ExplorerLocationState(
      location: location ?? this.location,
      isResolving: isResolving ?? this.isResolving,
    );
  }
}

class ExplorerLocationNotifier extends StateNotifier<ExplorerLocationState> {
  ExplorerLocationNotifier(this._ref, this._service)
      : super(const ExplorerLocationState(location: null, isResolving: true));

  final Ref _ref;
  final LocationRegionService _service;

  void syncFromResolved(AsyncValue<ResolvedLocationRegion> next) {
    next.when(
      data: (resolved) {
        Future.microtask(() {
          if (!mounted) return;
          state = ExplorerLocationState(location: resolved, isResolving: false);
        });
      },
      loading: () {
        Future.microtask(() {
          if (!mounted) return;
          state = state.copyWith(isResolving: true);
        });
      },
      error: (_, __) {
        Future.microtask(() {
          if (!mounted) return;
          state = state.copyWith(isResolving: false);
        });
      },
    );
  }

  Future<ResolvedLocationRegion> setManual({
    required CountryOption country,
    RegionOption? region,
  }) async {
    await _service.saveManualLocation(
      countryCode: country.code,
      countryName: country.label,
      regionCode: region?.code ?? '',
      regionName: region?.label ?? '',
    );
    final next = await _service.getSavedManualLocation() ??
        ResolvedLocationRegion(
          countryCode: country.code,
          countryName: country.label,
          regionCode: region?.code ?? '',
          regionName: region?.label ?? '',
          isAutoDetected: false,
          isApproximate: false,
          source: LocationResolutionSource.savedManual,
          resolvedAt: DateTime.now(),
        );
    state = ExplorerLocationState(location: next, isResolving: false);
    _ref.read(locationResolutionRefreshTokenProvider.notifier).state++;
    return next;
  }

  Future<ResolvedLocationRegion> redetect() async {
    state = state.copyWith(isResolving: true);
    final auto = await _service.resolveLocationRegion(forceRefresh: true);
    state = ExplorerLocationState(location: auto, isResolving: false);
    _ref.read(locationResolutionRefreshTokenProvider.notifier).state++;
    return auto;
  }
}

final explorerLocationProvider =
    StateNotifierProvider<ExplorerLocationNotifier, ExplorerLocationState>(
  (ref) {
    final notifier = ExplorerLocationNotifier(
      ref,
      ref.read(locationRegionServiceProvider),
    );
    final initialResolved = ref.read(resolvedLocationProvider).valueOrNull;
    if (initialResolved != null) {
      notifier.syncFromResolved(AsyncData(initialResolved));
    }
    ref.listen<AsyncValue<ResolvedLocationRegion>>(
      resolvedLocationProvider,
      (_, next) => notifier.syncFromResolved(next),
      fireImmediately: true,
    );
    return notifier;
  },
);

// ─── Filtre ──────────────────────────────────────────────────────────────────

class ExplorerFilterNotifier extends StateNotifier<ExplorerFilter> {
  ExplorerFilterNotifier() : super(const ExplorerFilter());

  void setCountry(
    String? code, {
    String? name,
    bool userInitiated = true,
  }) {
    final normalizedCountry =
        (code == null || code.isEmpty) ? null : _canonicalCountryCode(code);
    final shouldClearRegion = normalizedCountry == null ||
        normalizedCountry != state.countryCode;
    state = state.copyWith(
      countryCode: normalizedCountry,
      countryName: normalizedCountry == null ? null : (name ?? state.countryName),
      regionCode: shouldClearRegion ? null : state.regionCode,
      regionName: shouldClearRegion ? null : state.regionName,
      locationScope: state.regionCode != null && !shouldClearRegion
          ? ExplorerLocationScope.region
          : normalizedCountry != null
              ? ExplorerLocationScope.country
              : ExplorerLocationScope.global,
      hasUserModifiedLocationFilter:
          userInitiated ? true : state.hasUserModifiedLocationFilter,
      locationFilterAppliedAutomatically:
          userInitiated ? false : state.locationFilterAppliedAutomatically,
    );
  }

  void setRegion(
    String? code, {
    String? name,
    bool userInitiated = true,
  }) {
    final normalizedRegion = (code == null || code.isEmpty)
        ? null
        : _canonicalRegionCode(code, regionName: name);
    state = state.copyWith(
      regionCode: normalizedRegion,
      regionName: normalizedRegion == null ? null : (name ?? state.regionName),
      locationScope: normalizedRegion != null
          ? ExplorerLocationScope.region
          : state.countryCode != null
              ? ExplorerLocationScope.country
              : ExplorerLocationScope.global,
      hasUserModifiedLocationFilter:
          userInitiated ? true : state.hasUserModifiedLocationFilter,
      locationFilterAppliedAutomatically:
          userInitiated ? false : state.locationFilterAppliedAutomatically,
    );
  }
  void setCategory(String? value) => state = state.copyWith(category: value);
  void setSceneType(String? value) => state = state.copyWith(sceneType: value);
  void setDifficulty(String? value) => state = state.copyWith(difficulty: value);
  void setSortMode(ExplorerSortMode mode) =>
      state = state.copyWith(sortMode: mode);
  void toggleOnlyNew() =>
      state = state.copyWith(onlyNew: !state.onlyNew, onlyTrending: false);
  void toggleOnlyTrending() =>
      state = state.copyWith(onlyTrending: !state.onlyTrending, onlyNew: false);
  void applyDetectedLocation({
    required String countryCode,
    required String countryName,
    required String regionCode,
    required String regionName,
    bool overrideUserSelection = false,
  }) {
    if (!overrideUserSelection && state.hasUserModifiedLocationFilter) {
      return;
    }
    if (countryCode.trim().isEmpty) {
      return;
    }

    final normalizedCountry = _canonicalCountryCode(countryCode);
    final normalizedRegion = regionCode.trim().isEmpty
        ? ''
        : _canonicalRegionCode(regionCode, regionName: regionName);

    state = state.copyWith(
      countryCode: normalizedCountry,
      countryName: countryName,
      regionCode: normalizedRegion.isEmpty ? null : normalizedRegion,
      regionName: regionName.trim().isEmpty ? null : regionName,
      locationScope: normalizedRegion.isNotEmpty
          ? ExplorerLocationScope.region
          : ExplorerLocationScope.country,
      hasUserModifiedLocationFilter:
          overrideUserSelection ? false : state.hasUserModifiedLocationFilter,
      locationFilterAppliedAutomatically: true,
    );
  }

  void applyManualLocation({
    required String countryCode,
    required String countryName,
    required String regionCode,
    required String regionName,
  }) {
    final normalizedCountry = _canonicalCountryCode(countryCode);
    final normalizedRegion = regionCode.trim().isEmpty
        ? ''
        : _canonicalRegionCode(regionCode, regionName: regionName);
    state = state.copyWith(
      countryCode: normalizedCountry,
      countryName: countryName,
      regionCode: normalizedRegion.isEmpty ? null : normalizedRegion,
      regionName: regionName.trim().isEmpty ? null : regionName,
      locationScope: normalizedRegion.isNotEmpty
          ? ExplorerLocationScope.region
          : ExplorerLocationScope.country,
      hasUserModifiedLocationFilter: true,
      locationFilterAppliedAutomatically: false,
    );
  }
  void replace(ExplorerFilter next) => state = next;
  void reset() => state = state.cleared();
}

final explorerFilterProvider =
    StateNotifierProvider<ExplorerFilterNotifier, ExplorerFilter>(
  (ref) {
    final notifier = ExplorerFilterNotifier();
    final initialResolved = ref.read(resolvedLocationProvider).valueOrNull;
    if (initialResolved != null &&
        initialResolved.source !=
            LocationResolutionSource.fallbackManualRequired) {
      notifier.applyDetectedLocation(
        countryCode: initialResolved.countryCode,
        countryName: initialResolved.countryName,
        regionCode: initialResolved.regionCode,
        regionName: initialResolved.regionName,
      );
    }
    ref.listen<AsyncValue<ResolvedLocationRegion>>(
      resolvedLocationProvider,
      (_, next) {
        next.whenData((location) {
          if (location.source != LocationResolutionSource.fallbackManualRequired) {
            Future.microtask(() {
              notifier.applyDetectedLocation(
                countryCode: location.countryCode,
                countryName: location.countryName,
                regionCode: location.regionCode,
                regionName: location.regionName,
              );
            });
          }
        });
      },
      fireImmediately: true,
    );
    return notifier;
  },
);

// ─── Catalogue de scènes Explorer (démo) ────────────────────────────────────

@immutable
class ExplorerScene {
  const ExplorerScene({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.genre,
    required this.sceneType,
    required this.difficulty,
    required this.durationSeconds,
    required this.userPlanCount,
    required this.countryCode,
    required this.countryName,
    required this.regionCode,
    required this.regionName,
    required this.thumbnailAsset,
    required this.publishedAt,
    required this.playCount,
    required this.voteCount,
    required this.averageScore,
    required this.isNew,
    required this.isTrending,
  });

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String genre;
  final String sceneType;
  final String difficulty;
  final int durationSeconds;
  final int userPlanCount;
  final String countryCode;
  final String countryName;
  final String regionCode;
  final String regionName;
  final String thumbnailAsset;
  final DateTime publishedAt;
  final int playCount;
  final int voteCount;
  final double averageScore;
  final bool isNew;
  final bool isTrending;
}

final _now = DateTime.now();

const _legacyRegionCodes = <String, String>{
  'IDF': 'ile_de_france',
  'PACA': 'provence_alpes_cote_dazur',
  'AURA': 'auvergne_rhone_alpes',
  'OCC': 'occitanie',
  'NAQ': 'nouvelle_aquitaine',
  'HDF': 'hauts_de_france',
  'GES': 'grand_est',
  'BFC': 'bourgogne_franche_comte',
  'BRE': 'bretagne',
  'NOR': 'normandie',
  'PDL': 'pays_de_la_loire',
  'CVL': 'centre_val_de_loire',
  'COR': 'corse',
  'BRU': 'bruxelles',
  'WAL': 'wallonie',
  'FLA': 'flandre',
  'GE': 'geneve',
  'VD': 'vaud',
  'ZH': 'zurich',
  'QC': 'quebec',
  'ON': 'ontario',
  'BC': 'colombie_britannique',
  'GP': 'guadeloupe',
  'MQ': 'martinique',
  'GF': 'guyane',
  'RE': 'la_reunion',
  'YT': 'mayotte',
};

String _canonicalCountryCode(String code) {
  final upper = code.trim().toUpperCase();
  switch (upper) {
    case 'GP':
    case 'MQ':
    case 'GF':
    case 'RE':
    case 'YT':
      return 'FR';
    case '':
      return 'GLOBAL';
    default:
      return upper;
  }
}

String _canonicalRegionCode(String code, {String? regionName}) {
  final trimmed = code.trim();
  if (trimmed.isEmpty) {
    return regionName == null || regionName.trim().isEmpty
        ? 'global'
        : normalizeRegionCode('FR', regionName);
  }

  final legacy = _legacyRegionCodes[trimmed.toUpperCase()];
  if (legacy != null) {
    return legacy;
  }

  if (trimmed.toLowerCase() == 'global') {
    return 'global';
  }

  return normalizeRegionCode(
    'FR',
    regionName?.isNotEmpty == true ? regionName! : trimmed,
  );
}

final publishedAdminScenesProvider = StreamProvider<List<SceneFormData>>((ref) {
  return SceneDraftRepository.watchAll().map(
    (items) => items
        .where((scene) => scene.status == SceneStatus.published)
        .toList(growable: false),
  );
});

ExplorerScene _mapAdminSceneToExplorer(SceneFormData scene) {
  final publishedAt = scene.publishedAt ?? scene.updatedAt;
  final markerDuration = computeTimelineDurationSeconds(scene.markersJson);
  final durationSeconds = markerDuration > 0 ? markerDuration : 60;
  final isNew = DateTime.now().difference(scene.createdAt).inDays <= 14;

  return ExplorerScene(
    id: scene.id,
    title: _titleForAdminScene(scene),
    subtitle: _subtitleForAdminScene(scene),
    category: scene.category.trim().isEmpty ? 'Scène' : scene.category.trim(),
    genre: scene.genre.trim().isEmpty ? 'Non renseigné' : scene.genre.trim(),
    sceneType: _inferSceneType(scene),
    difficulty: _difficultyForAdminScene(scene),
    durationSeconds: durationSeconds,
    userPlanCount: _countUserPlanMarkers(scene.markersJson),
    countryCode: _canonicalCountryCode(scene.countryCode),
    countryName: scene.countryName.trim().isEmpty ? 'Global' : scene.countryName.trim(),
    regionCode: _canonicalRegionCode(
      scene.regionCode,
      regionName: scene.regionName,
    ),
    regionName: scene.regionName.trim().isEmpty ? 'Global' : scene.regionName.trim(),
    thumbnailAsset: _thumbnailAssetForAdminScene(scene),
    publishedAt: publishedAt,
    playCount: 0,
    voteCount: 0,
    averageScore: 0,
    isNew: isNew,
    isTrending: false,
  );
}

String _titleForAdminScene(SceneFormData scene) {
  if (scene.id == 'scene_test_interrogatoire_police_001') {
    return 'Interrogatoire police';
  }
  if (scene.projectTitle.trim().isNotEmpty) {
    return scene.projectTitle.trim();
  }
  return scene.displayTitle.trim();
}

String _subtitleForAdminScene(SceneFormData scene) {
  if (scene.id == 'scene_test_interrogatoire_police_001') {
    return 'Interrogatoire police';
  }
  if (scene.sceneName.trim().isNotEmpty &&
      scene.sceneName.trim() != _titleForAdminScene(scene)) {
    return scene.sceneName.trim();
  }
  if (scene.contextSummary.trim().isNotEmpty) {
    return scene.contextSummary.trim();
  }
  return scene.category.trim().isEmpty ? 'Scène publiée' : scene.category.trim();
}

String _inferSceneType(SceneFormData scene) {
  final category = scene.category.toLowerCase();
  final textType = scene.textType.toLowerCase();
  if (category.contains('polic')) return 'Confrontation / Interrogatoire';
  if (textType.contains('dialogue')) return 'Dialogue';
  if (textType.contains('impro')) return 'Improvisation';
  return 'Monologue';
}

String _difficultyForAdminScene(SceneFormData scene) {
  if (scene.playStyles.any((style) => style.toLowerCase() == 'intense')) {
    return 'Intense';
  }
  return _humanizeValue(scene.recommendedLevel, fallback: 'Intermédiaire');
}

String _thumbnailAssetForAdminScene(SceneFormData scene) {
  final category = scene.category.toLowerCase();
  if (category.contains('polic') || category.contains('action')) {
    return 'assets/scenes/scene_interrogatoire.svg';
  }
  if (category.contains('romance')) {
    return 'assets/scenes/scene_declaration_amour.svg';
  }
  return 'assets/scenes/scene_rupture_telephone.svg';
}

String _humanizeValue(String raw, {required String fallback}) {
  final value = raw.trim();
  if (value.isEmpty) return fallback;
  return value[0].toUpperCase() + value.substring(1);
}

List<Map<String, dynamic>> _decodeMarkerList(String raw) {
  if (raw.trim().isEmpty) return const [];
  try {
    final decoded = json.decode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => item.map((k, v) => MapEntry('$k', v)))
          .toList(growable: false);
    }
  } catch (_) {
    return const [];
  }
  return const [];
}

int computeTimelineDurationSeconds(String raw) {
  return _decodeMarkerList(raw).fold<int>(
    0,
    (sum, marker) => sum + _readDurationSeconds(marker['durationSeconds']),
  );
}

int _readDurationSeconds(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

int _countUserPlanMarkers(String raw) {
  const userMarkerTypes = {
    'user_intro',
    'user_dialogue',
    'user_reply',
    'user_emotion',
    'user_silent_action',
    'close_up',
    'medium_shot',
    'over_shoulder',
  };
  final count = _decodeMarkerList(raw)
      .where((marker) => userMarkerTypes.contains(marker['type']))
      .length;
  return count == 0 ? 1 : count;
}

final explorerSceneCatalogProvider = Provider<List<ExplorerScene>>((ref) {
  final liveScenes = ref.watch(publishedAdminScenesProvider).maybeWhen(
        data: (items) => items.map(_mapAdminSceneToExplorer).toList(growable: false),
        orElse: () => const <ExplorerScene>[],
      );
  if (!kDebugMode) {
    return liveScenes;
  }
  final liveIds = liveScenes.map((scene) => scene.id).toSet();
  final demoScenes = [
    ExplorerScene(
      id: 'scene_test_interrogatoire_police_001',
      title: 'La vérité fissure',
      subtitle: 'Salle d’interrogatoire',
      category: 'Policier',
      genre: 'Drame / Thriller',
      sceneType: 'Interrogatoire',
      difficulty: 'Intermédiaire',
      durationSeconds: 60,
      userPlanCount: 3,
      countryCode: 'FR',
      countryName: 'France',
      regionCode: 'IDF',
      regionName: 'Île-de-France',
      thumbnailAsset: 'assets/scenes/scene_interrogatoire.svg',
      publishedAt: _now.subtract(const Duration(hours: 2)),
      playCount: 412,
      voteCount: 138,
      averageScore: 4.6,
      isNew: true,
      isTrending: true,
    ),
    ExplorerScene(
      id: 'scene_rupture_telephone',
      title: 'Rupture au téléphone',
      subtitle: 'Conversation à cœur ouvert',
      category: 'Drame',
      genre: 'Drame',
      sceneType: 'Dialogue',
      difficulty: 'Débutant',
      durationSeconds: 60,
      userPlanCount: 2,
      countryCode: 'FR',
      countryName: 'France',
      regionCode: 'PACA',
      regionName: 'Provence-Alpes-Côte d’Azur',
      thumbnailAsset: 'assets/scenes/scene_rupture_telephone.svg',
      publishedAt: _now.subtract(const Duration(days: 1)),
      playCount: 1820,
      voteCount: 612,
      averageScore: 4.4,
      isNew: true,
      isTrending: true,
    ),
    ExplorerScene(
      id: 'scene_declaration_amour',
      title: 'Déclaration d’amour',
      subtitle: 'Premier aveu',
      category: 'Romance',
      genre: 'Romance',
      sceneType: 'Monologue',
      difficulty: 'Intermédiaire',
      durationSeconds: 60,
      userPlanCount: 2,
      countryCode: 'FR',
      countryName: 'France',
      regionCode: 'BRE',
      regionName: 'Bretagne',
      thumbnailAsset: 'assets/scenes/scene_declaration_amour.svg',
      publishedAt: _now.subtract(const Duration(days: 3)),
      playCount: 2145,
      voteCount: 802,
      averageScore: 4.8,
      isNew: false,
      isTrending: true,
    ),
    ExplorerScene(
      id: 'scene_confrontation',
      title: 'Confrontation',
      subtitle: 'Face à face sous pression',
      category: 'Action',
      genre: 'Thriller',
      sceneType: 'Conflit',
      difficulty: 'Avancé',
      durationSeconds: 60,
      userPlanCount: 3,
      countryCode: 'BE',
      countryName: 'Belgique',
      regionCode: 'BRU',
      regionName: 'Bruxelles',
      thumbnailAsset: 'assets/scenes/scene_confrontation.svg',
      publishedAt: _now.subtract(const Duration(days: 4)),
      playCount: 1340,
      voteCount: 478,
      averageScore: 4.2,
      isNew: true,
      isTrending: false,
    ),
    ExplorerScene(
      id: 'scene_audition_libre',
      title: 'Audition libre',
      subtitle: 'Self-tape spontanée',
      category: 'Audition',
      genre: 'Casting',
      sceneType: 'Self-tape',
      difficulty: 'Débutant',
      durationSeconds: 60,
      userPlanCount: 1,
      countryCode: 'CA',
      countryName: 'Canada',
      regionCode: 'QC',
      regionName: 'Québec',
      thumbnailAsset: 'assets/scenes/scene_interrogatoire.svg',
      publishedAt: _now.subtract(const Duration(hours: 18)),
      playCount: 720,
      voteCount: 215,
      averageScore: 4.1,
      isNew: true,
      isTrending: false,
    ),
    ExplorerScene(
      id: 'scene_humour_cafe',
      title: 'Café noir, vie blanche',
      subtitle: 'Stand-up café',
      category: 'Comédie',
      genre: 'Comédie',
      sceneType: 'Stand-up',
      difficulty: 'Intermédiaire',
      durationSeconds: 60,
      userPlanCount: 2,
      countryCode: 'CH',
      countryName: 'Suisse',
      regionCode: 'GE',
      regionName: 'Genève',
      thumbnailAsset: 'assets/scenes/scene_declaration_amour.svg',
      publishedAt: _now.subtract(const Duration(days: 6)),
      playCount: 980,
      voteCount: 324,
      averageScore: 4.0,
      isNew: false,
      isTrending: true,
    ),
    ExplorerScene(
      id: 'scene_iles_sourire',
      title: 'Sourire des îles',
      subtitle: 'Souvenirs créoles',
      category: 'Drame',
      genre: 'Drame',
      sceneType: 'Monologue',
      difficulty: 'Débutant',
      durationSeconds: 60,
      userPlanCount: 1,
      countryCode: 'FR',
      countryName: 'France',
      regionCode: 'guadeloupe',
      regionName: 'Guadeloupe',
      thumbnailAsset: 'assets/scenes/scene_rupture_telephone.svg',
      publishedAt: _now.subtract(const Duration(hours: 9)),
      playCount: 285,
      voteCount: 92,
      averageScore: 4.5,
      isNew: true,
      isTrending: false,
    ),
  ];
  return [
    ...liveScenes,
    ...demoScenes.where((scene) => !liveIds.contains(scene.id)),
  ];
});

// ─── Filtrage / tri ─────────────────────────────────────────────────────────

bool _matchesFilter(ExplorerScene scene, ExplorerFilter filter) {
  final sceneIsGlobal = _canonicalCountryCode(scene.countryCode) == 'GLOBAL' ||
      _canonicalRegionCode(scene.regionCode, regionName: scene.regionName) ==
          'global';
  if (filter.countryCode != null &&
      !sceneIsGlobal &&
      _canonicalCountryCode(scene.countryCode) !=
          _canonicalCountryCode(filter.countryCode!)) {
    return false;
  }
  if (filter.regionCode != null &&
      !sceneIsGlobal &&
      _canonicalRegionCode(scene.regionCode, regionName: scene.regionName) !=
          _canonicalRegionCode(
            filter.regionCode!,
            regionName: filter.regionName,
          )) {
    return false;
  }
  if (filter.category != null &&
      scene.category.toLowerCase() != filter.category!.toLowerCase()) {
    return false;
  }
  if (filter.sceneType != null &&
      scene.sceneType.toLowerCase() != filter.sceneType!.toLowerCase()) {
    return false;
  }
  if (filter.difficulty != null &&
      scene.difficulty.toLowerCase() != filter.difficulty!.toLowerCase()) {
    return false;
  }
  if (filter.onlyNew && !scene.isNew) return false;
  if (filter.onlyTrending && !scene.isTrending) return false;
  return true;
}

List<ExplorerScene> _sortScenes(
    List<ExplorerScene> input, ExplorerSortMode mode) {
  final list = List<ExplorerScene>.from(input);
  switch (mode) {
    case ExplorerSortMode.newest:
      list.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      break;
    case ExplorerSortMode.trending:
      list.sort((a, b) {
        final play = b.playCount.compareTo(a.playCount);
        if (play != 0) return play;
        final vote = b.voteCount.compareTo(a.voteCount);
        if (vote != 0) return vote;
        return b.publishedAt.compareTo(a.publishedAt);
      });
      break;
    case ExplorerSortMode.topRated:
      list.sort((a, b) => b.averageScore.compareTo(a.averageScore));
      break;
  }
  return list;
}

// ─── Listes filtrées exposées à l'UI ────────────────────────────────────────

final explorerFilteredScenesProvider = Provider<List<ExplorerScene>>((ref) {
  final scenes = ref.watch(explorerSceneCatalogProvider);
  final filter = ref.watch(explorerFilterProvider);
  final filtered = scenes.where((s) => _matchesFilter(s, filter)).toList();
  return _sortScenes(filtered, filter.sortMode);
});

final explorerNewScenesProvider = Provider<List<ExplorerScene>>((ref) {
  final scenes = ref.watch(explorerSceneCatalogProvider);
  final filter = ref.watch(explorerFilterProvider);
  final filtered = scenes
      .where((s) => s.isNew && _matchesFilter(s, filter))
      .toList();
  return _sortScenes(filtered, ExplorerSortMode.newest);
});

final explorerTrendingScenesProvider = Provider<List<ExplorerScene>>((ref) {
  final scenes = ref.watch(explorerSceneCatalogProvider);
  final filter = ref.watch(explorerFilterProvider);
  final filtered = scenes
      .where((s) => s.isTrending && _matchesFilter(s, filter))
      .toList();
  return _sortScenes(filtered, ExplorerSortMode.trending);
});

// ─── Classements régional / national (démo) ─────────────────────────────────

@immutable
class _RankingSeed {
  const _RankingSeed({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.regionCode,
    required this.regionName,
    required this.countryCode,
    required this.countryName,
    required this.totalScore,
    required this.averageScore,
    required this.voteCount,
    required this.submissionCount,
    this.isVerified = false,
    this.isCurrentUser = false,
  });

  final String userId;
  final String displayName;
  final String avatarUrl;
  final String regionCode;
  final String regionName;
  final String countryCode;
  final String countryName;
  final double totalScore;
  final double averageScore;
  final int voteCount;
  final int submissionCount;
  final bool isVerified;
  final bool isCurrentUser;
}

final _rankingSeedsProvider = Provider<List<_RankingSeed>>((ref) {
  return const [
    _RankingSeed(
      userId: 'u_rank_global_1',
      displayName: 'Iris Prime',
      avatarUrl: Take30Assets.avatarIaFemaleLead,
      regionCode: 'IDF',
      regionName: 'Île-de-France',
      countryCode: 'FR',
      countryName: 'France',
      totalScore: 250000,
      averageScore: 4.9,
      voteCount: 9820,
      submissionCount: 18,
      isVerified: true,
    ),
    _RankingSeed(
      userId: 'u_rank_week_1',
      displayName: 'Nora Act',
      avatarUrl: Take30Assets.avatarIaFemaleLead,
      regionCode: 'PACA',
      regionName: 'Provence-Alpes-Côte d’Azur',
      countryCode: 'FR',
      countryName: 'France',
      totalScore: 184500,
      averageScore: 4.8,
      voteCount: 6420,
      submissionCount: 14,
      isVerified: true,
    ),
    _RankingSeed(
      userId: 'u_rank_month_1',
      displayName: 'Star Luna',
      avatarUrl: Take30Assets.avatarIaFemaleLead,
      regionCode: 'IDF',
      regionName: 'Île-de-France',
      countryCode: 'FR',
      countryName: 'France',
      totalScore: 178200,
      averageScore: 4.7,
      voteCount: 5980,
      submissionCount: 13,
      isVerified: true,
    ),
    _RankingSeed(
      userId: 'u_rank_day_1',
      displayName: 'Luna Scene',
      avatarUrl: Take30Assets.avatarIaFemaleLead,
      regionCode: 'AURA',
      regionName: 'Auvergne-Rhône-Alpes',
      countryCode: 'FR',
      countryName: 'France',
      totalScore: 152400,
      averageScore: 4.6,
      voteCount: 4810,
      submissionCount: 11,
    ),
    _RankingSeed(
      userId: 'u_rank_month_3',
      displayName: 'Kai Line',
      avatarUrl: Take30Assets.avatarIaMaleLead,
      regionCode: 'IDF',
      regionName: 'Île-de-France',
      countryCode: 'FR',
      countryName: 'France',
      totalScore: 134800,
      averageScore: 4.5,
      voteCount: 4120,
      submissionCount: 10,
    ),
    _RankingSeed(
      userId: 'u_rank_week_3',
      displayName: 'Leo Frame',
      avatarUrl: Take30Assets.avatarIaMaleLead,
      regionCode: 'OCC',
      regionName: 'Occitanie',
      countryCode: 'FR',
      countryName: 'France',
      totalScore: 121500,
      averageScore: 4.4,
      voteCount: 3520,
      submissionCount: 9,
    ),
    _RankingSeed(
      userId: 'u_demo_local',
      displayName: 'Mode Demo',
      avatarUrl: Take30Assets.avatarCurrentUser,
      regionCode: 'IDF',
      regionName: 'Île-de-France',
      countryCode: 'FR',
      countryName: 'France',
      totalScore: 98750,
      averageScore: 4.3,
      voteCount: 2850,
      submissionCount: 8,
      isCurrentUser: true,
    ),
    _RankingSeed(
      userId: 'u_be_1',
      displayName: 'Anna Rive',
      avatarUrl: Take30Assets.avatarIaFemaleLead,
      regionCode: 'BRU',
      regionName: 'Bruxelles',
      countryCode: 'BE',
      countryName: 'Belgique',
      totalScore: 142000,
      averageScore: 4.7,
      voteCount: 4280,
      submissionCount: 11,
      isVerified: true,
    ),
    _RankingSeed(
      userId: 'u_ca_1',
      displayName: 'Mathis Roy',
      avatarUrl: Take30Assets.avatarIaMaleLead,
      regionCode: 'QC',
      regionName: 'Québec',
      countryCode: 'CA',
      countryName: 'Canada',
      totalScore: 168400,
      averageScore: 4.8,
      voteCount: 5210,
      submissionCount: 12,
      isVerified: true,
    ),
    _RankingSeed(
      userId: 'u_gp_1',
      displayName: 'Naïa Léon',
      avatarUrl: Take30Assets.avatarIaFemaleLead,
      regionCode: 'guadeloupe',
      regionName: 'Guadeloupe',
      countryCode: 'FR',
      countryName: 'France',
      totalScore: 76200,
      averageScore: 4.6,
      voteCount: 1820,
      submissionCount: 7,
    ),
  ];
});

List<RankingEntry> _rankSeeds(
  List<_RankingSeed> seeds, {
  required bool Function(_RankingSeed s) keep,
  required Comparator<_RankingSeed> sort,
}) {
  final filtered = seeds.where(keep).toList()..sort(sort);
  return [
    for (var i = 0; i < filtered.length; i++)
      RankingEntry(
        rank: i + 1,
        userId: filtered[i].userId,
        displayName: filtered[i].displayName,
        avatarUrl: filtered[i].avatarUrl,
        regionName: filtered[i].regionName,
        countryName: _canonicalCountryCode(filtered[i].countryCode) == 'FR' &&
                filtered[i].regionName == 'Guadeloupe'
            ? 'France'
            : filtered[i].countryName,
        regionCode: _canonicalRegionCode(
          filtered[i].regionCode,
          regionName: filtered[i].regionName,
        ),
        countryCode: _canonicalCountryCode(filtered[i].countryCode),
        totalScore: filtered[i].totalScore,
        averageScore: filtered[i].averageScore,
        voteCount: filtered[i].voteCount,
        submissionCount: filtered[i].submissionCount,
        isVerified: filtered[i].isVerified,
        isCurrentUser: filtered[i].isCurrentUser,
      ),
  ];
}

/// Classement régional pour `(countryCode, regionCode)`.
final regionalRankingProvider =
    Provider.family<List<RankingEntry>, ({String countryCode, String regionCode})>(
        (ref, scope) {
  final seeds = ref.watch(_rankingSeedsProvider);
  return _rankSeeds(
    seeds,
  keep: (s) =>
    _canonicalCountryCode(s.countryCode) ==
      _canonicalCountryCode(scope.countryCode) &&
    _canonicalRegionCode(s.regionCode, regionName: s.regionName) ==
      _canonicalRegionCode(scope.regionCode),
    sort: (a, b) {
      final byTotal = b.totalScore.compareTo(a.totalScore);
      if (byTotal != 0) return byTotal;
      final byAvg = b.averageScore.compareTo(a.averageScore);
      if (byAvg != 0) return byAvg;
      return b.voteCount.compareTo(a.voteCount);
    },
  );
});

/// Classement national pour `countryCode`.
final nationalRankingProvider =
    Provider.family<List<RankingEntry>, String>((ref, countryCode) {
  final seeds = ref.watch(_rankingSeedsProvider);
  return _rankSeeds(
    seeds,
    keep: (s) =>
        _canonicalCountryCode(s.countryCode) == _canonicalCountryCode(countryCode),
    sort: (a, b) {
      final byTotal = b.totalScore.compareTo(a.totalScore);
      if (byTotal != 0) return byTotal;
      final bySub = b.submissionCount.compareTo(a.submissionCount);
      if (bySub != 0) return bySub;
      return b.voteCount.compareTo(a.voteCount);
    },
  );
});

final globalRankingProvider = Provider<List<RankingEntry>>((ref) {
  final seeds = ref.watch(_rankingSeedsProvider);
  return _rankSeeds(
    seeds,
    keep: (_) => true,
    sort: (a, b) {
      final byTotal = b.totalScore.compareTo(a.totalScore);
      if (byTotal != 0) return byTotal;
      final bySub = b.submissionCount.compareTo(a.submissionCount);
      if (bySub != 0) return bySub;
      return b.voteCount.compareTo(a.voteCount);
    },
  );
});
