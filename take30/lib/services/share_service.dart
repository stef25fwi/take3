import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';

class ShareService {
  ShareService._();

  static final ShareService _instance = ShareService._();
  static const String _defaultPublicBaseUrl = 'https://take30.web.app';

  factory ShareService() => _instance;

  String _publicBaseUrl() {
    if (!kIsWeb) {
      return _defaultPublicBaseUrl;
    }

    final base = Uri.base;
    final firstSegment = base.pathSegments.isEmpty ? '' : base.pathSegments.first;
    final pathPrefix = firstSegment == 'take3' ? '/take3' : '';
    return '${base.origin}$pathPrefix';
  }

  String _sceneUrl(String sceneId) => '${_publicBaseUrl()}/scene/$sceneId';
  String _profileUrl(String userId) => '${_publicBaseUrl()}/profile/$userId';
  String _challengeUrl() => '${_publicBaseUrl()}/challenge';

  Future<void> shareScene(SceneModel scene) async {
    final text = '''🎬 Regarde ma performance sur Take 30 !

"${scene.title}" — ${scene.category}
Par @${scene.author.username}

❤️ ${_formatCount(scene.likesCount)} likes · 👁 ${_formatCount(scene.viewsCount)} vues

👉 ${_sceneUrl(scene.id)}''';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: '${scene.title} sur Take 30',
      ),
    );
  }

  Future<void> shareProfile(UserModel user) async {
    final text = '''🌟 Découvre @${user.username} sur Take 30 !

${user.bio.isNotEmpty ? '"${user.bio}"' : 'Talent Take 30'}
🎬 ${user.scenesCount} scènes · ❤️ ${_formatCount(user.likesCount)} likes

👉 ${_profileUrl(user.id)}''';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: '@${user.username} sur Take 30',
      ),
    );
  }

  Future<void> shareDailyChallenge(DailyChallengeModel challenge) async {
    final text = '''🔥 Défi du Jour Take 30 !

Scène : "${challenge.sceneTitle}"
${challenge.quote}

👉 ${_challengeUrl()}''';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Défi du Jour Take 30',
      ),
    );
  }

  Future<void> shareAfterPublish({
    required String sceneTitle,
    required String sceneId,
  }) async {
    final text = '''🎭 Je viens de poster "$sceneTitle" sur Take 30 !

👉 ${_sceneUrl(sceneId)}''';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: sceneTitle,
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}