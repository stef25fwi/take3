Objectif : ajouter un bouton “Dashboard admin” dans la page profil de l’utilisateur admin.

Comportement attendu :
- Quand un utilisateur admin est connecté, il peut utiliser l’application normalement.
- Sur sa page profil, afficher un bouton visible “Dashboard admin” ou “Espace admin”.
- Le bouton doit rediriger vers AppRouter.admin.
- Le bouton ne doit apparaître que si l’utilisateur connecté est admin.
- Les utilisateurs non admin ne doivent pas voir ce bouton.
- Le mode démo/local ne doit pas donner accès à ce bouton si ce n’est pas un vrai admin.
- L’accès admin doit continuer à passer par Firebase Auth et la route /admin déjà protégée.

Fichiers à analyser :
- take30/lib/screens/profile_screen.dart
- take30/lib/router/router.dart
- take30/lib/services/auth_service.dart
- take30/lib/providers/providers.dart
- take30/lib/models/models.dart ou user model si nécessaire

À faire :
1. Dans profile_screen.dart, récupérer l’utilisateur connecté :
   final authUser = ref.watch(authProvider).user;
2. Déterminer si le profil affiché correspond à l’utilisateur connecté :
   authUser?.id == userId
3. Déterminer si l’utilisateur connecté est admin :
   authUser?.isAdmin == true
   ou authUser?.role == 'admin' si le modèle expose role.
4. Afficher un bouton uniquement si :
   - authUser != null
   - authUser.isAdmin == true
   - le profil affiché est celui de l’utilisateur connecté, sauf si le design préfère l’afficher partout pour admin.
5. UI souhaitée :
   - bouton premium dans la page profil
   - icône Icons.admin_panel_settings_rounded
   - texte “Dashboard admin”
   - sous-texte optionnel “Gérer les scènes, VEO et publications”
   - style cohérent avec Take60
6. Au clic :
   context.push(AppRouter.admin) ou context.go(AppRouter.admin)
7. Importer AppRouter si nécessaire :
   import '../router/router.dart';
8. Ne pas utiliser AppRouter.adminAccess.
9. Ne pas contourner la protection du router.
10. Ajouter au besoin une petite méthode privée :
   bool _canShowAdminDashboardButton(UserModel? authUser, String profileUserId)
11. Validation obligatoire :
   flutter analyze
   flutter test --reporter expanded
