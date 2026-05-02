import '../../../models/models.dart';

class Take60ProfileStats {
  const Take60ProfileStats({
    required this.scenesCount,
    required this.followersCount,
    required this.likesCount,
    required this.totalViews,
    required this.sharesCount,
    required this.approvalRate,
    this.regionalRank,
    this.countryRank,
    this.globalRank,
  });

  final int scenesCount;
  final int followersCount;
  final int likesCount;
  final int totalViews;
  final int sharesCount;
  final double approvalRate;
  final int? regionalRank;
  final int? countryRank;
  final int? globalRank;

  String get approvalRateLabel => '${(approvalRate * 100).round()}%';

  Take60ProfileStats copyWith({
    int? scenesCount,
    int? followersCount,
    int? likesCount,
    int? totalViews,
    int? sharesCount,
    double? approvalRate,
    int? regionalRank,
    int? countryRank,
    int? globalRank,
  }) {
    return Take60ProfileStats(
      scenesCount: scenesCount ?? this.scenesCount,
      followersCount: followersCount ?? this.followersCount,
      likesCount: likesCount ?? this.likesCount,
      totalViews: totalViews ?? this.totalViews,
      sharesCount: sharesCount ?? this.sharesCount,
      approvalRate: approvalRate ?? this.approvalRate,
      regionalRank: regionalRank ?? this.regionalRank,
      countryRank: countryRank ?? this.countryRank,
      globalRank: globalRank ?? this.globalRank,
    );
  }

  factory Take60ProfileStats.fromUserModel(
    UserModel user, {
    int? scenesCount,
    int? regionalRank,
    int? countryRank,
    int? globalRank,
  }) {
    return Take60ProfileStats(
      scenesCount: scenesCount ?? user.scenesCount,
      followersCount: user.followersCount,
      likesCount: user.likesCount,
      totalViews: user.totalViews,
      sharesCount: user.sharesCount,
      approvalRate: user.approvalRate,
      regionalRank: regionalRank,
      countryRank: countryRank,
      globalRank: globalRank,
    );
  }
}