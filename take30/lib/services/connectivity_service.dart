import 'package:flutter/material.dart';

class ConnectivityService extends ChangeNotifier {
  ConnectivityService._();

  static final ConnectivityService _instance = ConnectivityService._();

  factory ConnectivityService() => _instance;

  bool _isOnline = true;

  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    _isOnline = true;
  }

  void setOnline(bool value) {
    if (_isOnline == value) {
      return;
    }
    _isOnline = value;
    notifyListeners();
  }

  static Widget offlineBanner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        color: const Color(0xFFFF4757),
        child: const Text(
          '⚠️ Pas de connexion internet',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}