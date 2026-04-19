import '../../models/models.dart';
import 'firestore_refs.dart';

class NotificationsRepo {
  NotificationsRepo(this._refs);

  final FirestoreRefs _refs;

  Stream<List<NotificationModel>> watchForUser(String uid, {int limit = 50}) {
    return _refs
        .userNotifications(uid)
        .orderBy('time', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<List<NotificationModel>> listForUser(String uid,
      {int limit = 50}) async {
    final q = await _refs
        .userNotifications(uid)
        .orderBy('time', descending: true)
        .limit(limit)
        .get();
    return q.docs.map((d) => d.data()).toList();
  }

  Future<void> markRead(String uid, String notifId) async {
    await _refs.userNotifications(uid).doc(notifId).update({'isRead': true});
  }

  Future<void> markAllRead(String uid) async {
    final q = await _refs.userNotifications(uid).where('isRead', isEqualTo: false).get();
    for (final doc in q.docs) {
      await doc.reference.update({'isRead': true});
    }
  }
}
