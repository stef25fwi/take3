import 'package:cloud_firestore/cloud_firestore.dart';

class BattlePredictionModel {
  const BattlePredictionModel({
    required this.uid,
    required this.predictedWinnerId,
    required this.createdAt,
    this.wasCorrect,
  });

  final String uid;
  final String predictedWinnerId;
  final DateTime createdAt;
  final bool? wasCorrect;

  factory BattlePredictionModel.fromMap(Map<String, dynamic> data) {
    return BattlePredictionModel(
      uid: data['uid'] as String? ?? '',
      predictedWinnerId: data['predictedWinnerId'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
      wasCorrect: data['wasCorrect'] as bool?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'predictedWinnerId': predictedWinnerId,
      'createdAt': Timestamp.fromDate(createdAt),
      if (wasCorrect != null) 'wasCorrect': wasCorrect,
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