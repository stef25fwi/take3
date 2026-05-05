import 'dart:async';
import 'dart:io' show File;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../models/models.dart';
import '../providers/battle_providers.dart';
import '../providers/providers.dart';
import '../router/router.dart';
import '../services/camera_service.dart';
import '../services/permission_service.dart';
import '../services/take60_guided_scene_service.dart';
import '../theme/app_theme.dart';
import '../utils/video_player_controller_factory.dart';

/// Take60 Guided Recording Flow — full state machine.
///
/// L'utilisateur:
///  1) choisit une scène guidée filtrable (catégorie / type / difficulté)
///  2) lit la fiche réalisateur
///  3) regarde le plan IA puis prépare sa caméra
///  4) joue son plan après un compte à rebours, l'enregistrement s'arrête seul
///  5) revoit / rejoue / valide chaque plan
///  6) déclenche le rendu final + publication / brouillon
class Take60GuidedRecordScreen extends ConsumerStatefulWidget {
  const Take60GuidedRecordScreen({
    super.key,
    this.initialScene,
    this.battleContext,
    this.onInitCameraOverride,
  });

  final SceneModel? initialScene;
  final Take60BattleRecordingContext? battleContext;
  @visibleForTesting
  final Future<CameraInitResult> Function(BuildContext context)?
      onInitCameraOverride;

  @override
  ConsumerState<Take60GuidedRecordScreen> createState() =>
      _Take60GuidedRecordScreenState();
}

enum _Stage {
  library,
  director,
  aiPlayback,
  prepCamera,
  countdown,
  recording,
  preview,
  rendering,
  finalScreen,
}

