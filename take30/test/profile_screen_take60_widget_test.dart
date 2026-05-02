import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:take30/features/profile/models/profile_activity_history.dart';
import 'package:take30/features/profile/models/take60_profile_stats.dart';
import 'package:take30/features/profile/models/take60_user_profile.dart';
import 'package:take30/features/profile/providers/take60_profile_providers.dart';
import 'package:take30/models/models.dart';
import 'package:take30/providers/providers.dart';
import 'package:take30/screens/profile_screen.dart';
import 'package:take30/services/api_service.dart';
import 'package:take30/services/auth_service.dart';
import 'package:take30/services/haptics_service.dart';
import 'package:take30/services/share_service.dart';

void main() {
  testWidgets('ProfileScreen affiche le hub Take60 pour le profil courant',
      (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    const user = UserModel(
      id: 'admin_1',
      username: 'take60_admin',
      displayName: 'Admin Take60',
      avatarUrl: 'https://example.com/avatar.png',
      email: 'admin@take60.local',
      bio: 'Direction artistique Take60',
      isVerified: true,
      scenesCount: 12,
      followersCount: 1800,
      likesCount: 4200,
      totalViews: 55000,
      approvalRate: 0.91,
      sharesCount: 86,
      isAdmin: true,
    );
    final scene = SceneModel(
      id: 'scene_1',
      title: 'Take studio',
      category: 'Drama',
      thumbnailUrl: 'https://example.com/thumb.png',
      sceneType: 'Monologue',
      description: 'Scene premium',
      dialogueText: 'Bonjour',
      difficulty: 'Intermediaire',
      durationSeconds: 45,
      editingMode: 'dialogue_auto_cut',
      ambiance: 'Cine',
      characterToPlay: 'Lead',
      context: 'Studio',
      emotionalObjective: 'Convaincre',
      directorInstructions: 'Fix camera',
      likesCount: 240,
      commentsCount: 14,
      sharesCount: 8,
      viewsCount: 2000,
      author: user,
      createdAt: DateTime(2026, 5, 2),
    );
    final take60Profile = Take60UserProfile.fromUserModel(
      user,
      regionName: 'Ile-de-France',
      countryName: 'France',
      castingModeEnabled: true,
      autoAcceptInvites: true,
      notificationsEnabled: true,
      accountVisibility: Take60AccountVisibility.publicProfile,
      videoVisibility: Take60VideoVisibility.publicVideos,
      darkModeEnabled: true,
    );
    final take60Stats = Take60ProfileStats.fromUserModel(
      user,
      scenesCount: 1,
      regionalRank: 2,
      countryRank: 5,
      globalRank: 11,
    );
    final viewedHistory = [
      ProfileViewedSceneHistoryItem.fromScene(
        scene,
        viewedAt: DateTime(2026, 5, 2, 10, 30),
      ),
    ];
    final duelHistory = [
      ProfileDuelVoteHistoryItem(
        duelId: 'duel_1',
        selectedSceneTitle: 'Take studio',
        otherSceneTitle: 'Face camera',
        selectedThumbnailUrl: 'https://example.com/thumb_a.png',
        otherThumbnailUrl: 'https://example.com/thumb_b.png',
        selectedAuthorName: 'Admin Take60',
        otherAuthorName: 'Lina Take60',
        choice: 0,
        votedAt: DateTime(2026, 5, 2, 11, 15),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith((ref) => AuthNotifier(_FakeAuthService(user))),
          currentTake60UserProfileProvider.overrideWith(
            (ref) async => take60Profile,
          ),
          currentTake60ProfileStatsProvider.overrideWith(
            (ref) => take60Stats,
          ),
          currentViewedSceneHistoryProvider.overrideWith(
            (ref) async => viewedHistory,
          ),
          currentDuelVoteHistoryProvider.overrideWith(
            (ref) async => duelHistory,
          ),
          profileProvider(user.id).overrideWith(
            (ref) => ProfileNotifier(
              _FakeApiService(user, [scene]),
              HapticsService(),
              ShareService(),
              DemoPublishedScenesStore(),
              DemoSceneInteractionsStore(),
              user.id,
            ),
          ),
        ],
        child: const MaterialApp(
          home: ProfileScreen(userId: 'admin_1'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Profil & activite'),
      300,
    );
    await tester.pumpAndSettle();

    expect(find.text('Profil & activite'), findsOneWidget);
    expect(find.text('Historique recent'), findsOneWidget);
    expect(find.text('Mode casting'), findsWidgets);
    expect(find.text('Classements Take60'), findsOneWidget);
    expect(find.text('Take studio'), findsWidgets);
    expect(find.text('Take studio vs Face camera'), findsOneWidget);
    expect(find.text('Video vue'), findsOneWidget);
    expect(find.text('Duel vote'), findsOneWidget);
  });
}

class _FakeAuthService extends AuthServiceBase {
  _FakeAuthService(this._user);

  final UserModel _user;

  @override
  UserModel? get currentUser => _user;

  @override
  bool get isAuthenticated => true;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> checkPersistedAuth() async {}

  @override
  Future<AuthResult> loginDemo() async => const AuthResult.failure('unused');

  @override
  Future<AuthResult> loginWithApple() async =>
      const AuthResult.failure('unused');

  @override
  Future<AuthResult> loginWithGoogle() async =>
      const AuthResult.failure('unused');

  @override
  Future<AuthResult> loginWithIdentifier({
    required String identifier,
    required String password,
  }) async => const AuthResult.failure('unused');

  @override
  Future<void> logout() async {}

  @override
  Future<AuthResult> registerWithEmail({
    required String username,
    required String email,
    required String password,
  }) async => const AuthResult.failure('unused');
}

class _FakeApiService implements ApiService {
  _FakeApiService(this._user, this._scenes);

  final UserModel _user;
  final List<SceneModel> _scenes;

  @override
  UserModel? get currentUser => _user;

  @override
  Future<UserModel?> getProfile(String userId) async => _user;

  @override
  Future<List<SceneModel>> getUserScenes(String userId) async => _scenes;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}