import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../router/router.dart';
import '../services/camera_service.dart';
import '../widgets/shared_widgets.dart';

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  bool _isPreparingCamera = false;
  bool _permissionsGranted = false;
  RecordingResult? _lastRecording;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareCamera();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _prepareCamera() async {
    if (_isPreparingCamera) {
      return;
    }

    setState(() {
      _isPreparingCamera = true;
    });

    final granted = await ref.read(permissionProvider).requestCameraAndMic();

    if (!mounted) {
      return;
    }

    if (!granted) {
      setState(() {
        _permissionsGranted = false;
        _isPreparingCamera = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caméra et microphone requis pour enregistrer un take')),
      );
      return;
    }

    final initialized = await ref.read(cameraServiceProvider).initialize();

    if (!mounted) {
      return;
    }

    setState(() {
      _permissionsGranted = granted && initialized;
      _isPreparingCamera = false;
    });

    if (!initialized) {
      final message = ref.read(cameraServiceProvider).errorMessage ?? 'Impossible d’initialiser la caméra';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _startRecording() async {
    final camera = ref.read(cameraServiceProvider);
    final started = await camera.startRecording();

    if (!mounted) {
      return;
    }

    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(camera.errorMessage ?? 'Impossible de démarrer l’enregistrement')),
      );
      return;
    }

    setState(() {
      _lastRecording = null;
    });
    await ref.read(hapticsProvider).recordStart();
  }

  Future<void> _stopRecording() async {
    final result = await ref.read(cameraServiceProvider).stopRecording();

    if (!mounted) {
      return;
    }

    if (result == null) {
      final camera = ref.read(cameraServiceProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(camera.errorMessage ?? 'Impossible d’arrêter l’enregistrement')),
      );
      return;
    }

    setState(() {
      _lastRecording = result;
    });
    await ref.read(hapticsProvider).recordStop();
  }

  void _openPreview() {
    final draft = TakeDraft(
      title: 'Mon Take créatif',
      description: 'Une capsule rapide tournée ce soir, avec une ambiance chaleureuse et un montage dynamique.',
      sceneType: 'Lifestyle',
      duration: 30,
      mood: 'Montage auto',
    );

    context.push(AppRouter.preview, extra: draft);
  }

  @override
  Widget build(BuildContext context) {
    final camera = ref.watch(cameraServiceProvider);
    final showRecordingVisual = camera.isRecording || _lastRecording == null;

    return PageWrap(
      title: 'Enregistrer',
      trailing: TakeHeaderButton(
        icon: Icons.close_rounded,
        onPressed: () => context.go(AppRouter.home),
      ),
      showBottomNav: true,
      activeTab: TakeTab.record,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              _RecordTimerCircle(
                time: _displayClock(camera),
                label: showRecordingVisual ? 'En cours' : 'Prêt',
                recording: showRecordingVisual,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RecordControlButton(
                    icon: Icons.pause_rounded,
                    size: 52,
                    onPressed: null,
                  ),
                  const SizedBox(width: 16),
                  _RecordControlButton(
                    icon: camera.isRecording ? Icons.stop_rounded : Icons.fiber_manual_record,
                    size: 64,
                    accent: true,
                    onPressed: _isPreparingCamera
                        ? null
                        : camera.isRecording
                            ? _stopRecording
                            : _permissionsGranted && camera.isReady
                                ? _startRecording
                                : _prepareCamera,
                  ),
                  const SizedBox(width: 16),
                  _RecordControlButton(
                    icon: Icons.stop_circle_outlined,
                    size: 52,
                    onPressed: _lastRecording != null ? _openPreview : null,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SectionCard(
                title: 'Scène 3 / 5',
                subtitle: 'Progression globale du tournage.',
                trailing: const TakePill(label: '● LIVE', tone: TakePillTone.red),
                child: TakeProgressBar(value: camera.isRecording ? camera.progress.clamp(0, 1) : 0.6),
              ),
              if (_lastRecording != null)
                Row(
                  children: [
                    Expanded(
                      child: InfoStat(
                        label: 'Durée',
                        value: '${_lastRecording!.durationSeconds}s',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InfoStat(
                        label: 'Taille',
                        value: _formatBytes(_lastRecording!.fileSizeBytes),
                      ),
                    ),
                  ],
                ),
              if (_isPreparingCamera || !_permissionsGranted || camera.errorMessage != null) ...[
                const SizedBox(height: 10),
                SectionCard(
                  title: 'Camera',
                  subtitle: _cameraSubtitle(camera),
                  icon: Icons.videocam_outlined,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _cameraSubtitle(CameraService camera) {
    if (_isPreparingCamera) {
      return 'Initialisation de la caméra...';
    }
    if (!_permissionsGranted) {
      return 'Caméra et microphone requis pour capturer un take.';
    }
    if (camera.isRecording) {
      return 'Enregistrement en cours • ${camera.elapsedSeconds}s / ${CameraService.maxRecordingSeconds}s';
    }
    if (_lastRecording != null) {
      return 'Dernier clip capturé • ${_lastRecording!.durationSeconds}s';
    }
    if (camera.isReady) {
      return 'Caméra prête. Lance un clip puis ouvre la prévisualisation.';
    }
    return camera.errorMessage ?? 'Caméra indisponible pour le moment.';
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }

  String _displayClock(CameraService camera) {
    if (!camera.isRecording) {
      return '24:37';
    }
    final seconds = camera.elapsedSeconds.toString().padLeft(2, '0');
    return '00:$seconds';
  }
}

class _RecordTimerCircle extends StatelessWidget {
  const _RecordTimerCircle({
    required this.time,
    required this.label,
    required this.recording,
  });

  final String time;
  final String label;
  final bool recording;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: recording ? const Color(0xFFFF4D4F) : const Color(0x14FFFFFF), width: 4),
        boxShadow: recording
            ? const [BoxShadow(color: Color(0x4DFF4D4F), blurRadius: 36)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0x99FFFFFF))),
        ],
      ),
    );
  }
}

class _RecordControlButton extends StatelessWidget {
  const _RecordControlButton({
    required this.icon,
    required this.size,
    required this.onPressed,
    this.accent = false,
  });

  final IconData icon;
  final double size;
  final VoidCallback? onPressed;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent ? const Color(0x2EFF4D4F) : const Color(0x0AFFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: accent ? const Color(0x80FF4D4F) : const Color(0x14FFFFFF)),
          boxShadow: accent
              ? const [BoxShadow(color: Color(0x59FF4D4F), blurRadius: 22)]
              : null,
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: accent ? 28 : 22),
        ),
      ),
    );
  }
}
