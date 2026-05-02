import '../../../models/models.dart';

enum Take60AccountVisibility {
  publicProfile,
  talentsOnly,
  privateProfile,
}

enum Take60VideoVisibility {
  publicVideos,
  subscribersOnly,
  privateVideos,
}

extension Take60AccountVisibilityX on Take60AccountVisibility {
  String get label {
    switch (this) {
      case Take60AccountVisibility.publicProfile:
        return 'Profil public';
      case Take60AccountVisibility.talentsOnly:
        return 'Talents uniquement';
      case Take60AccountVisibility.privateProfile:
        return 'Profil prive';
    }
  }

  String get description {
    switch (this) {
      case Take60AccountVisibility.publicProfile:
        return 'Votre profil est visible par tout le monde dans Take60.';
      case Take60AccountVisibility.talentsOnly:
        return 'Seulement les talents connectes peuvent voir votre profil complet.';
      case Take60AccountVisibility.privateProfile:
        return 'Votre profil est masque hors invitations et acces directs.';
    }
  }

  String get storageValue {
    return switch (this) {
      Take60AccountVisibility.publicProfile => 'public',
      Take60AccountVisibility.talentsOnly => 'talents_only',
      Take60AccountVisibility.privateProfile => 'private',
    };
  }

  static Take60AccountVisibility fromStorage(String? value) {
    switch (value) {
      case 'talents_only':
        return Take60AccountVisibility.talentsOnly;
      case 'private':
        return Take60AccountVisibility.privateProfile;
      case 'public':
      default:
        return Take60AccountVisibility.publicProfile;
    }
  }
}

extension Take60VideoVisibilityX on Take60VideoVisibility {
  String get label {
    switch (this) {
      case Take60VideoVisibility.publicVideos:
        return 'Vidos publiques';
      case Take60VideoVisibility.subscribersOnly:
        return 'Abonnes uniquement';
      case Take60VideoVisibility.privateVideos:
        return 'Vidos privees';
    }
  }

  String get description {
    switch (this) {
      case Take60VideoVisibility.publicVideos:
        return 'Vos performances sont visibles depuis le profil et l\'exploration.';
      case Take60VideoVisibility.subscribersOnly:
        return 'Les performances sont reserves a votre audience abonnee.';
      case Take60VideoVisibility.privateVideos:
        return 'Les performances restent privees tant que vous ne les partagez pas.';
    }
  }

  String get storageValue {
    return switch (this) {
      Take60VideoVisibility.publicVideos => 'public',
      Take60VideoVisibility.subscribersOnly => 'subscribers_only',
      Take60VideoVisibility.privateVideos => 'private',
    };
  }

  static Take60VideoVisibility fromStorage(String? value) {
    switch (value) {
      case 'subscribers_only':
        return Take60VideoVisibility.subscribersOnly;
      case 'private':
        return Take60VideoVisibility.privateVideos;
      case 'public':
      default:
        return Take60VideoVisibility.publicVideos;
    }
  }
}

class Take60UserProfile {
  const Take60UserProfile({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.bio,
    required this.roleLabel,
    required this.regionName,
    required this.countryName,
    required this.isVerified,
    required this.isTalentValidated,
    required this.isTrending,
    required this.isAdmin,
    required this.castingModeEnabled,
    required this.autoAcceptInvites,
    required this.notificationsEnabled,
    required this.accountVisibility,
    required this.videoVisibility,
    required this.darkModeEnabled,
  });

  final String userId;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String bio;
  final String roleLabel;
  final String regionName;
  final String countryName;
  final bool isVerified;
  final bool isTalentValidated;
  final bool isTrending;
  final bool isAdmin;
  final bool castingModeEnabled;
  final bool autoAcceptInvites;
  final bool notificationsEnabled;
  final Take60AccountVisibility accountVisibility;
  final Take60VideoVisibility videoVisibility;
  final bool darkModeEnabled;

  List<String> get badgeLabels {
    final badges = <String>[];
    if (isVerified) {
      badges.add('Verifie');
    }
    if (isTalentValidated) {
      badges.add('Talent valide');
    }
    if (isTrending) {
      badges.add('Trending');
    }
    if (isAdmin) {
      badges.add('Admin');
    }
    return badges;
  }

