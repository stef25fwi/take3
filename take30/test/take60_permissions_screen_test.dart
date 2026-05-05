import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:take30/features/profile/screens/take60_permissions_screen.dart';
import 'package:take30/services/permission_service.dart';

void main() {
  testWidgets('Permissions appareil affiche le contenu et ouvre les reglages pour un statut bloque', (
    tester,
  ) async {
    var settingsOpened = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Take60PermissionsScreen(
          loadStatusesOverride: () async => {
            AppPermission.camera: PermissionStatus.permanentlyDenied,
            AppPermission.microphone: PermissionStatus.granted,
            AppPermission.storage: PermissionStatus.denied,
            AppPermission.photos: PermissionStatus.denied,
            AppPermission.notifications: PermissionStatus.granted,
            AppPermission.mediaLibrary: PermissionStatus.granted,
          },
          requestPermissionOverride: (permission) async => PermissionStatus.granted,
          openSettingsOverride: () async {
            settingsOpened += 1;
            return true;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Permissions appareil'), findsAtLeastNWidgets(1));
    expect(find.textContaining('camera et le micro sont requis'), findsOneWidget);
    expect(find.text('Caméra'), findsOneWidget);
    expect(find.text('Bloqué dans les réglages'), findsOneWidget);
    expect(find.text('Microphone'), findsOneWidget);
    expect(find.text('Autorisé'), findsAtLeastNWidgets(1));

    await tester.tap(find.widgetWithText(TextButton, 'Ouvrir').first);
    await tester.pump();

    expect(settingsOpened, 1);
  });

  testWidgets('Permissions appareil affiche un etat erreur explicite puis permet de reessayer', (
    tester,
  ) async {
    var attempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Take60PermissionsScreen(
          loadStatusesOverride: () async {
            attempts += 1;
            if (attempts == 1) {
              throw Exception('permission failure');
            }
            return {
              AppPermission.camera: PermissionStatus.granted,
              AppPermission.microphone: PermissionStatus.granted,
              AppPermission.storage: PermissionStatus.granted,
              AppPermission.photos: PermissionStatus.granted,
              AppPermission.notifications: PermissionStatus.granted,
              AppPermission.mediaLibrary: PermissionStatus.granted,
            };
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Impossible de verifier les permissions'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Reessayer'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Caméra'), findsOneWidget);
    expect(find.text('Autorisé'), findsAtLeastNWidgets(1));
  });
}