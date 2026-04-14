# TAKE30 — Prompt de placement des images dans le code Flutter

## CONTEXTE
Ce fichier contient les instructions exactes pour intégrer les images SVG/PNG dans le code Flutter Take30.
Toutes les images sont dans le dossier `assets/` du projet.

---

## 1. CONFIGURATION pubspec.yaml

Remplace la section `flutter:` par :

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/avatars/
    - assets/scenes/
    - assets/onboarding/
```

---

## 2. LISTE DES IMAGES ET LEUR EMPLACEMENT

### AVATARS (assets/avatars/)

| Fichier | Utilisateur | Utilisé dans |
|---------|------------|--------------|
| `avatar_luna_act.svg` | LunaAct — femme afro-latine, cheveux bouclés | Feed, Profil, Leaderboard rang 1, Battle côté A |
| `avatar_max_act.svg` | Max_Act — homme européen, barbe | Feed, Leaderboard rang 2, Battle côté B, Notifications |
| `avatar_neo_player.svg` | NeoPlayer — homme asiatique, style moderne | Leaderboard rang 3 |
| `avatar_clara_scene.svg` | ClaraScene — femme méditerranéenne, cheveux longs | Leaderboard rang 4 |
| `avatar_theo_drama.svg` | TheoDrama — homme afro-américain | Leaderboard rang 5 |
| `avatar_act_queen.svg` | ActQueen — femme moyen-orientale, maquillage dramatique | Leaderboard rang 6 |
| `avatar_victor_play.svg` | VictorPlay — homme latino | Leaderboard rang 7 |
| `avatar_current_user.svg` | Utilisateur courant (toi) — femme sud-asiatique | AppBar Feed, Profil courant, Enregistrement |

### SCÈNES (assets/scenes/)

| Fichier | Scène | Utilisé dans |
|---------|-------|--------------|
| `scene_rupture_telephone.svg` | Rupture au téléphone — Drame | Feed card 1, Explore grille, Battle côté A |
| `scene_interrogatoire.svg` | Interrogatoire tendu — Thriller | Feed card 2, Explore grille, Battle côté B |
| `scene_declaration_amour.svg` | Déclaration d'amour — Romance | Feed card 3, Explore grille |
| `scene_mauvaise_nouvelle.svg` | Annonce mauvaise nouvelle — Drame | Feed card 4, Preview/Publish, Enregistrement bg, Profil grille |
| `scene_confrontation.svg` | Confrontation — Drame | Défi du Jour, Profil grille |

### ONBOARDING (assets/onboarding/)

| Fichier | Description | Utilisé dans |
|---------|-------------|--------------|
| `hero_onboarding.svg` | Collage 3 acteurs, cinématique | Screen 2 Onboarding (background) |

---

## 3. REMPLACEMENTS DANS CHAQUE FICHIER DART

### splash_screen.dart
Aucune image à remplacer (fond pur navy).

---

### onboarding_screen.dart
**Ligne : image background**
```dart
// AVANT:
Image.network(
  'https://images.unsplash.com/photo-1526510747491-58f928ec870f?w=800&q=80',
  fit: BoxFit.cover,
  errorBuilder: ...
)

// APRÈS:
Image.asset(
  'assets/onboarding/hero_onboarding.svg',  // SVG via flutter_svg
  fit: BoxFit.cover,
)
// OU avec flutter_svg:
SvgPicture.asset(
  'assets/onboarding/hero_onboarding.svg',
  fit: BoxFit.cover,
  width: double.infinity,
  height: double.infinity,
)
```

---

### home_screen.dart (Feed)
**Dans `_FeedCard` — thumbnails des scènes :**
```dart
// AVANT (réseau):
Image.network(s.thumbnailUrl, fit: BoxFit.cover, ...)

// APRÈS (assets locaux):
Image.asset(
  _getSceneAsset(s.id),
  fit: BoxFit.cover,
)

// Helper function à ajouter:
String _getSceneAsset(String sceneId) {
  switch (sceneId) {
    case 's1': return 'assets/scenes/scene_rupture_telephone.svg';
    case 's2': return 'assets/scenes/scene_interrogatoire.svg';
    case 's3': return 'assets/scenes/scene_declaration_amour.svg';
    case 's4': return 'assets/scenes/scene_mauvaise_nouvelle.svg';
    case 's5': return 'assets/scenes/scene_confrontation.svg';
    default:   return 'assets/scenes/scene_rupture_telephone.svg';
  }
}
```

**Avatar top-right (utilisateur courant) :**
```dart
// AVANT:
UserAvatar(url: 'https://i.pravatar.cc/150?img=47', size: 34, showBorder: true)

// APRÈS:
CircleAvatar(
  radius: 17,
  backgroundImage: AssetImage('assets/avatars/avatar_current_user.svg'),
)
// OU avec flutter_svg + ClipOval:
ClipOval(
  child: SvgPicture.asset(
    'assets/avatars/avatar_current_user.svg',
    width: 34, height: 34,
  ),
)
```

**Avatar auteur dans chaque feed card :**
```dart
// AVANT:
UserAvatar(url: s.author.avatarUrl, size: 30)

