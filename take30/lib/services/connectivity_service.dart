import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ConnectivityService extends ChangeNotifier with WidgetsBindingObserver {
  ConnectivityService._();

  static final ConnectivityService _instance = ConnectivityService._();

  factory ConnectivityService() => _instance;

  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  List<ConnectivityResult> _results = const [ConnectivityResult.none];
  bool _isOnline = true;
  bool _initialized = false;

  bool get isOnline => _isOnline;
  List<ConnectivityResult> get results => List.unmodifiable(_results);

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    await _refreshStatus();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  Future<void> refresh() => _refreshStatus();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshStatus());
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await _connectivity.checkConnectivity();
      _updateStatus(status);
    } catch (error, stackTrace) {
      debugPrint('Connectivity check failed: $error');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'connectivity_service',
          context: ErrorDescription('while checking connectivity state'),
        ),
      );
      _updateStatus(const [ConnectivityResult.none]);
    }
  }

  void _updateStatus(List<ConnectivityResult> status) {
    final normalized = _normalize(status);
    final online = normalized.any((result) => result != ConnectivityResult.none);

    if (listEquals(_results, normalized) && _isOnline == online) {
      return;
    }

    _results = normalized;
    _isOnline = online;
    notifyListeners();
  }

  List<ConnectivityResult> _normalize(List<ConnectivityResult> status) {
    if (status.isEmpty) {
      return const [ConnectivityResult.none];
    }

    final normalized = <ConnectivityResult>[];
    for (final result in status) {
      if (!normalized.contains(result)) {
        normalized.add(result);
      }
    }

    if (normalized.length > 1) {
      normalized.remove(ConnectivityResult.none);
    }

    return normalized.isEmpty ? const [ConnectivityResult.none] : normalized;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _subscription = null;
    _initialized = false;
    super.dispose();
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