import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/explorer_filter.dart';
import '../models/ranking_entry.dart';
import '../services/location_region_service.dart';
import '../utils/assets.dart';

// ─── Service singletons ─────────────────────────────────────────────────────

final locationRegionServiceProvider = Provider<LocationRegionService>((ref) {
  return LocationRegionService();
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
  ExplorerLocationNotifier(this._service)
      : super(const ExplorerLocationState(location: null, isResolving: true)) {
    _bootstrap();
  }

  final LocationRegionService _service;

  Future<void> _bootstrap() async {
    final resolved = await _service.resolve();
    if (!mounted) return;
    state = ExplorerLocationState(location: resolved, isResolving: false);
  }

  Future<void> setManual({
    required CountryOption country,
    RegionOption? region,
  }) async {
    final next = UserLocation(
      countryCode: country.code,
      countryName: country.label,
      regionCode: region?.code,
      regionName: region?.label,
      source: LocationSource.manual,
    );
    state = ExplorerLocationState(location: next, isResolving: false);
    await _service.save(next);
  }

  Future<void> redetect() async {
    state = state.copyWith(isResolving: true);
    final auto = _service.detectFromLocale();
    state = ExplorerLocationState(location: auto, isResolving: false);
    await _service.save(auto);
  }
}

final explorerLocationProvider =
    StateNotifierProvider<ExplorerLocationNotifier, ExplorerLocationState>(
  (ref) => ExplorerLocationNotifier(ref.read(locationRegionServiceProvider)),
);

// ─── Filtre ──────────────────────────────────────────────────────────────────

class ExplorerFilterNotifier extends StateNotifier<ExplorerFilter> {
  ExplorerFilterNotifier() : super(const ExplorerFilter());

  void setCountry(String? code) => state = state.copyWith(countryCode: code);
  void setRegion(String? code) => state = state.copyWith(regionCode: code);
  void setCategory(String? value) => state = state.copyWith(category: value);
  void setSceneType(String? value) => state = state.copyWith(sceneType: value);
  void setDifficulty(String? value) => state = state.copyWith(difficulty: value);
  void setSortMode(ExplorerSortMode mode) =>
      state = state.copyWith(sortMode: mode);
  void toggleOnlyNew() =>
      state = state.copyWith(onlyNew: !state.onlyNew, onlyTrending: false);
  void toggleOnlyTrending() =>
      state = state.copyWith(onlyTrending: !state.onlyTrending, onlyNew: false);
  void replace(ExplorerFilter next) => state = next;
  void reset() => state = state.cleared();
}

final explorerFilterProvider =
    StateNotifierProvider<ExplorerFilterNotifier, ExplorerFilter>(
  (ref) => ExplorerFilterNotifier(),
);

// ─── Catalogue de scènes Explorer (démo) ────────────────────────────────────

@immutable
class ExplorerScene {
  const ExplorerScene({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
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

final explorerSceneCatalogProvider = Provider<List<ExplorerScene>>((ref) {
  return [
    ExplorerScene(
      id: 'scene_test_interrogatoire_police_001',
      title: 'La vérité fissure',
      subtitle: 'Salle d’interrogatoire',
      category: 'Policier',
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
      sceneType: 'Monologue',
      difficulty: 'Débutant',
      durationSeconds: 60,
      userPlanCount: 1,
      countryCode: 'GP',
      countryName: 'Guadeloupe',
      regionCode: 'GP',
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
});

// ─── Filtrage / tri ─────────────────────────────────────────────────────────

bool _matchesFilter(ExplorerScene scene, ExplorerFilter filter) {
  if (filter.countryCode != null && scene.countryCode != filter.countryCode) {
    return false;
  }
  if (filter.regionCode != null && scene.regionCode != filter.regionCode) {
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
      regionCode: 'GP',
      regionName: 'Guadeloupe',
      countryCode: 'GP',
      countryName: 'Guadeloupe',
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
        countryName: filtered[i].countryName,
        regionCode: filtered[i].regionCode,
        countryCode: filtered[i].countryCode,
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
        s.countryCode == scope.countryCode && s.regionCode == scope.regionCode,
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
    keep: (s) => s.countryCode == countryCode,
    sort: (a, b) {
      final byTotal = b.totalScore.compareTo(a.totalScore);
      if (byTotal != 0) return byTotal;
      final bySub = b.submissionCount.compareTo(a.submissionCount);
      if (bySub != 0) return bySub;
      return b.voteCount.compareTo(a.voteCount);
    },
  );
});
