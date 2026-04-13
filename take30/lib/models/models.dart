import 'package:flutter/material.dart';

class FeatureItem {
  const FeatureItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? route;
}

class NotificationItem {
  const NotificationItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isNew = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isNew;
}

class SceneIdea {
  const SceneIdea({
    required this.title,
    required this.category,
    required this.description,
    required this.minutes,
  });

  final String title;
  final String category;
  final String description;
  final int minutes;
}

class UserStats {
  const UserStats({
    required this.level,
    required this.streakDays,
    required this.publishedCount,
    required this.communityScore,
    required this.nextBadge,
  });

  final String level;
  final int streakDays;
  final int publishedCount;
  final int communityScore;
  final String nextBadge;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.name,
    required this.score,
  });

  final String name;
  final int score;
}

class TakeDraft {
  const TakeDraft({
    required this.title,
    required this.description,
    required this.sceneType,
    required this.duration,
    required this.mood,
  });

  final String title;
  final String description;
  final String sceneType;
  final int duration;
  final String mood;
}
