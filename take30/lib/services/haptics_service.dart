import 'package:flutter/services.dart';

class HapticsService {
  HapticsService._();

  static final HapticsService _instance = HapticsService._();

  factory HapticsService() => _instance;

  Future<void> light() => HapticFeedback.lightImpact();

  Future<void> medium() => HapticFeedback.mediumImpact();

  Future<void> heavy() => HapticFeedback.heavyImpact();

  Future<void> selection() => HapticFeedback.selectionClick();

  Future<void> error() => HapticFeedback.vibrate();

  Future<void> like() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }

  Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  Future<void> recordStart() => HapticFeedback.heavyImpact();

  Future<void> recordStop() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.lightImpact();
  }
}