// APRÈS — dans UserAvatar widget, ajouter support asset:
// Dans shared_widgets.dart, modifier UserAvatar:
class UserAvatar extends StatelessWidget {
  final String? url;
  final String? assetPath;  // NOUVEAU CHAMP
  // ...
  Widget build(...) {
    return ClipOval(
      child: assetPath != null
        ? SvgPicture.asset(assetPath!, fit: BoxFit.cover)
        : Image.network(url!, fit: BoxFit.cover, ...),
    );
  }
}
```

---

### explore_screen.dart
**Thumbnails grille 3 colonnes :**
```dart
// Dans _ThumbCard:
// AVANT:
Image.network(scene.thumbnailUrl, fit: BoxFit.cover, ...)

// APRÈS:
Image.asset(
  _getSceneThumb(scene.id),
  fit: BoxFit.cover,
)
```

---

### record_screen.dart
**Background semi-transparent pendant recording :**
```dart
// AVANT:
Image.network(_scene?.thumbnailUrl ?? '', fit: BoxFit.cover, ...)

// APRÈS:
_scene != null
  ? Image.asset(
      _getSceneAsset(_scene!.id),
      fit: BoxFit.cover,
      opacity: const AlwaysStoppedAnimation(0.4),
    )
  : Container(color: const Color(0xFF0A0A0A))
```

---

### preview_publish_screen.dart
**Preview vidéo :**
```dart
// AVANT:
background: url('https://images.unsplash.com/...') center/cover

// APRÈS dans preview_video_img:
Image.asset(
  'assets/scenes/scene_mauvaise_nouvelle.svg',
  fit: BoxFit.cover,
  width: double.infinity,
  height: 230,
)
```

---

### battle_screen.dart
**Vidéo A et Vidéo B :**
```dart
// AVANT:
Image.network(scene.thumbnailUrl, fit: BoxFit.cover, ...)

// APRÈS:
// Vidéo A (LunaAct):
Image.asset('assets/scenes/scene_rupture_telephone.svg', fit: BoxFit.cover)
// Vidéo B (Max_Act):
Image.asset('assets/scenes/scene_interrogatoire.svg', fit: BoxFit.cover)
```

---

### leaderboard_screen.dart
**Avatars de chaque rangée :**
```dart
// AVANT:
UserAvatar(url: e.user.avatarUrl, size: 40)

// APRÈS — mapper les userId aux assets:
Image.asset(
  _getUserAvatar(e.user.id),
  width: 40, height: 40, fit: BoxFit.cover,
)

// Helper:
String _getUserAvatar(String userId) {
  const map = {
    'u1': 'assets/avatars/avatar_luna_act.svg',
    'u2': 'assets/avatars/avatar_max_act.svg',
    'u3': 'assets/avatars/avatar_neo_player.svg',
    'u4': 'assets/avatars/avatar_clara_scene.svg',
    'u5': 'assets/avatars/avatar_theo_drama.svg',
    'u6': 'assets/avatars/avatar_act_queen.svg',
    'u7': 'assets/avatars/avatar_victor_play.svg',
  };
  return map[userId] ?? 'assets/avatars/avatar_luna_act.svg';
}
```

---

### profile_screen.dart
**Avatar principal centré :**
```dart
// AVANT:
UserAvatar(url: user.avatarUrl, size: 76, showBorder: true)

// APRÈS:
Container(
  width: 76, height: 76,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: AppColors.yellow, width: 2),
  ),
  child: ClipOval(
    child: SvgPicture.asset(
      'assets/avatars/avatar_luna_act.svg',  // ou dynamique par userId
      fit: BoxFit.cover,
    ),
  ),
)
```

**Grid performances :**
```dart
// Utiliser les scènes assets au lieu des URLs réseau
Image.asset('assets/scenes/scene_${index}.svg', fit: BoxFit.cover)
```

---

### notifications_screen.dart
**Avatars dans les rows notifications :**
```dart
// AVANT:
UserAvatar(url: notif.avatarUrl, size: 42)

// APRÈS:
ClipOval(
  child: SvgPicture.asset(
    notif.avatarUrl != null
      ? _mapAvatarUrl(notif.avatarUrl!)
      : 'assets/avatars/avatar_luna_act.svg',
    width: 42, height: 42,
    fit: BoxFit.cover,
  ),
)
```

---

### daily_challenge_screen.dart
**Photo droite de la card :**
```dart
// AVANT:
background: url('https://images.unsplash.com/.../') center/cover

