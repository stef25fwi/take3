import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../providers/providers.dart';
import '../../../services/permission_service.dart';
import '../../../theme/app_theme.dart';

class Take60PermissionsScreen extends ConsumerStatefulWidget {
  const Take60PermissionsScreen({
    super.key,
    this.loadStatusesOverride,
    this.requestPermissionOverride,
    this.openSettingsOverride,
  });

  final Future<Map<AppPermission, PermissionStatus>> Function()?
      loadStatusesOverride;
  final Future<PermissionStatus> Function(AppPermission permission)?
      requestPermissionOverride;
  final Future<bool> Function()? openSettingsOverride;

  @override
  ConsumerState<Take60PermissionsScreen> createState() =>
      _Take60PermissionsScreenState();
}

class _Take60PermissionsScreenState
    extends ConsumerState<Take60PermissionsScreen>
    with WidgetsBindingObserver {
  late Future<Map<AppPermission, PermissionStatus>> _statusesFuture;
  var _openingSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _statusesFuture = _refreshStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {
        _statusesFuture = _refreshStatuses();
      });
    }
  }

  Future<Map<AppPermission, PermissionStatus>> _loadStatuses() async {
    if (widget.loadStatusesOverride != null) {
      return widget.loadStatusesOverride!.call();
    }
    final service = ref.read(permissionProvider);
    final result = <AppPermission, PermissionStatus>{};
    for (final permission in AppPermission.values) {
      result[permission] = await service.status(permission);
    }
    return result;
  }

  Future<Map<AppPermission, PermissionStatus>> _refreshStatuses() {
    return _loadStatuses();
  }

  Future<void> _request(AppPermission permission) async {
    final status = widget.requestPermissionOverride != null
        ? await widget.requestPermissionOverride!(permission)
        : await ref.read(permissionProvider).request(permission);
    if (!mounted) {
      return;
    }
    final message = _statusMessage(permission, status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() {
      _statusesFuture = _refreshStatuses();
    });
  }

  Future<void> _openSystemSettings() async {
    setState(() => _openingSettings = true);
    final opened = widget.openSettingsOverride != null
        ? await widget.openSettingsOverride!.call()
        : await ref.read(permissionProvider).openSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _openingSettings = false;
      _statusesFuture = _refreshStatuses();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? 'Réglages système ouverts. Reviens ici pour vérifier les accès.'
              : 'Impossible d’ouvrir les réglages système depuis cet appareil.',
        ),
      ),
    );
  }

  String _statusMessage(AppPermission permission, PermissionStatus status) {
    final title = _permissionTitle(permission).toLowerCase();
    if (status.isGranted) {
      return 'Accès $title autorisé.';
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return 'Accès $title bloqué. Ouvre les réglages système pour l’activer.';
    }
    if (status.isLimited) {
      return 'Accès $title partiel. Ajuste-le dans les réglages si nécessaire.';
    }
    return 'Accès $title refusé.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeTokens.pageBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppThemeTokens.primaryText(context),
        elevation: 0,
        title: Text(
          'Permissions appareil',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<Map<AppPermission, PermissionStatus>>(
        future: _statusesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _PermissionScreenLoader();
          }

          if (snapshot.hasError) {
            return _PermissionScreenMessage(
              icon: Icons.error_outline_rounded,
              title: 'Impossible de verifier les permissions',
              message:
                  'Take60 n’a pas reussi a lire les autorisations de cet appareil. Reessaie ou ouvre les reglages systeme.',
              primaryActionLabel: 'Reessayer',
              onPrimaryAction: () {
                setState(() {
                  _statusesFuture = _refreshStatuses();
                });
              },
              secondaryActionLabel: 'Ouvrir les reglages systeme',
              onSecondaryAction: _openingSettings ? null : _openSystemSettings,
            );
          }

          final statuses =
              snapshot.data ?? const <AppPermission, PermissionStatus>{};
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _PermissionIntroCard(
                blockedCount: statuses.values
                    .where(
                      (status) =>
                          status.isPermanentlyDenied || status.isRestricted,
                    )
                    .length,
              ),
              const SizedBox(height: 18),
              for (final permission in AppPermission.values) ...[
                _PermissionTile(
                  permission: permission,
                  status: statuses[permission],
                  onRequest: () => _request(permission),
                  onOpenSettings: _openSystemSettings,
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _openingSettings ? null : _openSystemSettings,
                icon: _openingSettings
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.open_in_new_rounded),
                label: const Text('Ouvrir les réglages système'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.permission,
    required this.status,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final AppPermission permission;
  final PermissionStatus? status;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final resolvedStatus = status;
    final granted = resolvedStatus?.isGranted ?? false;
    final blocked = resolvedStatus?.isPermanentlyDenied == true ||
      resolvedStatus?.isRestricted == true;
    final limited = resolvedStatus?.isLimited == true;
    final statusLabel = _statusLabel(resolvedStatus);
    final actionLabel = granted
      ? 'Vérifier'
      : blocked
        ? 'Ouvrir'
        : limited
          ? 'Ajuster'
          : 'Autoriser';
    final action = blocked ? onOpenSettings : onRequest;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemeTokens.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppThemeTokens.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconFor(permission), color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleFor(permission),
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppThemeTokens.primaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppThemeTokens.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: action,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  String _statusLabel(PermissionStatus? status) {
    if (status == null) {
      return 'Vérification en cours';
    }
    if (status.isGranted) {
      return 'Autorisé';
    }
    if (status.isLimited) {
      return 'Accès partiel';
    }
    if (status.isPermanentlyDenied) {
      return 'Bloqué dans les réglages';
    }
    if (status.isRestricted) {
      return 'Restreint par le système';
    }
    if (status.isDenied) {
      return 'Autorisation requise';
    }
    return 'Statut inconnu';
  }

  IconData _iconFor(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return Icons.videocam_rounded;
      case AppPermission.microphone:
        return Icons.mic_rounded;
      case AppPermission.storage:
        return Icons.sd_storage_rounded;
      case AppPermission.photos:
        return Icons.photo_library_rounded;
      case AppPermission.notifications:
        return Icons.notifications_active_rounded;
      case AppPermission.mediaLibrary:
        return Icons.perm_media_rounded;
    }
  }

  String _titleFor(AppPermission permission) {
    return _permissionTitle(permission);
  }
}

class _PermissionIntroCard extends StatelessWidget {
  const _PermissionIntroCard({required this.blockedCount});

  final int blockedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemeTokens.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppThemeTokens.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permissions appareil',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppThemeTokens.primaryText(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            blockedCount > 0
                ? 'Certaines autorisations sont bloquees. Ouvre les reglages systeme pour redonner acces a la camera, au micro ou aux notifications.'
                : 'Verifie les acces camera, micro, stockage et notifications sans quitter ton profil Take60.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppThemeTokens.secondaryText(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'La camera et le micro sont requis pour enregistrer. Les autres autorisations servent a importer, partager et recevoir les alertes.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppThemeTokens.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionScreenLoader extends StatelessWidget {
  const _PermissionScreenLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: 28,
        child: CircularProgressIndicator(strokeWidth: 2.4),
      ),
    );
  }
}

class _PermissionScreenMessage extends StatelessWidget {
  const _PermissionScreenMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppThemeTokens.surface(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppThemeTokens.border(context)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28, color: AppThemeTokens.primaryText(context)),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppThemeTokens.primaryText(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppThemeTokens.secondaryText(context),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onPrimaryAction,
                  child: Text(primaryActionLabel),
                ),
                if (secondaryActionLabel != null && onSecondaryAction != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: onSecondaryAction,
                    child: Text(secondaryActionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _permissionTitle(AppPermission permission) {
  switch (permission) {
    case AppPermission.camera:
      return 'Caméra';
    case AppPermission.microphone:
      return 'Microphone';
    case AppPermission.storage:
      return 'Stockage';
    case AppPermission.photos:
      return 'Photos';
    case AppPermission.notifications:
      return 'Notifications';
    case AppPermission.mediaLibrary:
      return 'Bibliothèque média';
  }
}