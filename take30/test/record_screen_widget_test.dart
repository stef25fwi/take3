import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:take30/models/models.dart';
import 'package:take30/providers/providers.dart';
import 'package:take30/services/permission_service.dart';
import 'package:take30/screens/take60_guided_record_screen.dart';

void main() {
  testWidgets('Record affiche un état permission refusée sans crash', (
    tester,
  ) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          home: Take60GuidedRecordScreen(
            initialScene: _scene(),
            skipInitialLibraryLoad: true,
            skipPersistenceForTesting: true,
            onInitCameraOverride: (_) async => const CameraInitResult.denied(
              needsSettings: false,
              missingPermissions: [
                AppPermission.camera,
                AppPermission.microphone,
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Plan de tournage Take60'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Démarrer la scène'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Démarrer la scène'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('take60_permission_denied_state')), findsOneWidget);
    expect(find.text('Caméra et micro requis'), findsOneWidget);
    expect(find.textContaining('a été refusé'), findsOneWidget);
    expect(find.byKey(const Key('take60_permission_retry_button')), findsOneWidget);
  });
}

SceneModel _scene() {
  return SceneModel(
    id: 'scene_test',
    title: 'Contrôle de routine',
    category: 'Policier',
    thumbnailUrl: '',
    sceneType: 'Dialogue',
    difficulty: 'Intermédiaire',
    characterToPlay: 'Suspect',
    emotionalObjective: 'Garder le contrôle',
    mainObstacle: 'La pression de l’interrogatoire',
    dominantEmotion: 'Tension',
    context: 'Tu fais face à un interrogatoire bref et tendu.',
    dialogueText: 'Je n’ai rien à cacher.',
    directorInstructions: 'Regarde caméra et reste nerveux.',
    videoUrl: '',
    author: const UserModel(
      id: 'admin_1',
      username: 'admin',
      displayName: 'Admin',
      avatarUrl: '',
    ),
    createdAt: DateTime(2026, 5, 3),
    adminWorkflow: true,
    markers: const [
      Take60SceneMarker(
        id: 'user_1',
        order: 1,
        type: GuidedMarkerType.userPlan,
        startSeconds: 0,
        endSeconds: 8,
        durationSeconds: 8,
        source: 'user_video',
        character: 'Suspect',
        dialogue: 'Je n’ai rien à cacher.',
        cameraPlan: 'close_up',
        label: 'Réplique joueur',
      ),
    ],
  );
}
