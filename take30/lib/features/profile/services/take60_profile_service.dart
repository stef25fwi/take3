import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/models.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../models/take60_user_profile.dart';

class Take60ProfileService {
  Take60ProfileService(this._auth, this._api, this._prefs);

  static const _castingModeKey = 'casting_mode';
  static const _accountVisibilityKey = 'account_visibility';
  static const _videoVisibilityKey = 'video_visibility';
  static const _autoAcceptInvitesKey = 'auto_accept_invites';
  static const _notificationsEnabledKey = 'notifications_enabled';

  final AuthServiceBase _auth;
  final ApiService _api;
  final SharedPreferences _prefs;

  Future<Take60UserProfile?> getCurrentUserProfile() async {
    final authUser = _auth.currentUser ?? _api.currentUser;
    if (authUser == null) {
      return null;
    }

    UserModel user = authUser;
    try {
      final remote = await _api.users.getById(authUser.id);
      if (remote != null) {
        user = remote;
      }
    } catch (_) {}

    final remoteOverrides = await _readRemoteOverrides(user.id);
    return Take60UserProfile.fromUserModel(
      user,
      castingModeEnabled: _readBool(user.id, _castingModeKey) ??
          remoteOverrides['castingModeEnabled'] as bool? ??
          user.isAdmin,
      autoAcceptInvites: _readBool(user.id, _autoAcceptInvitesKey) ??
          remoteOverrides['autoAcceptInvites'] as bool? ??
          false,
      notificationsEnabled: _readBool(user.id, _notificationsEnabledKey) ??
          remoteOverrides['notificationsEnabled'] as bool? ??
          true,
      accountVisibility: Take60AccountVisibilityX.fromStorage(
        _readString(user.id, _accountVisibilityKey) ??
            remoteOverrides['accountVisibility'] as String?,
      ),
      videoVisibility: Take60VideoVisibilityX.fromStorage(
        _readString(user.id, _videoVisibilityKey) ??
            remoteOverrides['videoVisibility'] as String?,
      ),
    );
  }

  Stream<Take60UserProfile?> watchCurrentUserProfile() async* {
    yield await getCurrentUserProfile();
  }

  Future<void> updateCastingMode(bool enabled) async {
    final uid = _requireUserId();
    await _prefs.setBool(_prefKey(uid, _castingModeKey), enabled);
    await _mergeRemote(uid, {'castingModeEnabled': enabled});
  }

  Future<void> updateAccountVisibility(
    Take60AccountVisibility visibility,
  ) async {
    final uid = _requireUserId();
    await _prefs.setString(
      _prefKey(uid, _accountVisibilityKey),
      visibility.storageValue,
    );
    await _mergeRemote(uid, {'accountVisibility': visibility.storageValue});
  }

  Future<void> updateVideoVisibility(
    Take60VideoVisibility visibility,
  ) async {
    final uid = _requireUserId();
    await _prefs.setString(
      _prefKey(uid, _videoVisibilityKey),
      visibility.storageValue,
    );
    await _mergeRemote(uid, {'videoVisibility': visibility.storageValue});
  }

  Future<void> updateAutoAcceptInvites(bool enabled) async {
    final uid = _requireUserId();
    await _prefs.setBool(_prefKey(uid, _autoAcceptInvitesKey), enabled);
    await _mergeRemote(uid, {'autoAcceptInvites': enabled});
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    final uid = _requireUserId();
    await _prefs.setBool(_prefKey(uid, _notificationsEnabledKey), enabled);
    await _mergeRemote(uid, {'notificationsEnabled': enabled});
  }

  Future<Map<String, dynamic>> _readRemoteOverrides(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return snapshot.data() ?? const <String, dynamic>{};
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  Future<void> _mergeRemote(String uid, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  String _requireUserId() {
    final uid = _auth.currentUser?.id ?? _api.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      throw StateError('Aucun utilisateur connecte pour mettre a jour le profil Take60.');
    }
    return uid;
  }

  String _prefKey(String uid, String suffix) => 'take60.profile.$uid.$suffix';

  bool? _readBool(String uid, String suffix) {
    final key = _prefKey(uid, suffix);
    if (!_prefs.containsKey(key)) {
      return null;
    }
    return _prefs.getBool(key);
  }

  String? _readString(String uid, String suffix) {
    final key = _prefKey(uid, suffix);
    if (!_prefs.containsKey(key)) {
      return null;
    }
    return _prefs.getString(key);
  }
}