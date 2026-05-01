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
import '../providers/providers.dart';
import '../router/router.dart';
import '../services/camera_service.dart';
import '../services/permission_service.dart';
import '../services/take60_guided_scene_service.dart';
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
  const Take60GuidedRecordScreen({super.key, this.initialScene});

  final SceneModel? initialScene;

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
  static const _bg = Color(0xFF0B1020);
  static const _surface = Color(0xFF111827);
  static const _surfaceMuted = Color(0xFF1A2540);
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
  bool _videoValidated = false;
  String? _renderErrorMessage;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialScene != null) {
      _scene = widget.initialScene;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLibrary());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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
        if (_scene != null) {
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
    // Propose la reprise du brouillon si l'utilisateur en a un en cours.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeOfferDraftResume(scene),
    );
  }

  Future<void> _maybeOfferDraftResume(SceneModel scene) async {
    final draft = await _service.loadDraft(sceneId: scene.id);
    if (!mounted || draft == null || draft.recordings.isEmpty) return;
    if (_scene?.id != scene.id) return;
    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Text(
          'Reprendre la scène en cours ?',
          style: GoogleFonts.dmSans(color: Colors.white),
        ),
        content: Text(
          'Tu as ${draft.recordings.length} plan(s) déjà enregistrés pour « ${draft.sceneTitle} ». '
          'Veux-tu reprendre où tu t\'étais arrêté ?',
          style: GoogleFonts.dmSans(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Recommencer',
              style: GoogleFonts.dmSans(color: Colors.white70),
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
      for (final rec in draft.recordings) {
        _recordings[rec.markerId] = rec;
      }
      final resumeIndex = draft.currentMarkerIndex
          .clamp(0, _timeline.isEmpty ? 0 : _timeline.length - 1);
      setState(() => _currentIndex = resumeIndex);
    } else {
      await _service.clearDraft(scene.id);
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
    setState(() {
      _currentIndex = 0;
    });
    _enterMarker(_timeline.first);
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
    final url = (marker.videoUrl?.isNotEmpty ?? false)
        ? marker.videoUrl!
        : (_scene?.videoUrl ?? '');
    setState(() {
      _stage = _Stage.aiPlayback;
      _aiAutoFinished = false;
    });
    if (url.isEmpty) {
      // Pas d'URL → on saute la lecture et on passe directement à la suite.
      _onAiFinished();
      return;
    }
    try {
      final controller = buildVideoPlayerController(url);
      _aiController = controller;
      _aiInit = controller.initialize().then((_) {
        if (!mounted) return;
        controller.addListener(_aiListener);
        controller.play();
        setState(() {});
      });
    } catch (_) {
      // On ne bloque pas le flow si la lecture échoue.
      _onAiFinished();
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
      _onAiFinished();
    }
  }

  void _onAiFinished() {
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
    setState(() {
      _stage = _Stage.prepCamera;
      _cameraInitializing = true;
      _waitingForRecordingResult = false;
    });
    final result =
        await ref.read(recordingProvider.notifier).initCamera(context);
    if (!mounted) return;
    setState(() => _cameraInitializing = false);
    if (!result.isReady) {
      if (result.needsSettings) {
        await _showPermissionsSettingsDialog(result.missingPermissions);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Caméra ou micro non disponibles — vérifie les permissions',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
            backgroundColor: _danger,
            action: SnackBarAction(
              label: 'Réglages',
              textColor: Colors.white,
              onPressed: PermissionService().openSettings,
            ),
          ),
        );
      }
    }
  }

  Future<void> _showPermissionsSettingsDialog(
    List<AppPermission> missingPermissions,
  ) async {
    final labels = missingPermissions
        .map(
          (permission) => switch (permission) {
            AppPermission.camera => 'caméra',
            AppPermission.microphone => 'microphone',
            _ => 'autorisation',
          },
        )
        .join(' et ');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Autorisation requise'),
        content: Text(
          'L\'accès au $labels a été refusé. Ouvre les réglages pour autoriser Take60.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              PermissionService().openSettings();
            },
            child: const Text('Ouvrir les réglages'),
          ),
        ],
      ),
    );
  }

  void _startCountdown() {
    HapticFeedback.heavyImpact();
    setState(() {
      _stage = _Stage.countdown;
      _countdownValue = 10;
    });
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
    setState(() {
      _stage = _Stage.recording;
      _waitingForRecordingResult = true;
    });
    await ref.read(recordingProvider.notifier).startRecording(
          maxDurationSeconds: marker.durationSeconds,
        );
  }

  void _handleRecordingResult(RecordingResult result) {
    final marker = _currentMarker;
    if (marker == null || _scene == null) return;
    _waitingForRecordingResult = false;
    _service
        .persistRecording(
      scene: _scene!,
      marker: marker,
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
      _persistDraft();
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

  void _validateCurrentPlan() {
    final marker = _currentMarker;
    final draft = _previewRecording;
    if (marker == null || draft == null) return;
    final validated = draft.copyWith(
      status: UserPlanStatus.validated,
      updatedAt: DateTime.now(),
    );
    _recordings[marker.id] = validated;
    _disposePreviewController();
    setState(() {
      _previewRecording = null;
    });
    final next = _currentIndex + 1;
    if (next >= _timeline.length) {
      _renderFinalVideo();
      return;
    }
    setState(() => _currentIndex = next);
    _persistDraft();
    _enterMarker(_timeline[next]);
  }

  // ── Final render ────────────────────────────────────────────────────────
  Future<void> _renderFinalVideo() async {
    if (_scene == null) return;
    setState(() {
      _stage = _Stage.rendering;
      _renderResult = null;
      _renderErrorMessage = null;
      _statusMessage = 'Montage en cours…';
    });
    final scene = _scene!;
    try {
      final result = await _service.renderTake60GuidedScene(
        scene: scene,
        recordings: _recordings.values.toList(),
      );
      if (!mounted) return;
      setState(() {
        _renderResult = result;
        _stage = _Stage.finalScreen;
        _statusMessage = null;
      });
      if (result.finalVideoUrl.isNotEmpty) {
        await _initFinalController(result.finalVideoUrl);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _renderErrorMessage = error.toString();
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
    if (_scene == null || _renderResult == null) return;
    setState(() => _publicationStatus = 'Brouillon en cours d\'enregistrement…');
    await _service.saveRenderedProject(
      scene: _scene!,
      recordings: _recordings.values.toList(),
      renderResult: _renderResult!,
      status: 'draft',
    );
    if (!mounted) return;
    setState(() => _publicationStatus = 'Brouillon enregistré.');
  }

  void _validateVideo() {
    if (_renderResult == null) return;
    setState(() {
      _videoValidated = true;
      _publicationStatus = 'Vidéo validée. Tu peux maintenant publier.';
    });
  }

  Future<void> _publish() async {
    if (_scene == null || _renderResult == null) return;
    if (!_videoValidated) {
      setState(() => _publicationStatus =
          'Valide d\'abord ta vidéo avant publication.');
      return;
    }
    setState(() => _publicationStatus = 'Publication en cours…');
    await _service.saveRenderedProject(
      scene: _scene!,
      recordings: _recordings.values.toList(),
      renderResult: _renderResult!,
      status: 'published',
    );
    if (!mounted) return;
    setState(() => _publicationStatus = 'Vidéo publiée.');
    await _service.clearDraft(_scene!.id);
  }

  Future<void> _persistDraft() async {
    if (_scene == null) return;
    await _service.saveDraft(
      scene: _scene!,
      currentMarkerIndex: _currentIndex,
      status: _stage == _Stage.preview
          ? SceneRecordingStatus.previewUserPlan
          : SceneRecordingStatus.userPlanValidated,
      recordings: _recordings.values.toList(),
    );
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

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cameraService = ref.watch(cameraServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeHandleCameraResult(cameraService),
    );
    return Scaffold(
      backgroundColor: _bg,
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
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Créer ma scène Take60',
                        style: GoogleFonts.dmSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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
                    color: Colors.white.withValues(alpha: 0.65),
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
                    color: Colors.white.withValues(alpha: 0.65),
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
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isDense: true,
          value: value,
          dropdownColor: _surface,
          hint: Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          icon: const Icon(Icons.expand_more, color: Colors.white70, size: 18),
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'Tous · $label',
                style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _backToLibrary,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Fiche réalisateur',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DirectorBlock(
            title: scene.title,
            subtitle: '${scene.category} · ${scene.sceneType}',
          ),
          _DirectorRow(label: 'Ambiance', value: scene.ambiance),
          _DirectorRow(label: 'Personnage à jouer', value: scene.characterToPlay),
          _DirectorRow(label: 'Contexte', value: scene.context),
          _DirectorRow(
            label: 'Objectif émotionnel',
            value: scene.emotionalObjective,
          ),
          _DirectorRow(
            label: 'Texte imposé',
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
          const SizedBox(height: 12),
          Text(
            'Timeline',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ..._timeline.map(
            (marker) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    marker.requiresUserRecording
                        ? Icons.videocam_rounded
                        : Icons.movie_filter_outlined,
                    size: 16,
                    color: marker.requiresUserRecording ? _accent : _accent2,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${marker.label} · ${marker.durationSeconds}s',
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _backToLibrary,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _startScene,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Démarrer la scène'),
                ),
              ),
            ],
          ),
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
                child: FilledButton(
                  onPressed: _onAiFinished,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Préparer ma caméra'),
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
    return Stack(
      children: [
        Positioned.fill(
          child: _cameraInitializing
              ? const _CenteredLoader(label: 'Préparation caméra…')
              : (cameraService.controller?.value.isInitialized == true
                  ? CameraPreview(cameraService.controller!)
                  : const _CenteredLoader(label: 'Caméra non disponible')),
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
                onPressed: cameraService.isReady
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
                onPressed: cameraService.isReady
                    ? () => cameraService.flipCamera()
                    : null,
                icon: const Icon(
                  Icons.flip_camera_android_rounded,
                  color: Colors.white,
                ),
              ),
            ],
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
                  onPressed: cameraService.isReady ? _startCountdown : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  child: const Text('Enregistrer'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revoir ce plan',
            style: GoogleFonts.dmSans(
              color: Colors.white,
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
          if (draft != null)
            Text(
              'Durée enregistrée: ${draft.durationSeconds}s',
              style: GoogleFonts.dmSans(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retakeCurrentPlan,
                  icon: const Icon(Icons.replay),
                  label: const Text('Rejouer la scène'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _validateCurrentPlan,
                  icon: const Icon(Icons.check),
                  label: const Text('Valider ce plan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],
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
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
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
            _statusMessage ?? 'Montage en cours…',
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ─── Stage: Final ────────────────────────────────────────────────────
  Widget _buildFinalScreen() {
    final result = _renderResult;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Montage final',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ta scène Take60 est prête.',
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.65),
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
                    color: _surfaceMuted,
                    alignment: Alignment.center,
                    child: Text(
                      result == null
                          ? 'Aucun rendu disponible.'
                          : 'Rendu prêt: ${result.durationSeconds}s · ${result.segments.length} segments',
                      style: GoogleFonts.dmSans(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            'Plans utilisateur enregistrés',
            style: GoogleFonts.dmSans(
              color: Colors.white,
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
                    style: GoogleFonts.dmSans(color: Colors.white),
                  ),
                  subtitle: Text(
                    marker.dialogue,
                    style: GoogleFonts.dmSans(color: Colors.white60),
                  ),
                  trailing: TextButton(
                    onPressed: () => _replayPlan(marker),
                    child: const Text('Rejouer'),
                  ),
                ),
              ),
          const SizedBox(height: 16),
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
              OutlinedButton.icon(
                onPressed: _saveAsDraft,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Enregistrer en brouillon'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _videoValidated ? null : _validateVideo,
                icon: Icon(
                  _videoValidated ? Icons.check_circle : Icons.check,
                ),
                label: Text(
                  _videoValidated ? 'Vidéo validée' : 'Valider ma vidéo',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _videoValidated
                      ? Colors.green.shade600
                      : Colors.white,
                  foregroundColor:
                      _videoValidated ? Colors.white : Colors.black,
                ),
              ),
              FilledButton.icon(
                onPressed: _videoValidated ? _publish : null,
                icon: const Icon(Icons.publish),
                label: const Text('Publier'),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                ),
              ),
              TextButton.icon(
                onPressed: _backToLibrary,
                icon: const Icon(Icons.home, color: Colors.white70),
                label: Text(
                  'Retour bibliothèque',
                  style: GoogleFonts.dmSans(color: Colors.white70),
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

  static const _surface = Color(0xFF111827);
  static const _accent = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context) {
    final userPlans = scene.userPlanCount > 0
        ? '${scene.userPlanCount} plan(s) à jouer'
        : 'Plans à jouer définis par l\'admin';
    return Material(
      color: _surface,
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
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${scene.category} · ${scene.sceneType}',
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.65),
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
    if (thumbnailUrl.isEmpty) {
      return Container(color: const Color(0xFF1A2540));
    }
    if (thumbnailUrl.startsWith('http')) {
      return Image.network(
        thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: const Color(0xFF1A2540)),
      );
    }
    if (thumbnailUrl.startsWith('assets/')) {
      return Image.asset(
        thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: const Color(0xFF1A2540)),
      );
    }
    if (!kIsWeb) {
      return Image.file(
        File(thumbnailUrl),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: const Color(0xFF1A2540)),
      );
    }
    return Container(color: const Color(0xFF1A2540));
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: Colors.white.withValues(alpha: 0.85),
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
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.65),
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
              color: Colors.white,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
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
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFFFFB800)),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
