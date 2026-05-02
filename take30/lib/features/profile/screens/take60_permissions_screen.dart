import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../providers/providers.dart';
import '../../../services/permission_service.dart';
import '../../../theme/app_theme.dart';

class Take60PermissionsScreen extends ConsumerStatefulWidget {
  const Take60PermissionsScreen({super.key});

  @override
  ConsumerState<Take60PermissionsScreen> createState() =>
      _Take60PermissionsScreenState();
}

class _Take60PermissionsScreenState
    extends ConsumerState<Take60PermissionsScreen> {
  late Future<Map<AppPermission, PermissionStatus>> _statusesFuture;

  @override
  void initState() {
    super.initState();
    _statusesFuture = _loadStatuses();
  }

  Future<Map<AppPermission, PermissionStatus>> _loadStatuses() async {
    final service = ref.read(permissionProvider);
    final result = <AppPermission, PermissionStatus>{};
    for (final permission in AppPermission.values) {
      result[permission] = await service.status(permission);
    }
    return result;
  }

  Future<void> _request(AppPermission permission) async {
    await ref.read(permissionProvider).request(permission);
    if (!mounted) {
      return;
    }
    setState(() {
      _statusesFuture = _loadStatuses();
    });
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
          final statuses =
              snapshot.data ?? const <AppPermission, PermissionStatus>{};
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                'Verifiez les acces camera, micro, stockage et notifications sans quitter votre profil Take60.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppThemeTokens.secondaryText(context),
                ),
              ),
              const SizedBox(height: 18),
              for (final permission in AppPermission.values) ...[
                _PermissionTile(
                  permission: permission,
                  status: statuses[permission],
                  onRequest: () => _request(permission),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => ref.read(permissionProvider).openSettings(),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Ouvrir les reglages systeme'),
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
  });

  final AppPermission permission;
  final PermissionStatus? status;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final resolvedStatus = status;
    final granted = resolvedStatus?.isGranted ?? false;
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
                  granted ? 'Autorise' : 'Autorisation requise',
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
            onPressed: onRequest,
            child: Text(granted ? 'Verifier' : 'Autoriser'),
          ),
        ],
      ),
    );
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
    switch (permission) {
      case AppPermission.camera:
        return 'Camera';
      case AppPermission.microphone:
        return 'Microphone';
      case AppPermission.storage:
        return 'Stockage';
      case AppPermission.photos:
        return 'Photos';
      case AppPermission.notifications:
        return 'Notifications';
      case AppPermission.mediaLibrary:
        return 'Bibliotheque media';
    }
  }
}