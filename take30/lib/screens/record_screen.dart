import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../router/router.dart';
import '../services/mock_data.dart';
import '../services/camera_service.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key, this.scene});

  final SceneModel? scene;

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  SceneModel? _scene;
  bool _cameraInitializing = true;

  @override
  void initState() {
    super.initState();
    _scene = widget.scene ?? MockData.scenes.first;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCamera());
  }

  Future<void> _initCamera() async {
    final ready = await ref.read(recordingProvider.notifier).initCamera(context);
    if (mounted) {
      setState(() => _cameraInitializing = false);
    }
    if (!ready && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caméra non disponible — vérifier les permissions'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> _toggleRecord() async {
    final notifier = ref.read(recordingProvider.notifier);
    final recordingState = ref.read(recordingProvider);

    if (!recordingState.isRecording) {
      await notifier.startRecording();
      return;
    }

    final path = await notifier.stopRecording();
    if (path != null && mounted) {
      context.go(
        AppRouter.preview,
        extra: <String, dynamic>{
          'videoPath': path,
          'scene': _scene,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingProvider);
    final cameraService = ref.watch(cameraServiceProvider);
    final elapsed = cameraService.elapsedSeconds;
    final remaining = CameraService.maxRecordingSeconds - elapsed;
    final isRecording = cameraService.isRecording || recordingState.isRecording;
    final currentScene = _scene ?? MockData.scenes.first;
    final sceneIndex = MockData.scenes.indexWhere((item) => item.id == currentScene.id);
    final sceneStep = sceneIndex >= 0 ? sceneIndex + 1 : 1;
    final progress = sceneStep / MockData.scenes.length;
    final timerLabel = '00:${remaining.clamp(0, 59).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: RecordTheme.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: _cameraInitializing
                ? const _CameraLoadingPlaceholder()
                : cameraService.controller?.value.isInitialized == true
                    ? CameraPreview(cameraService.controller!)
                    : const _CameraFallback(),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.55),
                    const Color(0xF2081020),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      _HeaderButton(
                        icon: Icons.close,
                        onTap: () {
                          if (isRecording) {
                            ref.read(recordingProvider.notifier).stopRecording();
                          }
                          context.go(AppRouter.home);
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Enregistrer',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      _HeaderButton(
                        icon: Icons.flip_camera_android,
                        onTap: isRecording
                            ? null
                            : () => ref.read(recordingProvider.notifier).flipCamera(),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: isRecording ? null : _showScenePicker,
                    child: Container(
                      width: 182,
                      height: 182,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isRecording ? AppColors.red : Colors.white24,
                          width: 4,
                        ),
                        boxShadow: isRecording
                            ? [
                                BoxShadow(
                                  color: AppColors.red.withValues(alpha: 0.32),
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            timerLabel,
                            style: GoogleFonts.dmSans(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isRecording ? 'En cours' : 'Pret',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoundControl(
                        icon: Icons.movie_filter_outlined,
                        onTap: isRecording ? null : _showScenePicker,
                      ),
                      const SizedBox(width: 18),
                      GestureDetector(
                        onTap: _cameraInitializing ? null : _toggleRecord,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                            color: AppColors.red.withValues(alpha: 0.18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.red.withValues(alpha: 0.35),
                                blurRadius: 22,
                              ),
                            ],
                          ),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isRecording ? 24 : 46,
                              height: isRecording ? 24 : 46,
                              decoration: BoxDecoration(
                                color: AppColors.red,
                                borderRadius: BorderRadius.circular(isRecording ? 6 : 999),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      _RoundControl(
                        icon: isRecording ? Icons.stop_rounded : Icons.flip_camera_android,
                        onTap: isRecording
                            ? _toggleRecord
                            : () => ref.read(recordingProvider.notifier).flipCamera(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  GestureDetector(
                    onTap: isRecording ? null : _showScenePicker,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Scene $sceneStep / ${MockData.scenes.length}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isRecording
                                      ? AppColors.red.withValues(alpha: 0.18)
                                      : AppColors.yellow.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isRecording ? '● LIVE' : currentScene.category,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isRecording ? AppColors.red : AppColors.yellow,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.surfaceElevated,
                              valueColor: const AlwaysStoppedAnimation(AppColors.red),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentScene.title,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Progression globale du tournage.',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showScenePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.dark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ScenePickerSheet(
        currentSceneId: _scene?.id,
        onSelect: (scene) {
          setState(() => _scene = scene);
          ref.read(recordingProvider.notifier).setScene(scene);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _CameraLoadingPlaceholder extends StatelessWidget {
  const _CameraLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.yellow),
      ),
    );
  }
}

class _CameraFallback extends StatelessWidget {
  const _CameraFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: AppColors.grey, size: 56),
            const SizedBox(height: 12),
            Text(
              'Caméra non disponible',
              style: GoogleFonts.dmSans(color: AppColors.grey, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async => PermissionService().openSettings(),
              child: Text(
                'Autoriser dans Réglages',
                style: GoogleFonts.dmSans(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: RecordTheme.overlayBtnBg,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: onTap != null ? RecordTheme.overlayBtnIcon : Colors.white30,
          size: 20,
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: onTap != null ? RecordTheme.ctrlBtnBg : const Color(0x0FFFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(
          icon,
          color: onTap != null ? RecordTheme.ctrlBtnIcon : Colors.white30,
          size: 24,
        ),
      ),
    );
  }
}

class _ScenePickerSheet extends StatelessWidget {
  const _ScenePickerSheet({this.currentSceneId, required this.onSelect});

  final String? currentSceneId;
  final void Function(SceneModel) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Choisir une scène',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: MockData.scenes.length,
            itemBuilder: (_, index) {
              final scene = MockData.scenes[index];
              final selected = currentSceneId == scene.id;
              return GestureDetector(
                onTap: () => onSelect(scene),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.yellow.withValues(alpha: 0.1)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.yellow : AppColors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 58,
                          height: 44,
                          child: Image.network(
                            scene.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: AppColors.surface),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scene.title,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                            Text(
                              scene.category,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle, color: AppColors.yellow, size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
