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

const leaderboard = <LeaderboardEntry>[
  LeaderboardEntry(name: 'Lina', score: 100),
  LeaderboardEntry(name: 'Youssef', score: 93),
  LeaderboardEntry(name: 'Maya', score: 89),
  LeaderboardEntry(name: 'Noah', score: 84),
];
