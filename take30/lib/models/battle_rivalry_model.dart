import 'package:cloud_firestore/cloud_firestore.dart';

class BattleRivalryModel {
  const BattleRivalryModel({
    required this.pairKey,
    required this.userAId,
    required this.userBId,
    this.userAWins = 0,
    this.userBWins = 0,
    this.totalBattles = 0,
    this.lastBattleId,
    this.lastBattleAt,
    this.closeBattlesCount = 0,
    this.updatedAt,
  });

  final String pairKey;
  final String userAId;
  final String userBId;
  final int userAWins;
  final int userBWins;
  final int totalBattles;
  final String? lastBattleId;
  final DateTime? lastBattleAt;
  final int closeBattlesCount;
  final DateTime? updatedAt;

  factory BattleRivalryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return BattleRivalryModel.fromMap(doc.data() ?? const <String, dynamic>{});
  }

  factory BattleRivalryModel.fromMap(Map<String, dynamic> data) {
    return BattleRivalryModel(
      pairKey: data['pairKey'] as String? ?? '',
      userAId: data['userAId'] as String? ?? '',
      userBId: data['userBId'] as String? ?? '',
      userAWins: _readInt(data['userAWins']),
      userBWins: _readInt(data['userBWins']),
      totalBattles: _readInt(data['totalBattles']),
      lastBattleId: _readNullableString(data['lastBattleId']),
      lastBattleAt: _readNullableDate(data['lastBattleAt']),
      closeBattlesCount: _readInt(data['closeBattlesCount']),
      updatedAt: _readNullableDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pairKey': pairKey,
      'userAId': userAId,
      'userBId': userBId,
      'userAWins': userAWins,
      'userBWins': userBWins,
      'totalBattles': totalBattles,
      if (_hasValue(lastBattleId)) 'lastBattleId': lastBattleId,
      if (lastBattleAt != null) 'lastBattleAt': Timestamp.fromDate(lastBattleAt!),
      'closeBattlesCount': closeBattlesCount,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  String summaryFor(String uid) {
    if (uid == userAId) {
      return '$userAWins-$userBWins';
    }
    if (uid == userBId) {
      return '$userBWins-$userAWins';
    }
    return '$userAWins-$userBWins';
  }
}

int _readInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

DateTime? _readNullableDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

String? _readNullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;