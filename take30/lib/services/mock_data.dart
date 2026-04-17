import '../models/models.dart';
import '../utils/assets.dart';

final _users = <UserModel>[
  const UserModel(
    id: 'u1',
    username: 'LunaAct',
    displayName: 'LunaAct',
    avatarUrl: Take30Assets.avatarIaFemaleLead,
    bio: 'Actrice / Créatrice • Top 10 semaine',
    isVerified: true,
    scenesCount: 47,
    followersCount: 12400,
    likesCount: 248000,
    totalViews: 248300,
    approvalRate: 92,
    sharesCount: 12400,
  ),
  const UserModel(
    id: 'u2',
    username: 'Max_Act',
    displayName: 'Max_Act',
    avatarUrl: Take30Assets.avatarIaMaleLead,
    followersCount: 10800,
  ),
  const UserModel(
    id: 'u3',
    username: 'NeoPlayer',
    displayName: 'NeoPlayer',
    avatarUrl: Take30Assets.avatarIaMaleLead,
    followersCount: 8900,
  ),
  const UserModel(
    id: 'u4',
    username: 'ClaraScene',
    displayName: 'ClaraScene',
    avatarUrl: Take30Assets.avatarIaFemaleAlt,
    isVerified: true,
    followersCount: 8100,
  ),
  const UserModel(
    id: 'u5',
    username: 'TheoDrama',
    displayName: 'TheoDrama',
    avatarUrl: Take30Assets.avatarIaMaleLead,
    followersCount: 7500,
  ),
  const UserModel(
    id: 'u6',
    username: 'ActQueen',
    displayName: 'ActQueen',
    avatarUrl: Take30Assets.avatarIaFemaleAlt,
    isVerified: true,
    followersCount: 6900,
  ),
  const UserModel(
    id: 'u7',
    username: 'VictorPlay',
    displayName: 'VictorPlay',
    avatarUrl: Take30Assets.avatarIaMaleLead,
    followersCount: 6100,
  ),
];