// APRÈS:
Image.asset(
  'assets/scenes/scene_confrontation.svg',
  fit: BoxFit.cover,
  width: double.infinity,
  height: double.infinity,
)
```

**Photos "défis précédents" :**
```dart
// APRÈS:
final pastScenes = [
  'assets/scenes/scene_rupture_telephone.svg',
  'assets/scenes/scene_interrogatoire.svg',
  'assets/scenes/scene_declaration_amour.svg',
  'assets/scenes/scene_mauvaise_nouvelle.svg',
];
Image.asset(pastScenes[i % pastScenes.length], fit: BoxFit.cover)
```

---

## 4. DÉPENDANCES À AJOUTER dans pubspec.yaml

```yaml
dependencies:
  flutter_svg: ^2.0.9   # Pour afficher les fichiers .svg
```

**Import dans chaque fichier qui utilise SVG :**
```dart
import 'package:flutter_svg/flutter_svg.dart';
```

---

## 5. HELPER GLOBAL À CRÉER : lib/utils/assets.dart

```dart
/// Centralise tous les chemins d'assets Take30
class Take30Assets {
  // ── Avatars ──────────────────────────────────────────────────
  static const String lunaAct       = 'assets/avatars/avatar_luna_act.svg';
  static const String maxAct        = 'assets/avatars/avatar_max_act.svg';
  static const String neoPlayer     = 'assets/avatars/avatar_neo_player.svg';
  static const String claraScene    = 'assets/avatars/avatar_clara_scene.svg';
  static const String theoDrama     = 'assets/avatars/avatar_theo_drama.svg';
  static const String actQueen      = 'assets/avatars/avatar_act_queen.svg';
  static const String victorPlay    = 'assets/avatars/avatar_victor_play.svg';
  static const String currentUser   = 'assets/avatars/avatar_current_user.svg';

  // ── Scènes ───────────────────────────────────────────────────
  static const String sceneRupture       = 'assets/scenes/scene_rupture_telephone.svg';
  static const String sceneInterrogatoire = 'assets/scenes/scene_interrogatoire.svg';
  static const String sceneDeclaration   = 'assets/scenes/scene_declaration_amour.svg';
  static const String sceneMauvaiseNouvelle = 'assets/scenes/scene_mauvaise_nouvelle.svg';
  static const String sceneConfrontation = 'assets/scenes/scene_confrontation.svg';

  // ── Onboarding ───────────────────────────────────────────────
  static const String heroOnboarding    = 'assets/onboarding/hero_onboarding.svg';

  // ── Mappers ───────────────────────────────────────────────────
  static String avatarForUserId(String userId) {
    const map = {
      'u1': lunaAct,
      'u2': maxAct,
      'u3': neoPlayer,
      'u4': claraScene,
      'u5': theoDrama,
      'u6': actQueen,
      'u7': victorPlay,
    };
    return map[userId] ?? currentUser;
  }

  static String sceneForId(String sceneId) {
    const map = {
      's1': sceneRupture,
      's2': sceneInterrogatoire,
      's3': sceneDeclaration,
      's4': sceneMauvaiseNouvelle,
      's5': sceneConfrontation,
    };
    return map[sceneId] ?? sceneRupture;
  }

  /// Widget helper — avatar circulaire avec border optionnel
  static Widget avatarWidget({
    required String userId,
    double size = 40,
    bool showBorder = false,
    Color borderColor = const Color(0xFFFFB800),
  }) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
          ? Border.all(color: borderColor, width: 2)
          : null,
      ),
      child: ClipOval(
        child: SvgPicture.asset(
          avatarForUserId(userId),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Widget helper — thumbnail scène
  static Widget sceneThumb({
    required String sceneId,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return SvgPicture.asset(
      sceneForId(sceneId),
      width: width,
      height: height,
      fit: fit,
    );
  }
}
```

---

## 6. EXEMPLE D'UTILISATION DANS LE CODE

```dart
// Au lieu de:
Image.network(scene.thumbnailUrl, fit: BoxFit.cover)

// Utiliser:
Take30Assets.sceneThumb(sceneId: scene.id, fit: BoxFit.cover)

// Au lieu de:
UserAvatar(url: user.avatarUrl, size: 40)

// Utiliser:
Take30Assets.avatarWidget(userId: user.id, size: 40, showBorder: true)
```

---

## 7. MOCK DATA À METTRE À JOUR

Dans `lib/services/mock_data.dart`, remplacer les URLs Unsplash et pravatar par les assets locaux :

```dart
// AVANT dans UserModel:
avatarUrl: 'https://i.pravatar.cc/150?img=47'

// APRÈS:
avatarUrl: Take30Assets.lunaAct  // utiliser les constantes

// AVANT dans SceneModel:
thumbnailUrl: 'https://images.unsplash.com/...'

// APRÈS:
thumbnailUrl: Take30Assets.sceneRupture
```

---

## 8. NOTE SUR flutter_svg

Pour les SVG complexes comme ces avatars, `flutter_svg` est recommandé.
Si tu préfères des PNG, convertis les SVG avec :
```bash
# En ligne de commande avec Inkscape:
inkscape input.svg --export-png=output.png --export-width=200 --export-height=200
# Ou en ligne sur: svgtopng.com
```

---

*Fichier généré automatiquement pour Take30 Flutter MVP*
*8 avatars · 5 scènes · 1 onboarding hero = 14 images total*
