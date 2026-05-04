import 'package:flutter_test/flutter_test.dart';
import 'package:take30/models/models.dart';

void main() {
  group('BattleModel', () {
    test('parse storage status and exposes voting getters', () {
      final battle = BattleModel.fromMap({
        'id': 'b1',
        'status': 'voting_open',
        'challengerId': 'u1',
        'opponentId': 'u2',
        'challengerName': 'Alex',
        'opponentName': 'Clara',
        'createdAt': DateTime(2026, 5, 4),
        'challengerVideoUrl': 'https://example.com/a.mp4',
        'opponentVideoUrl': 'https://example.com/b.mp4',
        'totalVotes': 10,
        'votesChallenger': 6,
        'votesOpponent': 4,
      });

      expect(battle.status, BattleStatus.votingOpen);
      expect(battle.isVotingOpen, isTrue);
      expect(battle.hasBothVideos, isTrue);
      expect(battle.canVote('spectator'), isTrue);
      expect(battle.canVote('u1'), isFalse);
      expect(battle.opponentOf('u1'), 'u2');
    });

    test('close result threshold uses five percent', () {
      final battle = BattleModel.fromMap({
        'id': 'b2',
        'status': 'ended',
        'challengerId': 'u1',
        'opponentId': 'u2',
        'challengerName': 'Alex',
        'opponentName': 'Clara',
        'createdAt': DateTime(2026, 5, 4),
        'totalVotes': 100,
        'votesChallenger': 52,
        'votesOpponent': 48,
      });

      expect(battle.isCloseResult, isTrue);
    });
  });
}