final _scenes = <SceneModel>[
  SceneModel(
    id: 's1',
    title: 'Rupture au téléphone',
    category: 'Drame',
    thumbnailUrl: 'https://images.unsplash.com/photo-1614680376739-414d95ff43df?w=400',
    durationSeconds: 95,
    likesCount: 24300,
    commentsCount: 452,
    sharesCount: 1200,
    viewsCount: 89400,
    author: _users[0],
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    tags: ['drame', 'émotion', 'rupture'],
  ),
  SceneModel(
    id: 's2',
    title: 'Interrogatoire tendu',
    category: 'Thriller',
    thumbnailUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
    durationSeconds: 75,
    likesCount: 18700,
    commentsCount: 312,
    sharesCount: 890,
    viewsCount: 67200,
    author: _users[1],
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  SceneModel(
    id: 's3',
    title: 'Déclaration d\'amour',
    category: 'Romance',
    thumbnailUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400',
    durationSeconds: 85,
    likesCount: 31200,
    commentsCount: 678,
    sharesCount: 2100,
    viewsCount: 112000,
    author: _users[2],
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
  ),
  SceneModel(
    id: 's4',
    title: 'Annonce d\'une mauvaise nouvelle',
    category: 'Drame',
    thumbnailUrl: 'https://images.unsplash.com/photo-1542513217-0b0eeea7f7bc?w=400',
    durationSeconds: 90,
    likesCount: 15600,
    commentsCount: 234,
    sharesCount: 780,
    viewsCount: 54800,
    author: _users[3],
    createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    tags: ['drame', 'annonce', 'solo'],
  ),
  SceneModel(
    id: 's5',
    title: 'Confrontation familiale',
    category: 'Drame',
    thumbnailUrl: 'https://images.unsplash.com/photo-1504593811423-6dd665756598?w=400',
    durationSeconds: 88,
    likesCount: 22100,
    commentsCount: 445,
    sharesCount: 1560,
    viewsCount: 78300,
    author: _users[4],
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  SceneModel(
    id: 's6',
    title: 'Le Monologue du Héros',
    category: 'Action',
    thumbnailUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400',
    durationSeconds: 72,
    likesCount: 19800,
    commentsCount: 389,
    sharesCount: 1230,
    viewsCount: 65700,
    author: _users[5],
    createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
  ),
];

class MockData {
  static final users = _users;

  static const categories = <CategoryModel>[
    CategoryModel(id: 'c1', name: 'Drame', emoji: '🎭', scenesCount: 1240),
    CategoryModel(id: 'c2', name: 'Comédie', emoji: '😂', scenesCount: 890),
    CategoryModel(id: 'c3', name: 'Action', emoji: '💥', scenesCount: 654),
    CategoryModel(id: 'c4', name: 'Romance', emoji: '❤️', scenesCount: 780),
    CategoryModel(id: 'c5', name: 'Thriller', emoji: '😱', scenesCount: 432),
  ];

  static final scenes = _scenes;

  static const badges = <BadgeModel>[
    BadgeModel(
      id: 'b1',
      name: 'Révélation du jour',
      emoji: '⭐',
      description: 'Meilleure performance du jour',
      type: BadgeType.gold,
    ),
    BadgeModel(
      id: 'b2',
      name: 'Top 10',
      emoji: '🏆',
      description: 'Dans le Top 10 de la semaine',
      type: BadgeType.gold,
    ),
    BadgeModel(
      id: 'b3',
      name: 'Meilleure Émotion',
      emoji: '🎭',
      description: 'Performance la plus émotionnelle',
      type: BadgeType.silver,
    ),
    BadgeModel(
      id: 'b4',
      name: 'Scène la plus jouée',
      emoji: '🔥',
      description: 'Ta scène a été la plus rejouée',
      type: BadgeType.bronze,
    ),
  ];

  static final leaderboard = <LeaderboardEntry>[
    LeaderboardEntry(rank: 1, user: _users[0], score: 245200, scoreLabel: '245.2K ❤️'),
    LeaderboardEntry(rank: 2, user: _users[1], score: 210500, scoreLabel: '210.5K ❤️'),
    LeaderboardEntry(rank: 3, user: _users[2], score: 188300, scoreLabel: '188.3K ❤️'),
    LeaderboardEntry(rank: 4, user: _users[3], score: 176400, scoreLabel: '176.4K ❤️'),
    LeaderboardEntry(rank: 5, user: _users[4], score: 150200, scoreLabel: '150.2K ❤️'),
    LeaderboardEntry(rank: 6, user: _users[5], score: 142800, scoreLabel: '142.8K ❤️'),
    LeaderboardEntry(rank: 7, user: _users[6], score: 130900, scoreLabel: '130.9K ❤️'),
  ];

  static final notifications = <NotificationModel>[
    NotificationModel(
      id: 'n1',
      message: 'L\'équipe Take30 a aimé ta scène',
      subMessage: 'Il y a 2 min',
      type: NotificationType.like,
      time: DateTime.now().subtract(const Duration(minutes: 2)),
      avatarUrl: Take30Assets.avatarIaFemaleLead,
    ),
    NotificationModel(
      id: 'n2',
      message: 'Tu es dans le Top 10 du jour !',
      subMessage: 'Il y a 10 min',
      type: NotificationType.achievement,
      time: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    NotificationModel(
      id: 'n3',
      message: 'Max_Act a commenté ta scène',
      subMessage: 'Il y a 35 min',
      type: NotificationType.comment,
      time: DateTime.now().subtract(const Duration(minutes: 35)),
      avatarUrl: Take30Assets.avatarIaMaleLead,
    ),
    NotificationModel(
      id: 'n4',
      message: 'Nouveau duel disponible',
      subMessage: 'Il y a 1h',
      type: NotificationType.duel,
      time: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationModel(
      id: 'n5',
      message: 'ClaraScene a aimé ta performance',
      subMessage: 'Il y a 2h',
      type: NotificationType.like,
      time: DateTime.now().subtract(const Duration(hours: 2)),
      avatarUrl: Take30Assets.avatarIaFemaleAlt,
    ),
  ];

  static final currentDuel = DuelModel(
    id: 'd1',
    sceneA: _scenes[0],
    sceneB: _scenes[1],
    votesA: 1240,
    votesB: 980,
    expiresAt: DateTime.now().add(const Duration(hours: 6)),
  );

  static final dailyChallenge = DailyChallengeModel(
    id: 'dc1',
    sceneTitle: 'Scène Confrontation',
    quote: '"Tu m\'as trahi."',
    maxSeconds: 30,
    thumbnailUrl: 'https://images.unsplash.com/photo-1526510747491-58f928ec870f?w=400',
    rules: [
      '30 secondes max',
      'Joue avec émotion',
      'Partage pour gagner',
    ],
    expiresAt: DateTime.now().add(const Duration(hours: 14)),
    participantsCount: 1247,
  );

  static String formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
