class Take30Assets {
  const Take30Assets._();

  static const String avatarLunaAct = 'assets/avatars/avatar_luna_act.svg';
  static const String avatarMaxAct = 'assets/avatars/avatar_max_act.svg';
  static const String avatarNeoPlayer = 'assets/avatars/avatar_neo_player.svg';
  static const String avatarClaraScene = 'assets/avatars/avatar_clara_scene.svg';
  static const String avatarTheoDrama = 'assets/avatars/avatar_theo_drama.svg';
  static const String avatarActQueen = 'assets/avatars/avatar_act_queen.svg';
  static const String avatarVictorPlay = 'assets/avatars/avatar_victor_play.svg';
  static const String avatarCurrentUser = 'assets/avatars/avatar_current_user.svg';

  static const String sceneRuptureTelephone = 'assets/scenes/scene_rupture_telephone.svg';
  static const String sceneInterrogatoire = 'assets/scenes/scene_interrogatoire.svg';
  static const String sceneDeclarationAmour = 'assets/scenes/scene_declaration_amour.svg';
  static const String sceneMauvaiseNouvelle = 'assets/scenes/scene_mauvaise_nouvelle.svg';
  static const String sceneConfrontation = 'assets/scenes/scene_confrontation.svg';

  static const String heroOnboarding = 'assets/onboarding/hero_onboarding.svg';

  static String avatarForUserId(String userId) {
    const map = {
      'u1': avatarLunaAct,
      'u2': avatarMaxAct,
      'u3': avatarNeoPlayer,
      'u4': avatarClaraScene,
      'u5': avatarTheoDrama,
      'u6': avatarActQueen,
      'u7': avatarVictorPlay,
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