import 'package:cloud_firestore/cloud_firestore.dart';

class BattleVoteModel {
  const BattleVoteModel({
    required this.uid,
    required this.votedForUserId,
    required this.votedAgainstUserId,
    required this.createdAt,
    this.watchedChallenger = false,
    this.watchedOpponent = false,
    this.watchProgressChallenger = 0,
    this.watchProgressOpponent = 0,
    this.deviceHash,
    this.appVersion,
  });

  final String uid;
  final String votedForUserId;
  final String votedAgainstUserId;
  final DateTime createdAt;
  final bool watchedChallenger;
  final bool watchedOpponent;
  final double watchProgressChallenger;
  final double watchProgressOpponent;
  final String? deviceHash;
  final String? appVersion;

  factory BattleVoteModel.fromMap(Map<String, dynamic> data) {
    return BattleVoteModel(
      uid: data['uid'] as String? ?? '',
      votedForUserId: data['votedForUserId'] as String? ?? '',
      votedAgainstUserId: data['votedAgainstUserId'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
      watchedChallenger: data['watchedChallenger'] as bool? ?? false,
      watchedOpponent: data['watchedOpponent'] as bool? ?? false,
      watchProgressChallenger:
          _readDouble(data['watchProgressChallenger']),
      watchProgressOpponent: _readDouble(data['watchProgressOpponent']),
      deviceHash: _readNullableString(data['deviceHash']),
      appVersion: _readNullableString(data['appVersion']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'votedForUserId': votedForUserId,
      'votedAgainstUserId': votedAgainstUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'watchedChallenger': watchedChallenger,
      'watchedOpponent': watchedOpponent,
      'watchProgressChallenger': watchProgressChallenger,
      'watchProgressOpponent': watchProgressOpponent,
      if (_hasValue(deviceHash)) 'deviceHash': deviceHash,
      if (_hasValue(appVersion)) 'appVersion': appVersion,
    };
  }

  bool get watchedBoth => watchedChallenger && watchedOpponent;
}

DateTime _readDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

double _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

String? _readNullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;