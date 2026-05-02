import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../router/router.dart';
import '../services/camera_service.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';
import 'take60_guided_record_screen.dart';

// ──────────────────────────────────────────────────────────────────────────────
// RECORD SCREEN — Page 5 Pixel-Perfect (PRD)
// ──────────────────────────────────────────────────────────────────────────────

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key, this.scene});

  final SceneModel? scene;

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen>
    with TickerProviderStateMixin {
  SceneModel? _scene;
  bool _cameraInitializing = true;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _scene = widget.scene;

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _initCamera());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final result =
        await ref.read(recordingProvider.notifier).initCamera(context);
    if (mounted) setState(() => _cameraInitializing = false);
    if (!mounted || result.isReady) {
      return;
    }

    if (result.needsSettings) {
      await _showPermissionsSettingsDialog(result.missingPermissions);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Caméra ou micro non disponibles — vérifier les permissions',
            style: GoogleFonts.dmSans(color: Colors.white),
          ),
          backgroundColor: _K.red,
          action: SnackBarAction(
            label: 'Réglages',
            textColor: Colors.white,
            onPressed: () {
              PermissionService().openSettings();
            },
          ),
        ),
      );
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
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Autorisation requise'),
          content: Text(
            'L’accès au $labels a été refusé de façon permanente. Ouvre les réglages système pour autoriser Take 30.',
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
        );
      },
    );
  }

  Future<void> _toggleRecord() async {
    final notifier = ref.read(recordingProvider.notifier);
    final recordingState = ref.read(recordingProvider);
    final currentScene = _resolveCurrentScene();

    if (!recordingState.isRecording) {
      HapticFeedback.heavyImpact();
      notifier.setScene(currentScene);
      await notifier.startRecording();
      _pulseCtrl.repeat(reverse: true);
      return;
    }

    _pulseCtrl.stop();
    _pulseCtrl.reset();
    HapticFeedback.mediumImpact();
    final path = await notifier.stopRecording();
    if (path != null && mounted) {
      context.go(
        AppRouter.preview,
        extra: <String, dynamic>{
          'videoPath': path,
          'scene': currentScene,
        },
      );
    }
  }

  SceneModel _resolveCurrentScene() {
    final availableScenes = ref.read(feedProvider).scenes;
    if (_scene != null) {
      return _scene!;
    }
    if (availableScenes.isNotEmpty) {
      return availableScenes.first;
    }
    final user = ref.read(authProvider).user;
    return SceneModel(
      id: 'draft-record',
      title: 'Nouvelle scène',
      category: 'Impro',
      thumbnailUrl: '',
      author: user ??
          const UserModel(
            id: 'anonymous',
            username: 'guest',
            displayName: 'Créateur',
            avatarUrl: '',
          ),
      createdAt: DateTime.now(),
      status: 'draft',
      tags: const ['take30'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Take60GuidedRecordScreen(initialScene: widget.scene);
  }

  // Legacy free-recording UI kept for reference; no longer wired.
  // ignore: unused_element
  Widget _legacyBuild(BuildContext context) {
    final recordingState = ref.watch(recordingProvider);
    final feedState = ref.watch(feedProvider);
    final cameraService = ref.watch(cameraServiceProvider);
    final elapsed = cameraService.elapsedSeconds;
    final remaining = CameraService.maxRecordingSeconds - elapsed;
    final isRecording =
        cameraService.isRecording || recordingState.isRecording;
    final currentScene = _scene ??
      (feedState.scenes.isNotEmpty ? feedState.scenes.first : _resolveCurrentScene());
    final clampedRemaining = remaining.clamp(
      0,
      CameraService.maxRecordingSeconds,
    );
    final timerMinutes = clampedRemaining ~/ 60;
    final timerSeconds = clampedRemaining % 60;
    final timerLabel =
        '${timerMinutes.toString().padLeft(2, '0')}:${timerSeconds.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: _surface(context),
      body: Stack(
        children: [
          // ── Full-screen camera ──
          Positioned.fill(
            child: _cameraInitializing
                ? const _CameraLoading()
                : cameraService.controller?.value.isInitialized == true
                    ? CameraPreview(cameraService.controller!)
                    : const _CameraFallback(),
          ),

          // ── Top vignette (theme-aware) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _topVignetteColors(context),
                ),
              ),
            ),
          ),

          // ── Bottom vignette (theme-aware) ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 280,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: _bottomVignetteColors(context),
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // ── UI overlay ──
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                        horizontal: AppThemeTokens.pageHorizontalPadding,
                        vertical: 8,
                      ),
                  child: Row(
                    children: [
                      _CircleButton(
                        icon: Icons.close_rounded,
                        onTap: () {
                          if (isRecording) {
                            ref
                                .read(recordingProvider.notifier)
                                .stopRecording();
                          }
                          context.go(AppRouter.home);
                        },
                      ),
                      const Spacer(),
                      // Timer pill
                      _TimerPill(
                        label: timerLabel,
                        isRecording: isRecording,
                      ),
                      const Spacer(),
                      _CircleButton(
                        icon: Icons.flip_camera_android_rounded,
                        onTap: isRecording
                            ? null
                            : () => ref
                                .read(recordingProvider.notifier)
                                .flipCamera(),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Scene title pill ──
                _ScenePill(
                  title: currentScene.title,
                  category: currentScene.category,
                  onTap: isRecording ? null : _showScenePicker,
                ),

                const SizedBox(height: 28),

                // ── Bottom controls row ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left: scenes
                      _SideControl(
                        icon: Icons.movie_filter_outlined,
                        label: 'Scènes',
                        onTap: isRecording ? null : _showScenePicker,
                      ),

                      // Center: record button
                      _RecordButton(
                        isRecording: isRecording,
                        pulseAnimation: _pulseAnim,
                        onTap: _cameraInitializing ? null : _toggleRecord,
                      ),

                      // Right: effects
                      _SideControl(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Effets',
                        onTap: isRecording ? null : _showEffectsSheet,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showScenePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ScenePickerSheet(
        currentSceneId: _resolveCurrentScene().id,
        onSelect: (scene) {
          setState(() => _scene = scene);
          ref.read(recordingProvider.notifier).setScene(scene);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEffectsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _ink(sheetContext).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              const Icon(
                Icons.auto_awesome_rounded,
                color: _K.yellow,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                'Effets (bientôt)',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _ink(sheetContext),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Filtres et effets vidéo arrivent dans une prochaine version.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: _ink(sheetContext).withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Timer Pill
// ──────────────────────────────────────────────────────────────────────────────

class _TimerPill extends StatelessWidget {
  const _TimerPill({required this.label, required this.isRecording});

  final String label;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isRecording
                ? _K.red.withValues(alpha: 0.18)
                : _glassBg(context, alpha: 0.78),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRecording
                  ? _K.red.withValues(alpha: 0.55)
                  : _ink(context).withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRecording) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _K.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _K.red.withValues(alpha: 0.60),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isRecording ? _K.red : _ink(context),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Scene Title Pill
// ──────────────────────────────────────────────────────────────────────────────

class _ScenePill extends StatelessWidget {
  const _ScenePill({
    required this.title,
    required this.category,
    this.onTap,
  });

  final String title;
  final String category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _glassBg(context, alpha: 0.82),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _ink(context).withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _K.yellow,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _ink(context).withValues(alpha: 0.60),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _ink(context).withValues(alpha: 0.45),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Record Button
// ──────────────────────────────────────────────────────────────────────────────

class _RecordButton extends StatelessWidget {
  const _RecordButton({
    required this.isRecording,
    required this.pulseAnimation,
    this.onTap,
  });

  final bool isRecording;
  final Animation<double> pulseAnimation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) {
          final scale = isRecording ? pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _glassBg(context, alpha: 0.55),
            border: Border.all(
              color: _ink(context).withValues(alpha: 0.25),
              width: 4,
            ),
            boxShadow: isRecording
                ? [
                    BoxShadow(
                      color: _K.red.withValues(alpha: 0.40),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: isRecording ? 28 : 56,
              height: isRecording ? 28 : 56,
              decoration: BoxDecoration(
                color: _K.red,
                borderRadius:
                    BorderRadius.circular(isRecording ? 8 : 999),
                boxShadow: [
                  BoxShadow(
                    color: _K.red.withValues(alpha: 0.50),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Side Control
// ──────────────────────────────────────────────────────────────────────────────

class _SideControl extends StatelessWidget {
  const _SideControl({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _glassBg(context, alpha: enabled ? 0.78 : 0.45),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _ink(context).withValues(alpha: 0.10),
                ),
              ),
              child: Icon(
                icon,
                color: _ink(context).withValues(alpha: enabled ? 0.88 : 0.30),
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _ink(context).withValues(alpha: enabled ? 0.78 : 0.30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Circle Button (top bar)
// ──────────────────────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _glassBg(context, alpha: 0.78),
              shape: BoxShape.circle,
              border: Border.all(
                color: _ink(context).withValues(alpha: 0.10),
              ),
            ),
            child: Icon(
              icon,
              color: onTap != null
                  ? _ink(context)
                  : _ink(context).withValues(alpha: 0.30),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Camera Loading
// ──────────────────────────────────────────────────────────────────────────────

class _CameraLoading extends StatelessWidget {
  const _CameraLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface(context),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _K.yellow,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Préparation caméra…',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: _ink(context).withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Camera Fallback
// ──────────────────────────────────────────────────────────────────────────────

class _CameraFallback extends StatelessWidget {
  const _CameraFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface(context),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              color: _ink(context).withValues(alpha: 0.30),
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              'Caméra non disponible',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: _ink(context).withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async => PermissionService().openSettings(),
              child: Text(
                'Autoriser dans Réglages',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _K.cyan,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Scene Picker Sheet
// ──────────────────────────────────────────────────────────────────────────────

class _ScenePickerSheet extends ConsumerWidget {
  const _ScenePickerSheet({this.currentSceneId, required this.onSelect});

  final String? currentSceneId;
  final void Function(SceneModel) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenes = ref.watch(feedProvider).scenes;
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: _ink(context).withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Choisir une scène',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _ink(context),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: scenes.isEmpty
              ? Center(
                  child: Text(
                    'Aucune scène disponible. Publie ou seed des scènes pour enregistrer sur un prompt existant.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: _ink(context).withValues(alpha: 0.62),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: scenes.length,
                  itemBuilder: (_, index) {
                    final scene = scenes[index];
                    final selected = currentSceneId == scene.id;
                    return GestureDetector(
                      onTap: () => onSelect(scene),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? _K.yellow.withValues(alpha: 0.14)
                              : _ink(context).withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? _K.yellow.withValues(alpha: 0.55)
                                : _ink(context).withValues(alpha: 0.08),
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
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: _ink(context).withValues(alpha: 0.08)),
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
                                      color: _ink(context),
                                    ),
                                  ),
                                  Text(
                                    scene.category,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: _ink(context).withValues(alpha: 0.55),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check_circle,
                                color: _K.yellow,
                                size: 18,
                              ),
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

// ──────────────────────────────────────────────────────────────────────────────
// Palette
// ──────────────────────────────────────────────────────────────────────────────

class _K {
  static const red = Color(0xFFFF4757);
  static const yellow = Color(0xFFFFB800);
  static const cyan = Color(0xFF00D4FF);
}

// Helpers thème clair / sombre pour la page record.
Color _ink(BuildContext context) => AppThemeTokens.primaryText(context);
Color _surface(BuildContext context) => AppThemeTokens.pageBackground(context);
Color _glassBg(BuildContext context, {double alpha = 0.78}) =>
    AppThemeTokens.isDark(context)
        ? Colors.black.withValues(alpha: alpha * 0.55)
        : Colors.white.withValues(alpha: alpha);
List<Color> _topVignetteColors(BuildContext context) =>
    AppThemeTokens.isDark(context)
        ? [
            Colors.black.withValues(alpha: 0.70),
            Colors.black.withValues(alpha: 0.0),
          ]
        : [
            Colors.white.withValues(alpha: 0.78),
            Colors.white.withValues(alpha: 0.0),
          ];
List<Color> _bottomVignetteColors(BuildContext context) =>
    AppThemeTokens.isDark(context)
        ? [
            Colors.black.withValues(alpha: 0.85),
            Colors.black.withValues(alpha: 0.50),
            Colors.black.withValues(alpha: 0.0),
          ]
        : [
            Colors.white.withValues(alpha: 0.92),
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.0),
          ];
