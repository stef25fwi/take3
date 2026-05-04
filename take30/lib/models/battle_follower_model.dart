import 'package:cloud_firestore/cloud_firestore.dart';

class BattleFollowerModel {
  const BattleFollowerModel({
    required this.uid,
    required this.createdAt,
    this.notifyOnPublish = true,
    this.notifyOnResult = true,
  });

  final String uid;
  final DateTime createdAt;
  final bool notifyOnPublish;
  final bool notifyOnResult;

  factory BattleFollowerModel.fromMap(Map<String, dynamic> data) {
    return BattleFollowerModel(
      uid: data['uid'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
      notifyOnPublish: data['notifyOnPublish'] as bool? ?? true,
      notifyOnResult: data['notifyOnResult'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'createdAt': Timestamp.fromDate(createdAt),
      'notifyOnPublish': notifyOnPublish,
      'notifyOnResult': notifyOnResult,
    };
  }
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