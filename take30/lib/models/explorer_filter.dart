// Filtres de la page Explorer.
// Modèle immutable utilisé par explorerFilterProvider pour filtrer
// scènes et classements côté UI.

enum ExplorerSortMode {
  /// Plus récent en premier (publishedAt desc).
  newest,

  /// Tendances (playCount desc, voteCount desc, publishedAt desc).
  trending,

  /// Score moyen le plus élevé.
  topRated,
}

enum ExplorerLocationScope {
  global,
  country,
  region,
}

class ExplorerFilter {
  const ExplorerFilter({
    this.countryCode,
    this.countryName,
    this.regionCode,
    this.regionName,
    this.category,
    this.sceneType,
    this.difficulty,
    this.sortMode = ExplorerSortMode.newest,
    this.onlyNew = false,
    this.onlyTrending = false,
    this.locationScope = ExplorerLocationScope.global,
    this.hasUserModifiedLocationFilter = false,
    this.locationFilterAppliedAutomatically = false,
  });

  final String? countryCode;
  final String? countryName;
  final String? regionCode;
  final String? regionName;
  final String? category;
  final String? sceneType;
  final String? difficulty;
  final ExplorerSortMode sortMode;
  final bool onlyNew;
  final bool onlyTrending;
  final ExplorerLocationScope locationScope;
  final bool hasUserModifiedLocationFilter;
  final bool locationFilterAppliedAutomatically;

  bool get hasActiveFilter =>
      countryCode != null ||
      regionCode != null ||
      category != null ||
      sceneType != null ||
      difficulty != null ||
      onlyNew ||
      onlyTrending;

  ExplorerFilter copyWith({
    Object? countryCode = _sentinel,
    Object? countryName = _sentinel,
    Object? regionCode = _sentinel,
    Object? regionName = _sentinel,
    Object? category = _sentinel,
    Object? sceneType = _sentinel,
    Object? difficulty = _sentinel,
    ExplorerSortMode? sortMode,
    bool? onlyNew,
    bool? onlyTrending,
    ExplorerLocationScope? locationScope,
    bool? hasUserModifiedLocationFilter,
    bool? locationFilterAppliedAutomatically,
  }) {
    return ExplorerFilter(
      countryCode: identical(countryCode, _sentinel)
          ? this.countryCode
          : countryCode as String?,
      countryName: identical(countryName, _sentinel)
          ? this.countryName
          : countryName as String?,
      regionCode: identical(regionCode, _sentinel)
          ? this.regionCode
          : regionCode as String?,
      regionName: identical(regionName, _sentinel)
          ? this.regionName
          : regionName as String?,
      category: identical(category, _sentinel)
          ? this.category
          : category as String?,
      sceneType: identical(sceneType, _sentinel)
          ? this.sceneType
          : sceneType as String?,
      difficulty: identical(difficulty, _sentinel)
          ? this.difficulty
          : difficulty as String?,
      sortMode: sortMode ?? this.sortMode,
      onlyNew: onlyNew ?? this.onlyNew,
      onlyTrending: onlyTrending ?? this.onlyTrending,
      locationScope: locationScope ?? this.locationScope,
      hasUserModifiedLocationFilter: hasUserModifiedLocationFilter ??
          this.hasUserModifiedLocationFilter,
      locationFilterAppliedAutomatically:
          locationFilterAppliedAutomatically ??
              this.locationFilterAppliedAutomatically,
    );
  }

  ExplorerFilter cleared() => const ExplorerFilter();

  static const _sentinel = Object();
}
