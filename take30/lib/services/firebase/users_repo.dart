import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../models/models.dart';
import 'firestore_refs.dart';

class UsersRepo {
  UsersRepo(this._refs, this._functions);

  final FirestoreRefs _refs;
  final FirebaseFunctions _functions;

  Future<UserModel?> getById(String uid) async {
    try {
      final snap = await _refs.userDoc(uid).get();
      return snap.exists ? snap.data() : null;
    } on FirebaseException catch (error) {
      if (!_isOfflineReadError(error)) {
        rethrow;
      }
      try {
        final cached = await _refs
            .userDoc(uid)
            .get(const GetOptions(source: Source.cache));
        return cached.exists ? cached.data() : null;
      } on FirebaseException {
        return null;
      }
    }
  }

  Stream<UserModel?> watch(String uid) =>
      _refs.userDoc(uid).snapshots().map((s) => s.exists ? s.data() : null);

  Future<UserModel?> getByUsername(String username) async {
    try {
      final q = await _refs.users
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return q.docs.isEmpty ? null : q.docs.first.data();
    } on FirebaseException catch (error) {
      if (_isOfflineReadError(error)) {
        return null;
      }
      rethrow;
    }
  }

  Future<UserModel?> getByEmail(String email) async {
    try {
      final q = await _refs.users
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      return q.docs.isEmpty ? null : q.docs.first.data();
    } on FirebaseException catch (error) {
      if (_isOfflineReadError(error)) {
        return null;
      }
      rethrow;
    }
  }

  /// Création initiale à la 1re connexion : écrit `users/{uid}` en vérifiant
  /// l'unicité du username en transaction.
  Future<void> createProfile(UserModel user) async {
    await _refs.userDoc(user.id).set(user);
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> patch) async {
    await _refs.userDoc(uid).update(patch);
  }

  Future<void> addFcmToken({required String uid, required String token}) async {
    await _refs.userDoc(uid).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFcmToken({required String uid, required String token}) async {
    await _refs.userDoc(uid).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }

  /// Toggle follow via Cloud Function : la Function fait la transaction
  /// et met à jour `followersCount` / `followingCount`.
  Future<bool> toggleFollow(String targetUid) async {
    final result = await _functions
        .httpsCallable('toggleFollow')
        .call({'targetUid': targetUid});
    final data = result.data;
    if (data is Map && data['following'] is bool) {
      return data['following'] as bool;
    }
    return true;
  }

  Stream<List<UserModel>> watchFollowing(String uid) async* {
    // Lecture paginée simple : on récupère les userIds puis on watch les docs.
    final edgesStream = _refs.userFollowing(uid).snapshots();
    await for (final snap in edgesStream) {
      final ids = snap.docs.map((d) => d.id).toList();
      if (ids.isEmpty) {
        yield <UserModel>[];
        continue;
      }
      // Firestore `whereIn` est limité à 30 ids : on chunk.
      final chunks = <List<String>>[];
      for (var i = 0; i < ids.length; i += 30) {
        chunks.add(ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30));
      }
      final results = <UserModel>[];
      for (final chunk in chunks) {
        final q =
            await _refs.users.where(FieldPath.documentId, whereIn: chunk).get();
        results.addAll(q.docs.map((d) => d.data()));
      }
      yield results;
    }
  }

  bool _isOfflineReadError(FirebaseException error) {
    return error.code == 'unavailable' ||
        error.code == 'failed-precondition' ||
        error.code == 'network-request-failed';
  }
}
