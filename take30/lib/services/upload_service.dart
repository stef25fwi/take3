import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'mock_data.dart';

enum UploadState {
  idle,
  compressing,
  uploading,
  processing,
  complete,
  error,
}

class UploadProgress {
  const UploadProgress({
    required this.state,
    this.progress = 0,
    this.message,
    this.result,
    this.error,
  });

  final UploadState state;
  final double progress;
  final String? message;
  final SceneModel? result;
  final String? error;
}

class VideoUploadService extends ChangeNotifier {
  VideoUploadService._();

  static final VideoUploadService _instance = VideoUploadService._();

  factory VideoUploadService() => _instance;

  UploadProgress _progress = const UploadProgress(state: UploadState.idle);

  UploadProgress get progress => _progress;

  bool get isUploading => _progress.state == UploadState.uploading ||
      _progress.state == UploadState.compressing ||
      _progress.state == UploadState.processing;

  Future<SceneModel?> uploadScene({
    required String videoPath,
    required String title,
    required String category,
    required String authorId,
    List<String> tags = const [],
  }) async {
    try {
      _setProgress(UploadState.compressing, 0.1, 'Compression...');
      await Future<void>.delayed(const Duration(milliseconds: 800));
      _setProgress(UploadState.uploading, 0.45, 'Upload...');

      for (double value = 0.45; value <= 0.85; value += 0.1) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        _setProgress(UploadState.uploading, value, 'Upload...');
      }

      _setProgress(UploadState.processing, 0.92, 'Traitement...');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final scene = SceneModel(
        id: 'sc_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        category: category,
        thumbnailUrl: 'https://images.unsplash.com/photo-1542513217-0b0eeea7f7bc?w=400',
        videoUrl: videoPath,
        durationSeconds: 28,
        author: MockData.users.firstWhere(
          (user) => user.id == authorId,
          orElse: () => MockData.users.first,
        ),
        createdAt: DateTime.now(),
        tags: tags,
      );

      _setProgress(UploadState.complete, 1.0, 'Publié !', result: scene);
      return scene;
    } catch (error) {
      _setProgress(UploadState.error, 0, null, error: 'Erreur upload: $error');
      return null;
    }
  }

  void reset() {
    _progress = const UploadProgress(state: UploadState.idle);
    notifyListeners();
  }

  void _setProgress(
    UploadState state,
    double progress,
    String? message, {
    SceneModel? result,
    String? error,
  }) {
    _progress = UploadProgress(
      state: state,
      progress: progress,
      message: message,
      result: result,
      error: error,
    );
    notifyListeners();
  }
}