import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/models.dart';
import '../models/profile_activity_history.dart';

class ProfileActivityHistoryService {
  ProfileActivityHistoryService(this._prefs);

  static const _maxItems = 8;
  static const _viewedScenesKey = 'viewed_scenes';
  static const _votedDuelsKey = 'voted_duels';

  final SharedPreferences _prefs;

  Future<List<ProfileViewedSceneHistoryItem>> getViewedScenes(
    String userId,
  ) async {
    return _readViewedScenes(userId);
  }

  Future<List<ProfileDuelVoteHistoryItem>> getVotedDuels(String userId) async {
    return _readVotedDuels(userId);
  }

  Future<void> recordSceneViewed(String userId, SceneModel scene) async {
    if (userId.isEmpty || scene.id.isEmpty) {
      return;
    }

    final current = _readViewedScenes(userId);
    final next = [
      ProfileViewedSceneHistoryItem.fromScene(scene),
      for (final item in current)
        if (item.sceneId != scene.id) item,
    ].take(_maxItems).toList();
    await _prefs.setString(
      _prefKey(userId, _viewedScenesKey),
      jsonEncode([for (final item in next) item.toMap()]),
    );
  }

  Future<void> recordDuelVote(String userId, DuelModel duel, int choice) async {
    if (userId.isEmpty || duel.id.isEmpty) {
      return;
    }

    final current = _readVotedDuels(userId);
    final next = [
      ProfileDuelVoteHistoryItem.fromDuel(duel, choice),
      for (final item in current)
        if (item.duelId != duel.id) item,
    ].take(_maxItems).toList();
    await _prefs.setString(
      _prefKey(userId, _votedDuelsKey),
      jsonEncode([for (final item in next) item.toMap()]),
    );
  }

  List<ProfileViewedSceneHistoryItem> _readViewedScenes(String userId) {
    final raw = _prefs.getString(_prefKey(userId, _viewedScenesKey));
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in decoded)
        ProfileViewedSceneHistoryItem.fromMap(
          (item as Map).cast<String, dynamic>(),
        ),
    ];
  }

  List<ProfileDuelVoteHistoryItem> _readVotedDuels(String userId) {
    final raw = _prefs.getString(_prefKey(userId, _votedDuelsKey));
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in decoded)
        ProfileDuelVoteHistoryItem.fromMap(
          (item as Map).cast<String, dynamic>(),
        ),
    ];
  }

  String _prefKey(String userId, String suffix) {
    return 'take30.profile.$userId.$suffix';
  }
}