class _Take60GuidedRecordScreenState
    extends ConsumerState<Take60GuidedRecordScreen> {
  static const _accent = Color(0xFFFFB800);
  static const _accent2 = Color(0xFF00D4FF);
  static const _danger = Color(0xFFFF4757);

  final Take60GuidedSceneService _service = Take60GuidedSceneService.instance;

  _Stage _stage = _Stage.library;
  bool _loadingLibrary = true;
  List<SceneModel> _scenes = const [];
  String? _filterCategory;
  String? _filterType;
  String? _filterDifficulty;

  SceneModel? _scene;
  List<Take60SceneMarker> _timeline = const [];
  int _currentIndex = 0;
  final Map<String, Take60UserRecordingDraft> _recordings = {};

  VideoPlayerController? _aiController;
  Future<void>? _aiInit;
  bool _aiAutoFinished = false;
  bool _aiPlanCompleted = false;
  Timer? _aiFallbackTimer;

  Timer? _countdownTimer;
  int _countdownValue = 10;
  bool _cameraInitializing = false;
  bool _waitingForRecordingResult = false;

  Take60UserRecordingDraft? _previewRecording;
  VideoPlayerController? _previewController;
  Future<void>? _previewInit;

  Take60RenderResult? _renderResult;
  VideoPlayerController? _finalController;
  Future<void>? _finalInit;
  String _publicationStatus = '';
  String? _renderErrorMessage;
  String? _statusMessage;
  bool _finalVideoValidated = false;
  bool _showUserPlanList = false;
  bool _savingDraft = false;
  bool _publishing = false;
  CameraInitResult? _cameraInitResult;
  String? _cameraPermissionMessage;

  String? get _projectId {
    final scene = _scene;
    if (scene == null) {
      return null;
    }
    return _service.projectIdForScene(scene);
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialScene != null) {
      _scene = widget.initialScene;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialScene != null) {
        _enterDirectorSheet(widget.initialScene!);
      }
      _loadLibrary();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _aiFallbackTimer?.cancel();
    _disposeAiController();
    _disposePreviewController();
    _disposeFinalController();
    super.dispose();
  }

  // ── Library ─────────────────────────────────────────────────────────────
  Future<void> _loadLibrary() async {
    setState(() => _loadingLibrary = true);
    final user = ref.read(authProvider).user ??
        const UserModel(
          id: 'guest',
          username: 'guest',
          displayName: 'Invité',
          avatarUrl: '',
        );
    try {
      final scenes = await _service.loadGuidedScenes(fallbackAuthor: user);
      if (!mounted) return;
      setState(() {
        _scenes = scenes;
        _loadingLibrary = false;
        if (_scene != null && _stage == _Stage.library) {
          // Si l'écran est ouvert avec une scène pré-sélectionnée, on saute
          // directement à la fiche réalisateur.
          _enterDirectorSheet(_scene!);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _scenes = const [];
        _loadingLibrary = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de charger les scènes guidées pour le moment.'),
        ),
      );
    }
  }

  List<SceneModel> get _filteredScenes {
    return _scenes.where((scene) {
      if (_filterCategory != null && scene.category != _filterCategory) {
        return false;
      }
      if (_filterType != null && scene.sceneType != _filterType) return false;
      if (_filterDifficulty != null && scene.difficulty != _filterDifficulty) {
        return false;
      }
      return true;
    }).toList();
  }

  // ── Director sheet ──────────────────────────────────────────────────────
  void _enterDirectorSheet(SceneModel scene) {
    final timeline = _service.buildTimeline(scene);
    setState(() {
      _scene = scene;
      _timeline = timeline;
      _currentIndex = 0;
      _recordings.clear();
      _stage = _Stage.director;
    });
    _persistDraftWithStatus(SceneRecordingStatus.directorSheetViewed);
    // Propose la reprise du brouillon si l'utilisateur en a un en cours.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeOfferDraftResume(scene),
    );
  }

  Future<void> _maybeOfferDraftResume(SceneModel scene) async {
    final resumeState = await _service.loadResumeState(scene: scene);
    if (!mounted || resumeState == null) return;
    if (_scene?.id != scene.id) return;
    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface(dialogContext),
        title: Text(
          'Reprendre la scène en cours ?',
          style: GoogleFonts.dmSans(color: _primaryText(dialogContext)),
        ),
        content: Text(
          'Tu as ${resumeState.recordings.length} plan(s) déjà enregistrés pour « ${resumeState.sceneTitle} ». '
          'Veux-tu reprendre où tu t\'étais arrêté ?',
          style: GoogleFonts.dmSans(color: _secondaryText(dialogContext)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Recommencer',
              style: GoogleFonts.dmSans(color: _secondaryText(dialogContext)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reprendre'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (resume == true) {
      _recordings.clear();
      for (final rec in resumeState.recordings) {
        _recordings[rec.markerId] = rec;
      }
      final resumeTimeline = resumeState.markers.isEmpty
          ? _timeline
          : resumeState.markers;
      final resumeIndex = resumeState.currentMarkerIndex
          .clamp(0, resumeTimeline.isEmpty ? 0 : resumeTimeline.length - 1);
      setState(() {
        _timeline = resumeTimeline;
        _currentIndex = resumeIndex;
        _publicationStatus = 'Brouillon repris.';
      });
    } else {
      await _service.discardResumeState(scene: scene);
    }
  }

  void _backToLibrary() {
    _disposeAiController();
    _disposePreviewController();
    _disposeFinalController();
    _countdownTimer?.cancel();
    setState(() {
      _scene = null;
      _timeline = const [];
      _currentIndex = 0;
      _recordings.clear();
      _renderResult = null;
      _stage = _Stage.library;
    });
  }

  // ── Timeline driver ─────────────────────────────────────────────────────
  Take60SceneMarker? get _currentMarker =>
      (_currentIndex >= 0 && _currentIndex < _timeline.length)
          ? _timeline[_currentIndex]
          : null;

  void _startScene() {
    if (_timeline.isEmpty) return;
    final firstAiIndex = _timeline.indexWhere(
      (marker) => !marker.requiresUserRecording,
    );
    final startIndex = firstAiIndex >= 0 ? firstAiIndex : 0;
    setState(() => _currentIndex = startIndex);
    _enterMarker(_timeline[startIndex]);
  }

  void _enterMarker(Take60SceneMarker marker) {
    if (marker.requiresUserRecording) {
      _enterPrepCamera();
    } else {
      _enterAiPlayback(marker);
    }
  }

  // ── AI playback ─────────────────────────────────────────────────────────
  Future<void> _enterAiPlayback(Take60SceneMarker marker) async {
    _disposeAiController();
    _aiFallbackTimer?.cancel();
    final url = (marker.videoUrl?.isNotEmpty ?? false)
        ? marker.videoUrl!
        : (_scene?.videoUrl ?? '');
    setState(() {
      _stage = _Stage.aiPlayback;
      _aiAutoFinished = false;
      _aiPlanCompleted = false;
    });
    await _persistDraftWithStatus(SceneRecordingStatus.aiIntroPlaying);
    if (url.isEmpty) {
      setState(() {
        _stage = _Stage.director;
        _publicationStatus =
            'Vidéo IA indisponible pour ce plan. Vérifie que la scène publiée contient une URL vidéo VEO validée.';
      });
      return;
    }
    try {
      final controller = buildVideoPlayerController(url);
      _aiController = controller;
      _aiInit = controller.initialize().then((_) {
        if (!mounted) return;
        controller.addListener(_aiListener);
        controller.play();
        final playerDuration = controller.value.duration;
        final markerDuration = Duration(seconds: marker.durationSeconds);
        final fallbackDelay = playerDuration > Duration.zero
            ? playerDuration
            : markerDuration;
        if (fallbackDelay > Duration.zero) {
          _aiFallbackTimer?.cancel();
          _aiFallbackTimer = Timer(fallbackDelay, _markAiCompleted);
        }
        setState(() {});
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.director;
        _publicationStatus =
            'Impossible de charger la vidéo IA. Vérifie l’URL VEO ou régénère le plan IA.';
      });
    }
  }

  void _aiListener() {
    final controller = _aiController;
    if (controller == null || _aiAutoFinished) return;
    final value = controller.value;
    if (!value.isInitialized) return;
    final reachedEnd =
        value.position >= value.duration - const Duration(milliseconds: 250);
    if (reachedEnd && !value.isPlaying) {
      _aiAutoFinished = true;
      controller.removeListener(_aiListener);
      _markAiCompleted();
    }
  }

  void _markAiCompleted() {
    if (!mounted || _aiPlanCompleted) return;
    _aiFallbackTimer?.cancel();
    _aiFallbackTimer = null;
    setState(() => _aiPlanCompleted = true);
    _persistDraftWithStatus(SceneRecordingStatus.waitingCameraPreparation);
  }

  void _onAiFinished() {
    if (!_aiPlanCompleted) return;
    final next = _currentIndex + 1;
    if (next >= _timeline.length) {
      // Fin de scène — pas de plan utilisateur, on passe au rendu.
      _renderFinalVideo();
      return;
    }
    setState(() {
      _currentIndex = next;
    });
    final upcoming = _timeline[next];
    if (upcoming.requiresUserRecording) {
      _enterPrepCamera();
    } else {
      _enterAiPlayback(upcoming);
    }
  }

  // ── Camera prep + countdown + recording ─────────────────────────────────
  Future<void> _enterPrepCamera() async {
    _disposeAiController();
    _aiFallbackTimer?.cancel();
    setState(() {
      _stage = _Stage.prepCamera;
      _cameraInitializing = true;
      _cameraInitResult = null;
      _cameraPermissionMessage = null;
      _waitingForRecordingResult = false;
    });
    await _persistDraftWithStatus(SceneRecordingStatus.waitingCameraPreparation);
    if (!mounted) return;
    final result = await (widget.onInitCameraOverride?.call(context) ??
        ref.read(recordingProvider.notifier).initCamera(context));
    if (!mounted) return;
    final labels = result.missingPermissions
        .map(
          (permission) => switch (permission) {
            AppPermission.camera => 'caméra',
            AppPermission.microphone => 'microphone',
            _ => 'autorisation',
          },
        )
        .toList();
    final joined = labels.isEmpty ? 'caméra et micro' : labels.join(' et ');
    setState(() {
      _cameraInitializing = false;
      _cameraInitResult = result;
      if (!result.isReady) {
        _cameraPermissionMessage = result.needsSettings
            ? 'L’accès au $joined a été refusé de façon permanente. Ouvre les réglages puis réessaie.'
            : 'L’accès au $joined a été refusé. Autorise-le pour enregistrer ton Take60.';
      }
    });
  }

  void _openAiIntro() {
    final firstAiIndex = _timeline.indexWhere(
      (marker) => !marker.requiresUserRecording,
    );
    if (firstAiIndex < 0) {
      _startAtFirstUserMarker();
      return;
    }
    setState(() => _currentIndex = firstAiIndex);
    _enterAiPlayback(_timeline[firstAiIndex]);
  }

  void _startAtFirstUserMarker() {
    final firstUserIndex = _timeline.indexWhere(
      (marker) => marker.requiresUserRecording,
    );
    if (firstUserIndex < 0) {
      _startScene();
      return;
    }
    setState(() => _currentIndex = firstUserIndex);
    _enterPrepCamera();
  }

  void _startCountdown() {
    HapticFeedback.heavyImpact();
    setState(() {
      _stage = _Stage.countdown;
      _countdownValue = 10;
    });
    _persistDraftWithStatus(SceneRecordingStatus.countdown);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _countdownValue--);
      if (_countdownValue <= 0) {
        timer.cancel();
        _beginRecording();
      }
    });
  }

  Future<void> _beginRecording() async {
    final marker = _currentMarker;
    if (marker == null) return;
    final cameraService = ref.read(cameraServiceProvider);
    if (!cameraService.isReady) {
      setState(() {
        _stage = _Stage.prepCamera;
        _cameraPermissionMessage = cameraService.errorMessage ??
            'La caméra et le micro doivent être autorisés avant de lancer l’enregistrement.';
      });
      return;
    }
    setState(() {
      _stage = _Stage.recording;
      _waitingForRecordingResult = true;
    });
    await _persistDraftWithStatus(SceneRecordingStatus.recordingUserPlan);
    final started = await ref.read(recordingProvider.notifier).startRecording(
          maxDurationSeconds: marker.durationSeconds,
        );
    if (!started && mounted) {
      setState(() {
        _stage = _Stage.prepCamera;
        _waitingForRecordingResult = false;
        _cameraPermissionMessage = cameraService.errorMessage ??
            'Impossible de démarrer l’enregistrement. Vérifie l’accès caméra et micro puis réessaie.';
      });
    }
  }

  void _handleRecordingResult(RecordingResult result) {
    final marker = _currentMarker;
    final scene = _scene;
    final projectId = _projectId;
    if (marker == null || scene == null || projectId == null) return;
    _waitingForRecordingResult = false;
    _service
        .persistRecording(
      projectId: projectId,
      scene: scene,
      marker: marker,
      recordedFile: result.file,
      localTempPath: result.filePath,
      durationSeconds: result.durationSeconds,
      status: UserPlanStatus.recorded,
    )
        .then((draft) {
      if (!mounted) return;
      setState(() {
        _previewRecording = draft;
        _stage = _Stage.preview;
      });
      _initPreviewController(draft);
      _persistDraftWithStatus(SceneRecordingStatus.previewUserPlan);
    });
  }

  Future<void> _initPreviewController(Take60UserRecordingDraft draft) async {
    _disposePreviewController();
    final source = draft.uploadedVideoUrl?.isNotEmpty == true
        ? draft.uploadedVideoUrl!
        : draft.localTempPath;
    if (source.isEmpty) return;
    try {
      final controller = buildVideoPlayerController(source);
      _previewController = controller;
      _previewInit = controller.initialize().then((_) {
        if (!mounted) return;
        controller.setLooping(true);
        setState(() {});
      });
    } catch (_) {
      // Si la preview échoue on reste sur la fiche bouton.
    }
  }

  // ── Plan validation ─────────────────────────────────────────────────────
  void _retakeCurrentPlan() {
    final marker = _currentMarker;
    if (marker == null) return;
    final draft = _previewRecording?.copyWith(
      status: UserPlanStatus.retakeRequested,
      updatedAt: DateTime.now(),
    );
    if (draft != null) {
      _recordings.remove(marker.id);
    }
    _disposePreviewController();
    setState(() {
      _previewRecording = null;
    });
    _enterPrepCamera();
  }

  Future<void> _validateCurrentPlan({bool autoAdvance = true}) async {
    final marker = _currentMarker;
    final draft = _previewRecording;
    if (marker == null || draft == null) return;
    final validated = draft.copyWith(
      status: UserPlanStatus.validated,
      updatedAt: DateTime.now(),
    );
    _recordings[marker.id] = validated;
    setState(() {
      _previewRecording = validated;
      _publicationStatus = 'Prise validée.';
    });
    await _persistDraftWithStatus(SceneRecordingStatus.userPlanValidated);
    if (autoAdvance) {
      _returnToShootingPlan(
        message: 'Séquence validée. Tu peux continuer depuis le plan de tournage.',
      );
    }
  }

  void _returnToShootingPlan({String? message}) {
    _disposePreviewController();
    setState(() {
      _previewRecording = null;
      _stage = _Stage.director;
      if (message != null) {
        _publicationStatus = message;
      }
    });
  }

  bool get _allRequiredUserSegmentsUploaded {
    final requiredMarkers = _timeline.where((marker) => marker.requiresUserRecording);
    for (final marker in requiredMarkers) {
      final recording = _recordings[marker.id] ??
          (_previewRecording?.markerId == marker.id ? _previewRecording : null);
      if (recording == null || !recording.isUploaded) {
        return false;
      }
    }
    return requiredMarkers.isNotEmpty;
  }

  Take60UserRecordingDraft? _recordingForMarker(Take60SceneMarker marker) {
    return _recordings[marker.id] ??
        (_previewRecording?.markerId == marker.id ? _previewRecording : null);
  }

  int get _requiredUserSegmentCount {
    return _timeline.where((marker) => marker.requiresUserRecording).length;
  }

  int get _validatedUserSegmentCount {
    var count = 0;
    for (final marker in _timeline.where((m) => m.requiresUserRecording)) {
      final recording = _recordingForMarker(marker);
      if (recording?.status == UserPlanStatus.validated) {
        count += 1;
      }
    }
    return count;
  }

  int get _uploadedUserSegmentCount {
    var count = 0;
    for (final marker in _timeline.where((m) => m.requiresUserRecording)) {
      final recording = _recordingForMarker(marker);
      if (recording?.isUploaded == true) {
        count += 1;
      }
    }
    return count;
  }

  double get _userSegmentProgress {
    final requiredCount = _requiredUserSegmentCount;
    if (requiredCount == 0) {
      return 0;
    }
    return (_validatedUserSegmentCount / requiredCount).clamp(0, 1);
  }

  bool get _isPreviewValidated {
    return _previewRecording?.status == UserPlanStatus.validated;
  }

  bool get _isLastTimelineMarker {
    return _currentIndex + 1 >= _timeline.length;
  }

  Future<void> _goToNextSegment() async {
    if (!_isPreviewValidated) {
      await _validateCurrentPlan(autoAdvance: false);
    }
    if (_isLastTimelineMarker) {
      if (_allRequiredUserSegmentsUploaded) {
        _renderFinalVideo();
      }
      return;
    }
    final nextIndex = _currentIndex + 1;
    _disposePreviewController();
    setState(() {
      _previewRecording = null;
      _publicationStatus = '';
      _currentIndex = nextIndex;
    });
    _persistDraftWithStatus(SceneRecordingStatus.userPlanValidated);
    _enterMarker(_timeline[nextIndex]);
  }

  // ── Final render ────────────────────────────────────────────────────────
  Future<void> _renderFinalVideo() async {
    final scene = _scene;
    final projectId = _projectId;
    if (scene == null || projectId == null) return;
    setState(() {
      _stage = _Stage.rendering;
      _renderResult = null;
      _renderErrorMessage = null;
      _statusMessage = 'Montage final en cours…';
      _finalVideoValidated = false;
      _showUserPlanList = false;
    });
    await _persistDraftWithStatus(SceneRecordingStatus.renderingFinalVideo);
    debugPrint('[RECORD] render start');
    try {
      final result = await _service.renderTake60GuidedScene(
        projectId: projectId,
        scene: scene,
        recordings: _recordings.values.toList(),
      );
      if (!mounted) return;
      if (result.finalVideoUrl.isEmpty || result.renderStatus == 'failed') {
        throw const Take60GuidedSceneException(
          code: 'render-failed',
          message:
              'Le montage final n’a pas pu être généré. Réessaie ou rejoue certains plans.',
        );
      }
      setState(() {
        _renderResult = result;
        _stage = _Stage.finalScreen;
        _statusMessage = null;
      });
      await _persistDraftWithStatus(SceneRecordingStatus.finalPreviewReady);
      if (result.finalVideoUrl.isNotEmpty) {
        await _initFinalController(result.finalVideoUrl);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _renderErrorMessage =
            'Le montage final n’a pas pu être généré. Réessaie ou rejoue certains plans.';
        _statusMessage = null;
      });
    }
  }

  Future<void> _initFinalController(String url) async {
    _disposeFinalController();
    try {
      final controller = buildVideoPlayerController(url);
      _finalController = controller;
      _finalInit = controller.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _saveAsDraft() async {
    final scene = _scene;
    final renderResult = _renderResult;
    final projectId = _projectId;
    if (scene == null || projectId == null) return;
    setState(() {
      _savingDraft = true;
      _publicationStatus = 'Brouillon en cours d\'enregistrement…';
    });
    try {
      if (renderResult != null && renderResult.finalVideoUrl.isNotEmpty) {
        await _service.saveRenderedProject(
          projectId: projectId,
          scene: scene,
          recordings: _recordings.values.toList(),
          renderResult: renderResult,
          status: 'draft',
          currentMarkerIndex: _currentIndex,
          battleContext: widget.battleContext,
        );
      } else {
        await _service.saveGuidedProjectDraft(
          projectId: projectId,
          scene: scene,
          currentMarkerIndex: _currentIndex,
          markers: _timeline,
          recordings: _recordings.values.toList(),
          recordingStatus: SceneRecordingStatus.draftSaved,
        );
        await _persistDraftWithStatus(SceneRecordingStatus.draftSaved);
      }
      if (!mounted) return;
      setState(() => _publicationStatus = 'Brouillon enregistré.');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _publicationStatus =
            'Impossible d\'enregistrer le brouillon pour le moment.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _savingDraft = false;
        });
      }
    }
  }

  Future<void> _publish() async {
    final scene = _scene;
    final renderResult = _renderResult;
    final projectId = _projectId;
    if (scene == null || renderResult == null || projectId == null) return;
    if (renderResult.finalVideoUrl.isEmpty) {
      setState(() => _publicationStatus =
          'Le rendu final doit être disponible avant publication.');
      return;
    }
    setState(() {
      _publishing = true;
      _publicationStatus = 'Publication en cours…';
    });
    try {
      await _service.saveRenderedProject(
        projectId: projectId,
        scene: scene,
        recordings: _recordings.values.toList(),
        renderResult: renderResult,
        status: 'published',
        currentMarkerIndex: _currentIndex,
        battleContext: widget.battleContext,
      );
      final battleContext = widget.battleContext;
      if (battleContext != null && battleContext.battleId.isNotEmpty) {
        final mirroredBattleAsset = await _service.prepareBattleSubmissionAsset(
          projectId: projectId,
          finalVideoUrl: renderResult.finalVideoUrl,
          battleContext: battleContext,
        );
        await ref.read(battleServiceProvider).submitBattlePerformance(
              battleId: battleContext.battleId,
              recordingId: projectId,
              videoUrl:
                  mirroredBattleAsset?.downloadUrl ?? renderResult.finalVideoUrl,
              storagePath:
                  mirroredBattleAsset?.storagePath ?? renderResult.finalVideoUrl,
            );
      }
      if (!mounted) return;
      setState(
        () => _publicationStatus = widget.battleContext == null
            ? 'Vidéo publiée.'
            : 'Ta performance Battle est envoyée.',
      );
      await _persistDraftWithStatus(SceneRecordingStatus.published);
      await _service.clearDraft(scene.id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _publicationStatus = 'Publication impossible pour le moment.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _publishing = false;
        });
      }
    }
  }

  Future<void> _persistDraftWithStatus(SceneRecordingStatus status) async {
    if (_scene == null) return;
    await _service.saveDraft(
      scene: _scene!,
      currentMarkerIndex: _currentIndex,
      status: status,
      recordings: _recordings.values.toList(),
    );
    final projectId = _projectId;
    if (projectId != null) {
      await _service.saveGuidedProjectDraft(
        projectId: projectId,
        scene: _scene!,
        currentMarkerIndex: _currentIndex,
        markers: _timeline,
        recordings: _recordings.values.toList(),
        recordingStatus: status,
      ).catchError((_) {});
    }
  }

  void _replayPlan(Take60SceneMarker marker) {
    final index = _timeline.indexWhere((m) => m.id == marker.id);
    if (index < 0) return;
    _recordings.remove(marker.id);
    setState(() {
      _currentIndex = index;
    });
    _enterMarker(marker);
  }

  void _startMarkerFromPlan(Take60SceneMarker marker) {
    final index = _timeline.indexWhere((m) => m.id == marker.id);
    if (index < 0) return;
    if (!marker.requiresUserRecording && !_hasPlayableAiVideo(marker)) {
      setState(() {
        _publicationStatus =
            'Vidéo IA indisponible pour ce plan. Vérifie que la scène publiée contient une URL vidéo VEO validée.';
      });
      return;
    }
    setState(() {
      _currentIndex = index;
      _publicationStatus = '';
    });
    _enterMarker(marker);
  }

  bool _hasPlayableAiVideo(Take60SceneMarker marker) {
    if (marker.requiresUserRecording) return false;
    return (marker.videoUrl?.trim().isNotEmpty ?? false) ||
        (_scene?.videoUrl?.trim().isNotEmpty ?? false);
  }

  String _statusLabelForMarker(Take60SceneMarker marker) {
    if (!marker.requiresUserRecording) return 'Prête';
    final recording = _recordingForMarker(marker);
    if (recording == null) return 'À enregistrer';
    switch (recording.status) {
      case UserPlanStatus.pending:
        return 'À enregistrer';
      case UserPlanStatus.recording:
        return 'Enregistrée';
      case UserPlanStatus.previewed:
        return 'Enregistrée';
      case UserPlanStatus.validated:
        return 'Validée';
      case UserPlanStatus.retakeRequested:
        return 'À rejouer';
      case UserPlanStatus.recorded:
        return 'Enregistrée';
    }
  }

  Color _statusColorForMarker(Take60SceneMarker marker) {
    final status = _statusLabelForMarker(marker);
    if (status == 'Validée' || status == 'Prête') return Colors.green.shade600;
    if (status == 'À rejouer') return Colors.orange.shade700;
    return _accent;
  }

  // ── Reactions to camera state changes ───────────────────────────────────
  void _maybeHandleCameraResult(CameraService cameraService) {
    if (!_waitingForRecordingResult) return;
    if (cameraService.isRecording) return;
    final result = cameraService.consumeLastRecordingResult();
    if (result != null) {
      _handleRecordingResult(result);
    }
  }

  // ── Disposal helpers ────────────────────────────────────────────────────
  void _disposeAiController() {
    _aiController?.removeListener(_aiListener);
    _aiController?.dispose();
    _aiController = null;
    _aiInit = null;
  }

  void _disposePreviewController() {
    _previewController?.dispose();
    _previewController = null;
    _previewInit = null;
  }

  void _disposeFinalController() {
    _finalController?.dispose();
    _finalController = null;
    _finalInit = null;
  }

  Color _background(BuildContext context) => AppThemeTokens.pageBackground(context);
  Color _surface(BuildContext context) => AppThemeTokens.chromeSurface(context);
  Color _surfaceMuted(BuildContext context) => AppThemeTokens.surfaceMuted(context);
  Color _primaryText(BuildContext context) => AppThemeTokens.primaryText(context);
  Color _secondaryText(BuildContext context) => AppThemeTokens.secondaryText(context);
  Color _softBorder(BuildContext context) => AppThemeTokens.softBorder(context);

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cameraService = ref.watch(cameraServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeHandleCameraResult(cameraService),
    );
    return Scaffold(
      backgroundColor: _background(context),
      body: SafeArea(
        child: switch (_stage) {
          _Stage.library => _buildLibrary(),
          _Stage.director => _buildDirectorSheet(),
          _Stage.aiPlayback => _buildAiPlayback(),
          _Stage.prepCamera => _buildPrepCamera(cameraService),
          _Stage.countdown => _buildCountdown(),
          _Stage.recording => _buildRecording(cameraService),
          _Stage.preview => _buildPreview(),
          _Stage.rendering => _buildRendering(),
          _Stage.finalScreen => _buildFinalScreen(),
        },
      ),
    );
  }

  // ─── Stage: Library ──────────────────────────────────────────────────
  Widget _buildLibrary() {
    final categories = _scenes.map((s) => s.category).toSet().toList()..sort();
    final types = _scenes
        .map((s) => s.sceneType)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final difficulties = _scenes
        .map((s) => s.difficulty)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go(AppRouter.home),
                      icon: Icon(Icons.arrow_back, color: _primaryText(context)),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Créer ma scène Take60',
                        style: GoogleFonts.dmSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _primaryText(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Choisis une scène, regarde les plans IA, puis joue tes séquences.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: _secondaryText(context),
                  ),
                ),
                const SizedBox(height: 16),
                _filtersRow(categories, types, difficulties),
              ],
            ),
          ),
        ),
        if (_loadingLibrary)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: _accent),
            ),
          )
        else if (_filteredScenes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Aucune scène guidée ne correspond à ces filtres pour le moment.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: _secondaryText(context),
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList.builder(
              itemCount: _filteredScenes.length,
              itemBuilder: (context, index) {
                final scene = _filteredScenes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _SceneCard(
                    scene: scene,
                    onPlay: () => _enterDirectorSheet(scene),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _filtersRow(
    List<String> categories,
    List<String> types,
    List<String> difficulties,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _filterDropdown(
          label: 'Catégorie',
          value: _filterCategory,
          values: categories,
          onChanged: (v) => setState(() => _filterCategory = v),
        ),
        _filterDropdown(
          label: 'Type',
          value: _filterType,
          values: types,
          onChanged: (v) => setState(() => _filterType = v),
        ),
        _filterDropdown(
          label: 'Difficulté',
          value: _filterDifficulty,
          values: difficulties,
          onChanged: (v) => setState(() => _filterDifficulty = v),
        ),
      ],
    );
  }

  Widget _filterDropdown({
    required String label,
    required String? value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _softBorder(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isDense: true,
          value: value,
          dropdownColor: _surface(context),
          hint: Text(
            label,
            style: GoogleFonts.dmSans(
              color: _secondaryText(context),
              fontSize: 12,
            ),
          ),
          icon: Icon(Icons.expand_more, color: _secondaryText(context), size: 18),
          style: GoogleFonts.dmSans(color: _primaryText(context), fontSize: 13),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'Tous · $label',
                style: GoogleFonts.dmSans(color: _secondaryText(context), fontSize: 12),
              ),
            ),
            for (final v in values)
              DropdownMenuItem<String?>(value: v, child: Text(v)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ─── Stage: Director sheet ──────────────────────────────────────────
  Widget _buildDirectorSheet() {
    final scene = _scene!;
    final userPlanCount = _timeline.where((m) => m.requiresUserRecording).length;
    final introDuration = _timeline
        .where((m) => m.type == GuidedMarkerType.introAiVideo)
        .fold<int>(0, (total, marker) => total + marker.durationSeconds);
    final completed = _validatedUserSegmentCount;
    final canGenerate = _allRequiredUserSegmentsUploaded;
    final metadata = <String>[
      scene.category,
      if (scene.sceneType.trim().isNotEmpty) scene.sceneType,
      if (scene.difficulty.trim().isNotEmpty) scene.difficulty,
    ].join(' · ');
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _backToLibrary,
                icon: Icon(Icons.arrow_back, color: _primaryText(context)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Plan de tournage Take60',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _primaryText(context),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(
              'Visualise toute la scène, puis enregistre tes séquences une par une.',
              style: GoogleFonts.dmSans(
                color: _secondaryText(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _DirectorBlock(
            title: scene.title,
            subtitle: metadata,
          ),
          _DirectorRow(
            label: 'Catégorie / genre / difficulté',
            value: metadata,
          ),
          _DirectorRow(label: 'Personnage à jouer', value: scene.characterToPlay),
          _DirectorRow(label: 'Objectif', value: scene.emotionalObjective),
          _DirectorRow(label: 'Obstacle', value: scene.mainObstacle),
          _DirectorRow(label: 'État émotionnel', value: scene.dominantEmotion),
          _DirectorRow(label: 'Contexte', value: scene.context),
          _DirectorRow(label: 'Ambiance', value: scene.ambiance),
          _DirectorRow(
            label: 'Texte / dialogue',
            value: scene.dialogueText.isEmpty
                ? 'Voir les répliques par plan ci-dessous.'
                : scene.dialogueText,
          ),
          _DirectorRow(
            label: 'Consignes de jeu',
            value: scene.directorInstructions,
          ),
          const _DirectorRow(label: 'Durée totale', value: '60 secondes'),
          _DirectorRow(
            label: 'Séquences à enregistrer',
            value: '$userPlanCount plan(s) utilisateur',
          ),
          _DirectorRow(
            label: 'Intro IA',
            value: '${introDuration > 0 ? introDuration : 16} secondes · prête',
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surface(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _softBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completed / $userPlanCount séquences enregistrées et validées',
                  style: GoogleFonts.dmSans(
                    color: _primaryText(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: _userSegmentProgress,
                  minHeight: 8,
                  backgroundColor: _surfaceMuted(context),
                  valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                ),
                const SizedBox(height: 10),
                Text(
                  'Durée totale : 60 secondes max · ${_timeline.length} plans · alternance IA / utilisateur',
                  style: GoogleFonts.dmSans(
                    color: _secondaryText(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Liste complète des séquences',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w800,
              color: _primaryText(context),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ..._timeline.map(
            (marker) => _ShootingPlanCard(
              marker: marker,
              statusLabel: _statusLabelForMarker(marker),
              statusColor: _statusColorForMarker(marker),
              hasPlayableVideo: _hasPlayableAiVideo(marker),
              onPrimary: marker.requiresUserRecording
                  ? () => _startMarkerFromPlan(marker)
                  : () => _startMarkerFromPlan(marker),
              onReplay: marker.requiresUserRecording &&
                      _recordingForMarker(marker) != null
                  ? () => _replayPlan(marker)
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          if (_publicationStatus.isNotEmpty) ...[
            Text(
              _publicationStatus,
              style: GoogleFonts.dmSans(
                color: _accent2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (_savingDraft || _publishing) ? null : _saveAsDraft,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _softBorder(context)),
                    foregroundColor: _primaryText(context),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(_savingDraft
                      ? 'Enregistrement…'
                      : 'Enregistrer en brouillon'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: canGenerate ? _renderFinalVideo : _startScene,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(canGenerate
                      ? 'Générer le montage final'
                      : 'Démarrer la scène'),
                ),
              ),
            ],
          ),
          if ((scene.videoUrl?.isNotEmpty ?? false) ||
              _timeline.any((marker) => (marker.videoUrl?.isNotEmpty ?? false))) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openAiIntro,
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Voir l’intro IA en aperçu'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryText(context),
                  side: BorderSide(color: _softBorder(context)),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Stage: AI Playback ──────────────────────────────────────────────
  Widget _buildAiPlayback() {
    final marker = _currentMarker;
    final controller = _aiController;
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: Colors.black,
            child: FutureBuilder<void>(
              future: _aiInit,
              builder: (_, snapshot) {
                if (controller != null && controller.value.isInitialized) {
                  return Center(
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio == 0
                          ? 16 / 9
                          : controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(color: _accent),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              IconButton(
                onPressed: _backToLibrary,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
              const Spacer(),
              if (marker != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Plan IA ${_aiPlanIndexLabel(marker)} / ${_aiPlanCountLabel()} · ${marker.label}',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
          child: Column(
            children: [
              Text(
                'Prépare-toi, ton passage arrive après cette vidéo.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    FilledButton(
                      onPressed: _aiPlanCompleted ? _onAiFinished : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor:
                            Colors.white.withValues(alpha: 0.16),
                        disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.56),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: Text(
                        _aiPlanCompleted
                            ? 'Préparer ma caméra'
                            : 'Plan IA en cours…',
                      ),
                    ),
                    if (kDebugMode && !_aiPlanCompleted) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _markAiCompleted,
                        child: const Text('Debug · terminer le plan IA'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Stage: Camera prep ──────────────────────────────────────────────
  Widget _buildPrepCamera(CameraService cameraService) {
    final marker = _currentMarker;
    if (marker == null) return const SizedBox.shrink();
    final cameraDenied = _cameraInitResult != null && !_cameraInitResult!.isReady;
    return Stack(
      children: [
        Positioned.fill(
        child: cameraDenied
          ? _PermissionStateView(
            title: 'Caméra et micro requis',
            message: _cameraPermissionMessage ??
              'Autorise la caméra et le micro pour continuer.',
            needsSettings: _cameraInitResult!.needsSettings,
            onRetry: _enterPrepCamera,
            onOpenSettings: _cameraInitResult!.needsSettings
              ? PermissionService().openSettings
              : null,
          )
          : _cameraInitializing
            ? const _CenteredLoader(label: 'Préparation caméra…')
            : (cameraService.controller?.value.isInitialized == true
              ? CameraPreview(cameraService.controller!)
              : _PermissionStateView(
                title: 'Caméra non disponible',
                message: _cameraPermissionMessage ??
                  cameraService.errorMessage ??
                  'La caméra n’a pas pu être initialisée. Réessaie ou vérifie tes autorisations caméra et micro.',
                needsSettings: false,
                onRetry: _enterPrepCamera,
              )),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              IconButton(
                onPressed: _backToLibrary,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
              const Spacer(),
              IconButton(
                onPressed: cameraService.isReady && !cameraDenied
                    ? () => cameraService.toggleFlash()
                    : null,
                icon: Icon(
                  cameraService.flashMode == FlashMode.torch
                      ? Icons.flash_on
                      : Icons.flash_off,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: cameraService.isReady && !cameraDenied
                    ? () => cameraService.flipCamera()
                    : null,
                icon: const Icon(
                  Icons.flip_camera_android_rounded,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Réglages caméra accessibles via les contrôles système.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
              ),
            ],
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(child: _FramingOverlay()),
        ),
        if (cameraService.isReady && !cameraDenied)
        const Positioned(
          top: 82,
          left: 20,
          child: _CameraStatusChip(
            icon: Icons.mic_rounded,
            label: 'Micro activé',
          ),
        ),
        Positioned(
          top: 82,
          right: 20,
          child: _CameraStatusChip(
            icon: Icons.timer_outlined,
            label: '${marker.durationSeconds}s à jouer',
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 30,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _CueCard(
                  badge:
                      'Plan utilisateur ${_userPlanIndexLabel(marker)} / ${_userPlanCountLabel()}',
                  duration: '${marker.durationSeconds}s',
                  dialogue: marker.dialogue,
                  helper: marker.cueText.isEmpty
                      ? 'Joue ta réplique maintenant.'
                      : marker.cueText,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed:
                      cameraService.isReady && !cameraDenied ? _startCountdown : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  child: const Text('Démarrer l’enregistrement'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Stage: Countdown ──────────────────────────────────────────────────
  Widget _buildCountdown() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_countdownValue',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 120,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Prépare-toi à jouer.',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stage: Recording ────────────────────────────────────────────────
  Widget _buildRecording(CameraService cameraService) {
    final marker = _currentMarker;
    return Stack(
      children: [
        Positioned.fill(
          child: cameraService.controller?.value.isInitialized == true
              ? CameraPreview(cameraService.controller!)
              : const _CenteredLoader(label: 'Préparation caméra…'),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _danger.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'REC',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${cameraService.remainingSeconds.clamp(0, 60).toString().padLeft(2, '0')}s restantes',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (marker != null)
          const Positioned.fill(
            child: IgnorePointer(child: _FramingOverlay()),
          ),
        if (marker != null)
          const Positioned(
            top: 64,
            left: 20,
            child: _CameraStatusChip(
              icon: Icons.mic_rounded,
              label: 'Micro activé',
            ),
          ),
        if (marker != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _CueCard(
                badge:
                    'Plan utilisateur ${_userPlanIndexLabel(marker)} / ${_userPlanCountLabel()}',
                duration: '${marker.durationSeconds}s',
                dialogue: marker.dialogue,
                helper: 'Joue maintenant.',
              ),
            ),
          ),
      ],
    );
  }

  String _userPlanCountLabel() {
    return _timeline.where((m) => m.requiresUserRecording).length.toString();
  }

  String _userPlanIndexLabel(Take60SceneMarker marker) {
    var idx = 0;
    for (final m in _timeline) {
      if (m.requiresUserRecording) {
        idx++;
        if (m.id == marker.id) return idx.toString();
      }
    }
    return idx.toString();
  }

  String _aiPlanCountLabel() {
    return _timeline.where((m) => !m.requiresUserRecording).length.toString();
  }

  String _aiPlanIndexLabel(Take60SceneMarker marker) {
    var idx = 0;
    for (final m in _timeline) {
      if (!m.requiresUserRecording) {
        idx++;
        if (m.id == marker.id) return idx.toString();
      }
    }
    return idx.toString();
  }

  // ─── Stage: Preview ──────────────────────────────────────────────────
  Widget _buildPreview() {
    final draft = _previewRecording;
    final remainingUploads = _requiredUserSegmentCount - _uploadedUserSegmentCount;
    final canRenderNow = _isLastTimelineMarker && _allRequiredUserSegmentsUploaded;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revoir ce plan',
            style: GoogleFonts.dmSans(
              color: _primaryText(context),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _previewController != null &&
                    _previewController!.value.isInitialized
                ? FutureBuilder<void>(
                    future: _previewInit,
                    builder: (_, __) => Stack(
                      children: [
                        Positioned.fill(child: VideoPlayer(_previewController!)),
                        Center(
                          child: IconButton(
                            iconSize: 64,
                            onPressed: () {
                              final controller = _previewController!;
                              setState(() {
                                if (controller.value.isPlaying) {
                                  controller.pause();
                                } else {
                                  controller.play();
                                }
                              });
                            },
                            icon: Icon(
                              _previewController!.value.isPlaying
                                  ? Icons.pause_circle
                                  : Icons.play_circle,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const _CenteredLoader(label: 'Préparation preview…'),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surface(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _softBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progression prise utilisateur',
                  style: GoogleFonts.dmSans(
                    color: _primaryText(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _userSegmentProgress,
                  minHeight: 8,
                  backgroundColor: _surfaceMuted(context),
                  valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_validatedUserSegmentCount/$_requiredUserSegmentCount segments validés · $_uploadedUserSegmentCount uploadés',
                  style: GoogleFonts.dmSans(
                    color: _secondaryText(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (draft != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Durée enregistrée: ${draft.durationSeconds}s',
                  style: GoogleFonts.dmSans(
                    color: _secondaryText(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  draft.isUploaded
                      ? 'Upload Storage prêt pour le montage.'
                      : 'Upload Storage en attente. Le montage final restera bloqué tant que ce segment n’est pas distant.',
                  style: GoogleFonts.dmSans(
                    color: draft.isUploaded ? Colors.green.shade600 : _danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: OutlinedButton.icon(
                  onPressed: _retakeCurrentPlan,
                  icon: const Icon(Icons.replay),
                  label: const Text('Rejouer la scène'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryText(context),
                    side: BorderSide(color: _softBorder(context)),
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: FilledButton.icon(
                  onPressed: _isPreviewValidated ? null : _validateCurrentPlan,
                  icon: Icon(
                    _isPreviewValidated ? Icons.check_circle : Icons.check,
                  ),
                  label: Text(
                    _isPreviewValidated ? 'Plan validé' : 'Valider ce plan',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
              SizedBox(
                width: 260,
                child: OutlinedButton.icon(
                  onPressed: kDebugMode
                      ? (_isLastTimelineMarker
                          ? (canRenderNow ? _renderFinalVideo : null)
                          : _goToNextSegment)
                      : null,
                  icon: Icon(
                    _isLastTimelineMarker ? Icons.auto_fix_high : Icons.skip_next,
                  ),
                  label: Text(
                    _isLastTimelineMarker
                        ? 'Debug · regénérer'
                        : 'Debug · segment suivant',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryText(context),
                    side: BorderSide(color: _softBorder(context)),
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],
          ),
          if (_isLastTimelineMarker && !canRenderNow)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                remainingUploads > 0
                    ? 'Rendu final bloqué: $remainingUploads segment(s) pas encore uploadé(s) sur Storage.'
                    : 'Rendu final bloqué: valide d’abord la prise en cours.',
                style: GoogleFonts.dmSans(
                  color: _danger,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Stage: Rendering ────────────────────────────────────────────────
  Widget _buildRendering() {
    if (_renderErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _danger, size: 40),
              const SizedBox(height: 16),
              Text(
                _renderErrorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(color: _primaryText(context), fontSize: 14),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _renderFinalVideo,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer le rendu'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _renderErrorMessage = null;
                    _statusMessage = null;
                    _stage = _Stage.director;
                  });
                },
                child: const Text('Retour au briefing'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _accent),
          const SizedBox(height: 16),
          Text(
            _statusMessage ?? 'Montage final en cours…',
            style: GoogleFonts.dmSans(color: _primaryText(context), fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ─── Stage: Final ────────────────────────────────────────────────────
  Widget _buildFinalScreen() {
    final result = _renderResult;
    final canPublish = _finalVideoValidated &&
        (result?.finalVideoUrl.isNotEmpty ?? false) &&
        !_savingDraft &&
        !_publishing;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Montage final',
            style: GoogleFonts.dmSans(
              color: _primaryText(context),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ta scène Take60 est prête.',
            style: GoogleFonts.dmSans(
              color: _secondaryText(context),
            ),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _finalController != null &&
                    _finalController!.value.isInitialized
                ? FutureBuilder<void>(
                    future: _finalInit,
                    builder: (_, __) => Stack(
                      children: [
                        Positioned.fill(child: VideoPlayer(_finalController!)),
                        Center(
                          child: IconButton(
                            iconSize: 64,
                            onPressed: () {
                              final controller = _finalController!;
                              setState(() {
                                if (controller.value.isPlaying) {
                                  controller.pause();
                                } else {
                                  controller.play();
                                }
                              });
                            },
                            icon: Icon(
                              _finalController!.value.isPlaying
                                  ? Icons.pause_circle
                                  : Icons.play_circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    color: _surfaceMuted(context),
                    alignment: Alignment.center,
                    child: Text(
                      result == null
                          ? 'Aucun rendu disponible.'
                          : 'Rendu prêt: ${result.durationSeconds}s · ${result.segments.length} segments',
                      style: GoogleFonts.dmSans(color: _secondaryText(context)),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          if (_showUserPlanList) ...[
            Text(
              'Plans utilisateur enregistrés',
              style: GoogleFonts.dmSans(
                color: _primaryText(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ..._timeline.where((m) => m.requiresUserRecording).map(
                (marker) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.movie_creation_outlined,
                      color: _accent),
                  title: Text(
                    marker.label,
                    style: GoogleFonts.dmSans(color: _primaryText(context)),
                  ),
                  subtitle: Text(
                    marker.dialogue,
                    style: GoogleFonts.dmSans(color: _secondaryText(context)),
                  ),
                  trailing: TextButton(
                    onPressed: () => _replayPlan(marker),
                    child: const Text('Rejouer'),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
          if (_publicationStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _publicationStatus,
                style: GoogleFonts.dmSans(
                  color: _accent2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: result?.finalVideoUrl.isNotEmpty == true
                    ? () {
                        final controller = _finalController;
                        if (controller == null) return;
                        setState(() {
                          if (controller.value.isPlaying) {
                            controller.pause();
                          } else {
                            controller.play();
                          }
                        });
                      }
                    : null,
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Lire le montage final'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _showUserPlanList = !_showUserPlanList),
                icon: const Icon(Icons.movie_creation_outlined),
                label: const Text('Rejouer certains plans'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryText(context),
                  side: BorderSide(color: _softBorder(context)),
                ),
              ),
              FilledButton.icon(
                onPressed: result?.finalVideoUrl.isNotEmpty == true
                    ? () => setState(() {
                          _finalVideoValidated = true;
                          _publicationStatus = 'Vidéo validée. Tu peux publier.';
                        })
                    : null,
                icon: const Icon(Icons.verified_rounded),
                label: const Text('Valider ma vidéo'),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _finalVideoValidated ? Colors.green : _accent,
                  foregroundColor: Colors.black,
                ),
              ),
              OutlinedButton.icon(
                onPressed: (_savingDraft || _publishing) ? null : _saveAsDraft,
                icon: _savingDraft
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_savingDraft
                    ? 'Enregistrement…'
                  : 'Enregistrer en brouillon'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryText(context),
                  side: BorderSide(color: _softBorder(context)),
                ),
              ),
              FilledButton.icon(
                onPressed: canPublish ? _publish : null,
                icon: _publishing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.publish),
                label: Text(_publishing ? 'Publication…' : 'Publier'),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                ),
              ),
              TextButton.icon(
                onPressed: _backToLibrary,
                icon: Icon(Icons.home, color: _secondaryText(context)),
                label: Text(
                  'Retour bibliothèque',
                  style: GoogleFonts.dmSans(color: _secondaryText(context)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Internal widgets ─────────────────────────────────────────────────────

class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.scene, required this.onPlay});

  final SceneModel scene;
  final VoidCallback onPlay;

  static const _accent = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context) {
    final userPlans = scene.userPlanCount > 0
        ? '${scene.userPlanCount} plan(s) à jouer'
        : 'Plans à jouer définis par l\'admin';
    final surface = AppThemeTokens.chromeSurface(context);
    final primaryText = AppThemeTokens.primaryText(context);
    final secondaryText = AppThemeTokens.secondaryText(context);
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPlay,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: _Thumbnail(thumbnailUrl: scene.thumbnailUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.title,
                      style: GoogleFonts.dmSans(
                        color: primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${scene.category} · ${scene.sceneType}',
                      style: GoogleFonts.dmSans(
                        color: secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        const _Pill(label: '60 s'),
                        _Pill(label: scene.difficulty.isEmpty
                            ? 'Difficulté libre'
                            : scene.difficulty),
                        _Pill(label: userPlans),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: onPlay,
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Jouer cette scène'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.thumbnailUrl});

  final String thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = AppThemeTokens.surfaceMuted(context);
    if (thumbnailUrl.isEmpty) {
      return Container(color: fallback);
    }
    if (thumbnailUrl.startsWith('http')) {
      return Image.network(
        thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: fallback),
      );
    }
    if (thumbnailUrl.startsWith('assets/')) {
      return Image.asset(
        thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: fallback),
      );
    }
    if (!kIsWeb) {
      return Image.file(
        File(thumbnailUrl),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: fallback),
      );
    }
    return Container(color: fallback);
  }
}

class _CameraStatusChip extends StatelessWidget {
  const _CameraStatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShootingPlanCard extends StatelessWidget {
  const _ShootingPlanCard({
    required this.marker,
    required this.statusLabel,
    required this.statusColor,
    required this.hasPlayableVideo,
    required this.onPrimary,
    this.onReplay,
  });

  final Take60SceneMarker marker;
  final String statusLabel;
  final Color statusColor;
  final bool hasPlayableVideo;
  final VoidCallback onPrimary;
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context) {
    final isUser = marker.requiresUserRecording;
    final title = isUser ? 'À toi de jouer' : 'Plan IA';
    final canOpenPlan = isUser || hasPlayableVideo;
    final buttonLabel = isUser
        ? 'Enregistrer cette séquence'
      : (!hasPlayableVideo
        ? 'Vidéo IA indisponible'
        : marker.type == GuidedMarkerType.introAiVideo
            ? 'Voir l’introduction'
            : 'Voir le plan IA');
    final borderColor = isUser
        ? const Color(0xFF7C3AED).withValues(alpha: 0.36)
        : const Color(0xFF06B6D4).withValues(alpha: 0.34);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isUser
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF06B6D4))
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isUser ? Icons.videocam_rounded : Icons.movie_filter_outlined,
                  color: isUser
                      ? const Color(0xFFA78BFA)
                      : const Color(0xFF22D3EE),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title · ${marker.durationSeconds}s',
                      style: GoogleFonts.dmSans(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      marker.label.isEmpty ? marker.type.value : marker.label,
                      style: GoogleFonts.dmSans(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.66),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.38)),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.dmSans(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (marker.character.trim().isNotEmpty)
            _PlanCardLine(label: 'Personnage', value: marker.character),
          if (marker.dialogue.trim().isNotEmpty)
            _PlanCardLine(label: 'Dialogue attendu', value: marker.dialogue),
          if (marker.cueText.trim().isNotEmpty)
            _PlanCardLine(label: 'Consigne', value: marker.cueText),
          _PlanCardLine(label: 'Caméra', value: marker.cameraPlan),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: canOpenPlan ? onPrimary : null,
                icon: Icon(isUser ? Icons.fiber_manual_record : Icons.play_arrow),
                label: Text(buttonLabel),
              ),
              if (onReplay != null)
                OutlinedButton.icon(
                  onPressed: onReplay,
                  icon: const Icon(Icons.replay),
                  label: const Text('Rejouer'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCardLine extends StatelessWidget {
  const _PlanCardLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.dmSans(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 12.5,
          ),
          children: [
            TextSpan(
              text: '$label : ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _FramingOverlay extends StatelessWidget {
  const _FramingOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.72,
        heightFactor: 0.48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.72),
              width: 1.4,
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                left: 12,
                top: 12,
                child: _FrameCorner(alignment: Alignment.topLeft),
              ),
              const Positioned(
                right: 12,
                top: 12,
                child: _FrameCorner(alignment: Alignment.topRight),
              ),
              const Positioned(
                left: 12,
                bottom: 12,
                child: _FrameCorner(alignment: Alignment.bottomLeft),
              ),
              const Positioned(
                right: 12,
                bottom: 12,
                child: _FrameCorner(alignment: Alignment.bottomRight),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.52),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Place ton visage dans la zone',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrameCorner extends StatelessWidget {
  const _FrameCorner({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y < 0
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            bottom: alignment.y > 0
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            left: alignment.x < 0
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            right: alignment.x > 0
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final primaryText = AppThemeTokens.primaryText(context);
    final softAction = AppThemeTokens.softAction(context);
    final softBorder = AppThemeTokens.softBorder(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: softAction,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: softBorder),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: primaryText,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DirectorBlock extends StatelessWidget {
  const _DirectorBlock({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final softAction = AppThemeTokens.softAction(context);
    final primaryText = AppThemeTokens.primaryText(context);
    final secondaryText = AppThemeTokens.secondaryText(context);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: softAction,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              color: primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              color: secondaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectorRow extends StatelessWidget {
  const _DirectorRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final primaryText = AppThemeTokens.primaryText(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: const Color(0xFFFFB800),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: primaryText,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionStateView extends StatelessWidget {
  const _PermissionStateView({
    required this.title,
    required this.message,
    required this.needsSettings,
    required this.onRetry,
    this.onOpenSettings,
  });

  final String title;
  final String message;
  final bool needsSettings;
  final Future<void> Function() onRetry;
  final Future<void> Function()? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final surface = AppThemeTokens.chromeSurface(context);
    final primaryText = AppThemeTokens.primaryText(context);
    final secondaryText = AppThemeTokens.secondaryText(context);
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              key: const Key('take60_permission_denied_state'),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      color: primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: GoogleFonts.dmSans(
                      color: secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('take60_permission_retry_button'),
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: const Color(0xFFFFB800),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Réessayer'),
                  ),
                  if (needsSettings && onOpenSettings != null) ...[
                    const SizedBox(height: 10),
                    OutlinedButton(
                      key: const Key('take60_permission_settings_button'),
                      onPressed: onOpenSettings,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: primaryText,
                      ),
                      child: const Text('Ouvrir les réglages'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CueCard extends StatelessWidget {
  const _CueCard({
    required this.badge,
    required this.duration,
    required this.dialogue,
    required this.helper,
  });

  final String badge;
  final String duration;
  final String dialogue;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.dmSans(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                duration,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (dialogue.isNotEmpty)
            Text(
              '« $dialogue »',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            helper,
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final background = AppThemeTokens.pageBackground(context);
    final primaryText = AppThemeTokens.primaryText(context);
    return Container(
      color: background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFFFFB800)),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.dmSans(color: primaryText),
            ),
          ],
        ),
      ),
    );
  }
}
