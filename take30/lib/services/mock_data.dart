import 'package:flutter/material.dart';

import '../models/models.dart';

const dashboardItems = <FeatureItem>[
  FeatureItem(
    title: 'Défi du jour',
    subtitle: 'Accepter une consigne et tourner en 30 minutes.',
    icon: Icons.bolt_rounded,
    route: '/challenge',
  ),
  FeatureItem(
    title: 'Battle',
    subtitle: 'Comparer ta prise avec la communauté.',
    icon: Icons.emoji_events_outlined,
    route: '/battle',
  ),
  FeatureItem(
    title: 'Progression',
    subtitle: 'Suivre badges, statistiques et régularité.',
    icon: Icons.insights_outlined,
    route: '/badges',
  ),
];

const notifications = <NotificationItem>[
  NotificationItem(
    title: 'Nouveau badge',
    subtitle: 'Tu as débloqué Créatif du jour.',
    icon: Icons.workspace_premium_outlined,
    isNew: true,
  ),
  NotificationItem(
    title: 'Battle ouverte',
    subtitle: 'Un duel est prêt à être lancé.',
    icon: Icons.local_fire_department_outlined,
    isNew: true,
  ),
  NotificationItem(
    title: 'Rappel',
    subtitle: 'Publie ton Take30 avant ce soir.',
    icon: Icons.notifications_active_outlined,
  ),
];

const sceneIdeas = <SceneIdea>[
  SceneIdea(
    title: 'Cuisine rapide',
    category: 'Lifestyle',
    description: 'Montrer une recette courte en trois plans dynamiques.',
    minutes: 20,
  ),
  SceneIdea(
    title: 'Portrait créatif',
    category: 'Portrait',
    description: 'Jouer avec la lumière et un angle fort.',
    minutes: 30,
  ),
  SceneIdea(
    title: 'Mini reportage',
    category: 'Storytelling',
    description: 'Raconter une situation simple avec intro et chute.',
    minutes: 35,
  ),
];

const profileStats = UserStats(
  level: 'Intermédiaire',
  streakDays: 5,
  publishedCount: 12,
  communityScore: 87,
  nextBadge: 'Maître du rythme',
);

const leaderboard = <LeaderboardScoreEntry>[
  LeaderboardScoreEntry(name: 'Lina', score: 100),
  LeaderboardScoreEntry(name: 'Youssef', score: 93),
  LeaderboardScoreEntry(name: 'Maya', score: 89),
  LeaderboardScoreEntry(name: 'Noah', score: 84),
];

final mockUsers = <UserModel>[
  const UserModel(
    id: 'u1',
    username: 'LunaAct',
    displayName: 'LunaAct',
    avatarUrl: 'https://i.pravatar.cc/150?img=47',
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
    avatarUrl: 'https://i.pravatar.cc/150?img=12',
    followersCount: 10800,
  ),
  const UserModel(
    id: 'u3',
    username: 'NeoPlayer',
    displayName: 'NeoPlayer',
    avatarUrl: 'https://i.pravatar.cc/150?img=33',
    followersCount: 8900,
  ),
  const UserModel(
    id: 'u4',
    username: 'ClaraScene',
    displayName: 'ClaraScene',
    avatarUrl: 'https://i.pravatar.cc/150?img=44',
    isVerified: true,
    followersCount: 8100,
  ),
  const UserModel(
    id: 'u5',
    username: 'TheoDrama',
    displayName: 'TheoDrama',
    avatarUrl: 'https://i.pravatar.cc/150?img=15',
    followersCount: 7500,
  ),
  const UserModel(
    id: 'u6',
    username: 'ActQueen',
    displayName: 'ActQueen',
    avatarUrl: 'https://i.pravatar.cc/150?img=20',
    isVerified: true,
    followersCount: 6900,
  ),
  const UserModel(
    id: 'u7',
    username: 'VictorPlay',
    displayName: 'VictorPlay',
    avatarUrl: 'https://i.pravatar.cc/150?img=68',
    followersCount: 6100,
  ),
];

const mockCategories = <CategoryModel>[
  CategoryModel(id: 'c1', name: 'Drame', emoji: '🎭', scenesCount: 1240),
  CategoryModel(id: 'c2', name: 'Comédie', emoji: '😂', scenesCount: 890),
  CategoryModel(id: 'c3', name: 'Action', emoji: '💥', scenesCount: 654),
  CategoryModel(id: 'c4', name: 'Romance', emoji: '❤️', scenesCount: 780),
  CategoryModel(id: 'c5', name: 'Thriller', emoji: '😱', scenesCount: 432),
];

final mockScenes = <SceneModel>[
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
    author: mockUsers[0],
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
    author: mockUsers[1],
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
    author: mockUsers[2],
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
    author: mockUsers[3],
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
    author: mockUsers[4],
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
    author: mockUsers[5],
    createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
  ),
];

const mockBadges = <BadgeModel>[
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

final mockLeaderboardEntries = <LeaderboardEntry>[
  LeaderboardEntry(rank: 1, user: mockUsers[0], score: 245200, scoreLabel: '245.2K ❤️'),
  LeaderboardEntry(rank: 2, user: mockUsers[1], score: 210500, scoreLabel: '210.5K ❤️'),
  LeaderboardEntry(rank: 3, user: mockUsers[2], score: 188300, scoreLabel: '188.3K ❤️'),
  LeaderboardEntry(rank: 4, user: mockUsers[3], score: 176400, scoreLabel: '176.4K ❤️'),
  LeaderboardEntry(rank: 5, user: mockUsers[4], score: 150200, scoreLabel: '150.2K ❤️'),
  LeaderboardEntry(rank: 6, user: mockUsers[5], score: 142800, scoreLabel: '142.8K ❤️'),
  LeaderboardEntry(rank: 7, user: mockUsers[6], score: 130900, scoreLabel: '130.9K ❤️'),
];

final mockNotificationModels = <NotificationModel>[
  NotificationModel(
    id: 'n1',
    message: 'L\'équipe Take30 a aimé ta scène',
    subMessage: 'Il y a 2 min',
    type: NotificationType.like,
    time: DateTime.now().subtract(const Duration(minutes: 2)),
    avatarUrl: 'https://i.pravatar.cc/150?img=50',
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
    avatarUrl: 'https://i.pravatar.cc/150?img=12',
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
    avatarUrl: 'https://i.pravatar.cc/150?img=44',
  ),
];

final mockCurrentDuel = DuelModel(
  id: 'd1',
  sceneA: mockScenes[0],
  sceneB: mockScenes[1],
  votesA: 1240,
  votesB: 980,
  expiresAt: DateTime.now().add(const Duration(hours: 6)),
);

final mockDailyChallenge = DailyChallengeModel(
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

class MockData {
  static final users = mockUsers;
  static const categories = mockCategories;
  static final scenes = mockScenes;
  static const badges = mockBadges;
  static final leaderboard = mockLeaderboardEntries;
  static final notifications = mockNotificationModels;
  static final currentDuel = mockCurrentDuel;
  static final dailyChallenge = mockDailyChallenge;

  static String formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
