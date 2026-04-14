import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermission {
  camera,
  microphone,
  storage,
  photos,
  notifications,
  mediaLibrary,
}

class PermissionService {
  PermissionService._();

  static final PermissionService _instance = PermissionService._();

  factory PermissionService() => _instance;

  Future<bool> isGranted(AppPermission permission) async {
    final status = await _permissionFor(permission).status;
    return status.isGranted;
  }

  Future<PermissionStatus> request(AppPermission permission) {
    return _permissionFor(permission).request();
  }

  Future<Map<AppPermission, bool>> requestMultiple(List<AppPermission> permissions) async {
    final mapped = permissions.map(_permissionFor).toList();
    final statuses = await mapped.request();

    final result = <AppPermission, bool>{};
    for (var index = 0; index < permissions.length; index++) {
      result[permissions[index]] = statuses[mapped[index]]?.isGranted ?? false;
    }
    return result;
  }

  Future<bool> requestCameraAndMic() async {
    final result = await requestMultiple([
      AppPermission.camera,
      AppPermission.microphone,
    ]);
    return result.values.every((granted) => granted);
  }

  Future<bool> requestWithExplanation(
    BuildContext context,
    AppPermission permission, {
    required String title,
    required String message,
  }) async {
    if (await isGranted(permission)) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Pas maintenant'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Autoriser'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldRequest) {
      return false;
    }

    final status = await request(permission);
    return status.isGranted;
  }

  Future<void> openSettings() => openAppSettings();

  Permission _permissionFor(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return Permission.camera;
      case AppPermission.microphone:
        return Permission.microphone;
      case AppPermission.storage:
        return Permission.storage;
      case AppPermission.photos:
        return Permission.photos;
      case AppPermission.notifications:
        return Permission.notification;
      case AppPermission.mediaLibrary:
        return Permission.mediaLibrary;
    }
  }
}