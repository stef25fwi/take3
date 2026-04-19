import 'package:share_plus/share_plus.dart';

import '../models/models.dart';

class ShareService {
  ShareService._();

  static final ShareService _instance = ShareService._();

  factory ShareService() => _instance;

  Future<void> shareScene(SceneModel scene) async {
    final text = '''🎬 Regarde ma performance sur Take 60 !

"${scene.title}" — ${scene.category}
Par @${scene.author.username}

❤️ ${_formatCount(scene.likesCount)} likes · 👁 ${_formatCount(scene.viewsCount)} vues

👉 https://take30.app/scene/${scene.id}''';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: '${scene.title} sur Take 60',
      ),
    );
  }

  Future<void> shareProfile(UserModel user) async {
    final text = '''🌟 Découvre @${user.username} sur Take 60 !

${user.bio.isNotEmpty ? '"${user.bio}"' : 'Talent Take 60'}
🎬 ${user.scenesCount} scènes · ❤️ ${_formatCount(user.likesCount)} likes

👉 https://take30.app/profile/${user.id}''';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: '@${user.username} sur Take 60',
      ),
    );
  }

  Future<void> shareDailyChallenge(DailyChallengeModel challenge) async {
    final text = '''🔥 Défi du Jour Take 60 !

Scène : "${challenge.sceneTitle}"
${challenge.quote}

👉 https://take30.app/challenge''';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Défi du Jour Take 60',
      ),
    );
  }

  Future<void> shareAfterPublish({
    required String sceneTitle,
    required String sceneId,
  }) async {
    final text = '''🎭 Je viens de poster "$sceneTitle" sur Take 60 !

👉 https://take30.app/scene/$sceneId''';

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