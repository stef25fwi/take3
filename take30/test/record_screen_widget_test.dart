import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
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
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: '1:1234567890:web:testapp',
        messagingSenderId: '1234567890',
        projectId: 'take30-test',
        storageBucket: 'take30-test.appspot.com',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          home: Take60GuidedRecordScreen(
            initialScene: _scene(),
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
