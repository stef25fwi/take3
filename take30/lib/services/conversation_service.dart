import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantAvatars,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderId,
    required this.unreadCounts,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String> participantAvatars;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastSenderId;
  final Map<String, int> unreadCounts;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String peerIdFor(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => currentUserId,
    );
  }

  String peerName(String currentUserId) {
    final peerId = peerIdFor(currentUserId);
    final value = participantNames[peerId];
    if (value != null && value.trim().isNotEmpty) {
      return value;
    }
    return peerId;
  }

  String peerAvatar(String currentUserId) {
    final peerId = peerIdFor(currentUserId);
    return participantAvatars[peerId] ?? '';
  }

  int unreadFor(String currentUserId) {
    return unreadCounts[currentUserId] ?? 0;
  }

  factory ConversationModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? const <String, dynamic>{};
    return ConversationModel(
      id: snap.id,
      participantIds:
          (data['participantIds'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      participantNames: _stringMap(data['participantNames']),
      participantAvatars: _stringMap(data['participantAvatars']),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: _readTimestamp(data['lastMessageAt']),
      lastSenderId: data['lastSenderId'] as String? ?? '',
      unreadCounts: _intMap(data['unreadCounts']),
      createdAt: _readTimestamp(data['createdAt']),
      updatedAt: _readTimestamp(data['updatedAt']),
    );
  }
}

class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.type,
    required this.createdAt,
    required this.readAt,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String type;
  final DateTime? createdAt;
  final DateTime? readAt;

  factory ConversationMessage.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? const <String, dynamic>{};
    return ConversationMessage(
      id: snap.id,
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      type: data['type'] as String? ?? 'text',
      createdAt: _readTimestamp(data['createdAt']),
      readAt: _readTimestamp(data['readAt']),
    );
  }
}

class ConversationService {
  ConversationService({
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection('conversations');

  CollectionReference<Map<String, dynamic>> _messages(String conversationId) =>
      _conversations.doc(conversationId).collection('messages');

  String conversationIdFor(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return '${ids[0]}__${ids[1]}';
  }

  Stream<List<ConversationModel>> streamConversations(String uid) {
    return _conversations
        .where('participantIds', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(ConversationModel.fromSnapshot).toList(),
        );
  }

  Stream<List<ConversationMessage>> streamMessages(String conversationId) {
    return _messages(conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(ConversationMessage.fromSnapshot).toList(),
        );
  }

  Future<ConversationModel> getOrCreateConversation({
    required String currentUserId,
    required String peerId,
    UserModel? currentUser,
    UserModel? peerUser,
  }) async {
    final id = conversationIdFor(currentUserId, peerId);
    final ref = _conversations.doc(id);
    final snap = await ref.get();

    if (snap.exists) {
      return ConversationModel.fromSnapshot(snap);
    }

    final now = FieldValue.serverTimestamp();
    final names = <String, String>{};
    final avatars = <String, String>{};
    if (currentUser != null) {
      names[currentUserId] =
          currentUser.displayName.isNotEmpty
              ? currentUser.displayName
              : currentUser.username;
      avatars[currentUserId] = currentUser.avatarUrl;
    }
    if (peerUser != null) {
      names[peerId] = peerUser.displayName.isNotEmpty
          ? peerUser.displayName
          : peerUser.username;
      avatars[peerId] = peerUser.avatarUrl;
    }

    final payload = <String, dynamic>{
      'participantIds': [currentUserId, peerId],
      'participantNames': names,
      'participantAvatars': avatars,
      'lastMessage': '',
      'lastMessageAt': now,
      'lastSenderId': '',
      'unreadCounts': {currentUserId: 0, peerId: 0},
      'createdAt': now,
      'updatedAt': now,
    };

    await ref.set(payload);
    final created = await ref.get();
    return ConversationModel.fromSnapshot(created);
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final convoRef = _conversations.doc(conversationId);
    final messageRef = _messages(conversationId).doc();
    final now = FieldValue.serverTimestamp();

    final batch = _db.batch();
    batch.set(messageRef, {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': trimmed,
      'type': 'text',
      'createdAt': now,
      'readAt': null,
    });
    batch.set(
      convoRef,
      {
        'lastMessage': trimmed,
        'lastMessageAt': now,
        'lastSenderId': senderId,
        'updatedAt': now,
        'unreadCounts': {
          receiverId: FieldValue.increment(1),
          senderId: 0,
        },
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> markConversationRead({
    required String conversationId,
    required String uid,
  }) async {
    final convoRef = _conversations.doc(conversationId);
    await convoRef.set(
      {
        'unreadCounts': {uid: 0},
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final unreadMessages = await _messages(conversationId)
        .where('receiverId', isEqualTo: uid)
        .where('readAt', isNull: true)
        .get();

    if (unreadMessages.docs.isEmpty) {
      return;
    }

    final batch = _db.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}

Map<String, String> _stringMap(dynamic value) {
  if (value is Map) {
    return value.map(
      (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
    );
  }
  return const <String, String>{};
}

Map<String, int> _intMap(dynamic value) {
  if (value is Map) {
    return value.map(
      (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
    );
  }
  return const <String, int>{};
}

DateTime? _readTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}
