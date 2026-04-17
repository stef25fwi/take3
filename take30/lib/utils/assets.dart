class Take30Assets {
  const Take30Assets._();

  static const String avatarIaFemaleLead = 'assets/avatars/avatar_ia_female_lead.webp';
  static const String avatarIaFemaleAlt = 'assets/avatars/avatar_ia_female_alt.webp';
  static const String avatarIaMaleLead = 'assets/avatars/avatar_ia_male_lead.webp';
  static const String avatarCurrentUser = avatarIaFemaleLead;

  static const String sceneRuptureTelephone = 'assets/scenes/scene_rupture_telephone.svg';
  static const String sceneInterrogatoire = 'assets/scenes/scene_interrogatoire.svg';
  static const String sceneDeclarationAmour = 'assets/scenes/scene_declaration_amour.svg';
  static const String sceneMauvaiseNouvelle = 'assets/scenes/scene_mauvaise_nouvelle.svg';
  static const String sceneConfrontation = 'assets/scenes/scene_confrontation.svg';

  static const String heroOnboarding = 'assets/onboarding/hero_onboarding.svg';

  static String avatarForUserId(String userId) {
    const map = {
      'u1': avatarIaFemaleLead,
      'u2': avatarIaMaleLead,
      'u3': avatarIaMaleLead,
      'u4': avatarIaFemaleAlt,
      'u5': avatarIaMaleLead,
      'u6': avatarIaFemaleAlt,
      'u7': avatarIaMaleLead,
    };
    return map[userId] ?? avatarCurrentUser;
  }

  static String sceneForId(String sceneId) {
    const map = {
      's1': sceneRuptureTelephone,
      's2': sceneInterrogatoire,
      's3': sceneDeclarationAmour,
      's4': sceneMauvaiseNouvelle,
      's5': sceneConfrontation,
      's6': sceneMauvaiseNouvelle,
    };
    return map[sceneId] ?? sceneRuptureTelephone;
  }
}