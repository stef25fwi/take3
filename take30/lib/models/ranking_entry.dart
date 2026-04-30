/// Entrée de classement Explorer (régional ou national).
///
/// Distinct de `LeaderboardEntry` car porte le contexte géographique
/// (région/pays) et des compteurs de soumissions/votes spécifiques aux
/// classements pré-calculés `rankings/regional/...` et `rankings/national/...`.
class RankingEntry {
  const RankingEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.regionName,
    required this.countryName,
    required this.totalScore,
    required this.averageScore,
    required this.voteCount,
    required this.submissionCount,
    this.regionCode,
    this.countryCode,
    this.isVerified = false,
    this.isCurrentUser = false,
  });

  final int rank;
  final String userId;
  final String displayName;
  final String avatarUrl;
  final String regionName;
  final String countryName;
  final String? regionCode;
  final String? countryCode;
  final double totalScore;
  final double averageScore;
  final int voteCount;
  final int submissionCount;
  final bool isVerified;
  final bool isCurrentUser;

  factory RankingEntry.fromMap(Map<String, dynamic> data) {
    return RankingEntry(
      rank: (data['rank'] as num?)?.toInt() ?? 0,
      userId: data['userId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      regionName: data['regionName'] as String? ?? '',
      countryName: data['countryName'] as String? ?? '',
      regionCode: data['regionCode'] as String?,
      countryCode: data['countryCode'] as String?,
      totalScore: (data['totalScore'] as num?)?.toDouble() ?? 0,
      averageScore: (data['averageScore'] as num?)?.toDouble() ?? 0,
      voteCount: (data['voteCount'] as num?)?.toInt() ?? 0,
      submissionCount: (data['submissionCount'] as num?)?.toInt() ?? 0,
      isVerified: data['isVerified'] as bool? ?? false,
    );
  }
}
