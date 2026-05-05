import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/models.dart';

class AiFeedService {
  AiFeedService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Future<List<PersonalizedFeedItem>> getPersonalizedFeed({int limit = 24}) async {
    try {
      final callable = _functions.httpsCallable('getPersonalizedFeed');
      final response = await callable.call<Map<String, dynamic>>({'limit': limit});
      final rawItems = response.data['items'];
      if (rawItems is List && rawItems.isNotEmpty) {
        final ids = rawItems
            .whereType<Map>()
            .map((item) => item['postId']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        final scenes = await _loadScenesByIds(ids);
        return [
          for (final raw in rawItems.whereType<Map>())
            if (scenes[raw['postId']?.toString()] != null)
              PersonalizedFeedItem(
                scene: scenes[raw['postId']?.toString()]!,
                feedScore: _readDouble(raw['feedScore']),
                reason: raw['reason']?.toString() ?? 'personalized',
                isBattle: raw['isBattle'] == true,
                battleId: raw['battleId']?.toString(),
              ),
        ];
      }
    } catch (_) {
      // Fallback Firestore direct non bloquant pour garder le feed disponible.
    }
    return _fallbackRecentFeed(limit: limit);
  }

  Future<void> recordEvent({
    required String postId,
    required FeedEventType eventType,
    int watchTimeMs = 0,
  }) async {
    await _functions.httpsCallable('recordFeedEvent').call({
      'postId': postId,
      'eventType': eventType.storageValue,
      'watchTimeMs': watchTimeMs,
    });
  }

  Future<List<PersonalizedFeedItem>> _fallbackRecentFeed({required int limit}) async {
    final snap = await _firestore
        .collection('scenes')
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((doc) => PersonalizedFeedItem(scene: SceneModel.fromFirestore(doc)))
        .toList();
  }

  Future<Map<String, SceneModel>> _loadScenesByIds(List<String> ids) async {
    final result = <String, SceneModel>{};
    for (var index = 0; index < ids.length; index += 10) {
      final chunk = ids.skip(index).take(10).toList();
      if (chunk.isEmpty) continue;
      final snap = await _firestore
          .collection('scenes')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        result[doc.id] = SceneModel.fromFirestore(doc);
      }
    }
    return result;
  }
}

double _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
