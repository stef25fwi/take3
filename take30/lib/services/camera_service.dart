import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

enum CameraState {
  uninitialized,
  initializing,
  ready,
  recording,
  paused,
  stopped,
  error,
}

class RecordingResult {
  const RecordingResult({
    required this.filePath,
    required this.durationSeconds,
    required this.fileSizeBytes,
  });

  final String filePath;
  final int durationSeconds;
  final int fileSizeBytes;
}

class CameraService extends ChangeNotifier {
  CameraService._();

  static final CameraService _instance = CameraService._();

  factory CameraService() => _instance;

  static const int maxRecordingSeconds = 60;

  CameraController? _controller;
  List<CameraDescription> _cameras = <CameraDescription>[];
  int _currentCameraIndex = 0;
  CameraState _state = CameraState.uninitialized;
  String? _errorMessage;
  int _elapsedSeconds = 0;
  int _recordingLimitSeconds = maxRecordingSeconds;
  Timer? _recordingTimer;
  RecordingResult? _lastRecordingResult;
  FlashMode _flashMode = FlashMode.off;

  CameraController? get controller => _controller;
  CameraState get state => _state;
  String? get errorMessage => _errorMessage;
  int get elapsedSeconds => _elapsedSeconds;
  int get recordingLimitSeconds => _recordingLimitSeconds;
  RecordingResult? get lastRecordingResult => _lastRecordingResult;
  FlashMode get flashMode => _flashMode;
  int get remainingSeconds => _recordingLimitSeconds - _elapsedSeconds;
  double get progress =>
      _recordingLimitSeconds == 0 ? 0 : _elapsedSeconds / _recordingLimitSeconds;
  bool get isRecording => _state == CameraState.recording;
  bool get isReady => _state == CameraState.ready;

  RecordingResult? consumeLastRecordingResult() {
    final result = _lastRecordingResult;
    _lastRecordingResult = null;
    return result;
  }

  Future<bool> initialize() async {
    _setState(CameraState.initializing);

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _setError('Aucune caméra disponible');
        return false;
      }

      _currentCameraIndex = _cameras.length > 1 ? 1 : 0;
      await _initController(_cameras[_currentCameraIndex]);
      return true;
    } on CameraException catch (error) {
      _setError('Erreur caméra: ${error.description}');
      return false;
    } catch (error) {
      _setError('Erreur inattendue: $error');
      return false;
    }
  }

  Future<void> _initController(CameraDescription camera) async {
    await _controller?.dispose();
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _controller!.initialize();
    await _controller!.setFlashMode(FlashMode.off);
    _flashMode = FlashMode.off;
    _setState(CameraState.ready);
  }

  Future<bool> startRecording({int? maxDurationSeconds}) async {
    if (_controller == null || !_controller!.value.isInitialized || _state != CameraState.ready) {
      _setError('Caméra non initialisée');
      return false;
    }

    try {
      _lastRecordingResult = null;
      _recordingLimitSeconds =
          (maxDurationSeconds == null || maxDurationSeconds <= 0)
              ? maxRecordingSeconds
              : maxDurationSeconds.clamp(1, maxRecordingSeconds);
      await _controller!.startVideoRecording();
      _elapsedSeconds = 0;
      _setState(CameraState.recording);

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedSeconds++;
        notifyListeners();
        if (_elapsedSeconds >= _recordingLimitSeconds) {
          stopRecording();
        }
      });
      return true;
    } on CameraException catch (error) {
      _setError('Erreur démarrage: ${error.description}');
      return false;
    }
  }

  Future<RecordingResult?> stopRecording() async {
    if (_state != CameraState.recording) {
      return null;
    }

    _recordingTimer?.cancel();
    _recordingTimer = null;

    try {
      final file = await _controller!.stopVideoRecording();
      _setState(CameraState.stopped);
      _recordingLimitSeconds = maxRecordingSeconds;
      final resultFile = File(file.path);
      final size = await resultFile.length();
      final result = RecordingResult(
        filePath: file.path,
        durationSeconds: _elapsedSeconds,
        fileSizeBytes: size,
      );
      _lastRecordingResult = result;
      notifyListeners();
      return result;
    } on CameraException catch (error) {
      _setError('Erreur arrêt: ${error.description}');
      return null;
    }
  }

  Future<void> flipCamera() async {
    if (_cameras.length < 2 || _state == CameraState.recording) {
      return;
    }

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _initController(_cameras[_currentCameraIndex]);
  }

  Future<void> toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    final nextMode = _flashMode == FlashMode.torch
        ? FlashMode.off
        : FlashMode.torch;
    try {
      await _controller!.setFlashMode(nextMode);
      _flashMode = nextMode;
      notifyListeners();
    } on CameraException catch (error) {
      _setError('Flash indisponible: ${error.description}');
    }
  }

  Future<void> resetForNewRecording() async {
    _elapsedSeconds = 0;
    _recordingLimitSeconds = maxRecordingSeconds;
    _lastRecordingResult = null;
    if (_controller != null && _controller!.value.isInitialized) {
      _setState(CameraState.ready);
    } else {
      await initialize();
    }
    notifyListeners();
  }

  Future<String> buildOutputPath() async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return path.join(directory.path, 'take30_$timestamp.mp4');
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  void _setState(CameraState value) {
    _state = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _state = CameraState.error;
    notifyListeners();
  }
}