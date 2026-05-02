import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/ranking_entry.dart';
import '../../../providers/explorer_providers.dart';
import '../../../providers/providers.dart';
import '../models/take60_profile_stats.dart';
import '../models/take60_user_profile.dart';
import '../services/take60_profile_service.dart';

final take60ProfileServiceProvider = Provider<Take60ProfileService>((ref) {
  return Take60ProfileService(
    ref.read(authServiceProvider),
    ref.read(apiServiceProvider),
    ref.read(sharedPreferencesProvider),
  );
});

final currentTake60UserProfileProvider = FutureProvider<Take60UserProfile?>(
  (ref) async {
    final authUser = ref.watch(authProvider.select((state) => state.user));
    if (authUser == null) {
      return null;
    }

    final liveUser = ref.watch(profileProvider(authUser.id)).user ?? authUser;
    final location = ref.watch(explorerLocationProvider).location;
    final themeMode = ref.watch(themeModeProvider);
    final storedProfile =
        await ref.read(take60ProfileServiceProvider).getCurrentUserProfile();

    final fallback = Take60UserProfile.fromUserModel(
      liveUser,
      regionName: location?.regionName,
      countryName: location?.countryName,
      darkModeEnabled: themeMode == ThemeMode.dark,
    );

    if (storedProfile == null) {
      return fallback;
    }

    return storedProfile.copyWith(
      username: liveUser.username,
      displayName: liveUser.displayName,
      avatarUrl: liveUser.avatarUrl,
      bio: liveUser.bio.trim().isEmpty ? storedProfile.bio : liveUser.bio,
      isVerified: liveUser.isVerified,
      isTalentValidated:
          liveUser.isVerified || liveUser.approvalRate >= 0.75,
      isTrending: storedProfile.isTrending ||
          liveUser.likesCount >= 1000 ||
          liveUser.followersCount >= 500 ||
          liveUser.totalViews >= 10000,
      isAdmin: liveUser.isAdmin,
      roleLabel: liveUser.isAdmin
          ? 'Admin Take60'
          : storedProfile.roleLabel,
        regionName: location?.regionName.isNotEmpty == true
          ? location!.regionName
          : storedProfile.regionName,
        countryName: location?.countryName.isNotEmpty == true
          ? location!.countryName
          : storedProfile.countryName,
      darkModeEnabled: themeMode == ThemeMode.dark,
    );
  },
);

final currentTake60ProfileStatsProvider = Provider<Take60ProfileStats?>((ref) {
  final authUser = ref.watch(authProvider.select((state) => state.user));
  if (authUser == null) {
    return null;
  }

  final profileState = ref.watch(profileProvider(authUser.id));
  final liveUser = profileState.user ?? authUser;
  final profile = ref.watch(currentTake60UserProfileProvider).valueOrNull;
  final location = ref.watch(explorerLocationProvider).location;
  final globalRanking = ref.watch(globalRankingProvider);

  final countryCode =
      location?.countryCode.isNotEmpty == true ? location!.countryCode : 'FR';
  final regionCode =
      location?.regionCode.isNotEmpty == true ? location!.regionCode : 'global';

  final nationalRanking = ref.watch(nationalRankingProvider(countryCode));
  final regionalRanking = ref.watch(
    regionalRankingProvider((countryCode: countryCode, regionCode: regionCode)),
  );

  int? findRank(List<RankingEntry> entries) {
    for (final entry in entries) {
      if (entry.userId == authUser.id) {
        return entry.rank;
      }
    }
    return null;
  }

  return Take60ProfileStats.fromUserModel(
    liveUser,
    scenesCount: profileState.scenes.isNotEmpty
        ? profileState.scenes.length
        : liveUser.scenesCount,
    regionalRank: profile?.regionName.isEmpty == false
        ? findRank(regionalRanking)
        : null,
    countryRank: profile?.countryName.isEmpty == false
        ? findRank(nationalRanking)
        : null,
    globalRank: findRank(globalRanking),
  );
});