  Take60UserProfile copyWith({
    String? userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? roleLabel,
    String? regionName,
    String? countryName,
    bool? isVerified,
    bool? isTalentValidated,
    bool? isTrending,
    bool? isAdmin,
    bool? castingModeEnabled,
    bool? autoAcceptInvites,
    bool? notificationsEnabled,
    Take60AccountVisibility? accountVisibility,
    Take60VideoVisibility? videoVisibility,
    bool? darkModeEnabled,
  }) {
    return Take60UserProfile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      roleLabel: roleLabel ?? this.roleLabel,
      regionName: regionName ?? this.regionName,
      countryName: countryName ?? this.countryName,
      isVerified: isVerified ?? this.isVerified,
      isTalentValidated: isTalentValidated ?? this.isTalentValidated,
      isTrending: isTrending ?? this.isTrending,
      isAdmin: isAdmin ?? this.isAdmin,
      castingModeEnabled: castingModeEnabled ?? this.castingModeEnabled,
      autoAcceptInvites: autoAcceptInvites ?? this.autoAcceptInvites,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      accountVisibility: accountVisibility ?? this.accountVisibility,
      videoVisibility: videoVisibility ?? this.videoVisibility,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'roleLabel': roleLabel,
      'regionName': regionName,
      'countryName': countryName,
      'isVerified': isVerified,
      'isTalentValidated': isTalentValidated,
      'isTrending': isTrending,
      'isAdmin': isAdmin,
      'castingModeEnabled': castingModeEnabled,
      'autoAcceptInvites': autoAcceptInvites,
      'notificationsEnabled': notificationsEnabled,
      'accountVisibility': accountVisibility.storageValue,
      'videoVisibility': videoVisibility.storageValue,
      'darkModeEnabled': darkModeEnabled,
    };
  }

  factory Take60UserProfile.fromMap(Map<String, dynamic> map) {
    return Take60UserProfile(
      userId: map['userId'] as String? ?? '',
      username: map['username'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      roleLabel: map['roleLabel'] as String? ?? 'Actrice / Createur',
      regionName: map['regionName'] as String? ?? '',
      countryName: map['countryName'] as String? ?? '',
      isVerified: map['isVerified'] as bool? ?? false,
      isTalentValidated: map['isTalentValidated'] as bool? ?? false,
      isTrending: map['isTrending'] as bool? ?? false,
      isAdmin: map['isAdmin'] as bool? ?? false,
      castingModeEnabled: map['castingModeEnabled'] as bool? ?? false,
      autoAcceptInvites: map['autoAcceptInvites'] as bool? ?? false,
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      accountVisibility: Take60AccountVisibilityX.fromStorage(
        map['accountVisibility'] as String?,
      ),
      videoVisibility: Take60VideoVisibilityX.fromStorage(
        map['videoVisibility'] as String?,
      ),
      darkModeEnabled: map['darkModeEnabled'] as bool? ?? true,
    );
  }

  factory Take60UserProfile.fromUserModel(
    UserModel user, {
    String? regionName,
    String? countryName,
    bool? castingModeEnabled,
    bool? autoAcceptInvites,
    bool? notificationsEnabled,
    Take60AccountVisibility? accountVisibility,
    Take60VideoVisibility? videoVisibility,
    bool? darkModeEnabled,
  }) {
    final trimmedBio = user.bio.trim();
    final followers = user.followersCount;
    final likes = user.likesCount;
    final roleLabel = user.isAdmin
        ? 'Admin Take60'
        : user.isVerified
            ? 'Actrice verifiee'
            : 'Actrice / Creatrice';
    return Take60UserProfile(
      userId: user.id,
      username: user.username,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      bio: trimmedBio.isEmpty
          ? 'Ajoutez une bio premium pour presenter votre univers Take60.'
          : trimmedBio,
      roleLabel: roleLabel,
      regionName: regionName ?? '',
      countryName: countryName ?? '',
      isVerified: user.isVerified,
      isTalentValidated: user.isVerified || user.approvalRate >= 0.75,
      isTrending: likes >= 1000 || followers >= 500 || user.totalViews >= 10000,
      isAdmin: user.isAdmin,
      castingModeEnabled: castingModeEnabled ?? user.isAdmin,
      autoAcceptInvites: autoAcceptInvites ?? false,
      notificationsEnabled: notificationsEnabled ?? true,
      accountVisibility:
          accountVisibility ?? Take60AccountVisibility.publicProfile,
      videoVisibility: videoVisibility ?? Take60VideoVisibility.publicVideos,
      darkModeEnabled: darkModeEnabled ?? true,
    );
  }
}