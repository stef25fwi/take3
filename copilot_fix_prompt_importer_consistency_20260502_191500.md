# PROMPT COPILOT — FIX Importeur prompt Ajout scène Take60

Tu es un senior Flutter engineer. Objectif : corriger les incohérences métier de l’importeur “Coller un prompt scénario” ajouté dans la page admin Ajout scène.

Fichier principal probable :
take30/lib/admin/take30_admin_scene_flow.dart

IMPORTANT :
- Ne supprime aucune logique existante.
- Garde l’admin réel existant.
- Ne casse pas speech-to-text.
- Ne casse pas VEO.
- Ne casse pas les boutons brouillon / attente / publication.
- Ne casse pas SceneFormData.
- Ne casse pas Firestore payload.
- Le code doit passer flutter analyze.
- Ajoute ou adapte des tests ciblés si possible.

====================================================
1. FIX HAUTE SÉVÉRITÉ — IMPORT VEO NE DOIT PAS DÉSYNCHRONISER UNE VIDÉO VALIDÉE
====================================================

Problème :
L’importeur réécrit veoPromptCtrl même si une vidéo IA / preview VEO a déjà été validée et verrouillée. Cela contourne le verrou UI existant et peut publier une scène avec une preview validée qui ne correspond plus au prompt persisté.

À faire :
- Dans _applyPromptImport(), ne jamais écraser veoPromptCtrl si le prompt VEO est verrouillé ou si une vidéo IA validée existe déjà.
- Utiliser les signaux existants, par exemple :
  - _isVeoPromptLocked
  - aiIntroVideo existant dans initialData ou état courant
  - _veoStatusValue completed si pertinent
  - _veoOperationId non null si pertinent
- Ajouter une fonction privée claire :
  bool get _hasValidatedVeoPreview
  ou
  bool _canImportVeoPrompt()

Règle :
- Si aucune preview VEO validée :
  - importer le prompt VEO normalement.
- Si preview VEO déjà validée / prompt verrouillé :
  - ne pas modifier veoPromptCtrl
  - ne pas modifier _veoStatusValue
  - ne pas modifier _veoOperationId
  - ne pas modifier _veoGenerationError
  - ne pas modifier aiIntroVideo
  - ajouter un warning import :
    “Prompt VEO ignoré : une vidéo IA est déjà validée. Supprime ou régénère la preview pour changer le prompt.”

UX :
- Le résumé d’import doit afficher :
  - Prompt VEO détecté
  - Prompt VEO non importé si verrouillé
- SnackBar warning si au moins un champ a été ignoré.

Ne pas ajouter de bouton dangereux “forcer” qui remplace silencieusement la preview.

====================================================
2. FIX SÉVÉRITÉ MOYENNE — OBJECTIF LIBRE NE DOIT PAS ALLER DANS OBSTACLE
====================================================

Problème :
Quand l’objectif personnage importé ne matche pas exactement une option du dropdown, le code le met dans le champ obstacle. C’est faux : “Objectif: nier les faits” devient un obstacle.

À faire :
- Chercher la logique d’import autour du matching objectif.
- Interdire le fallback objectif -> obstacle.
- L’obstacle ne doit être rempli que par une section ou ligne explicitement nommée :
  - OBSTACLE
  - Obstacles
  - Obstacle principal
  - Contrainte
- Si l’objectif importé ne matche pas une option du dropdown :
  - conserver la valeur d’objectif actuelle si le champ est strictement dropdown
  - préserver le texte libre dans le meilleur champ existant :
    - notes personnage
    - fiche acteur
    - consignes de jeu
    - sous-texte
    - acting instructions
  - ajouter une ligne claire :
    “Objectif importé : nier les faits tout en comprenant que l’enquêtrice se rapproche de la vérité.”
- Si un champ texte libre d’objectif existe déjà, l’utiliser plutôt que les notes.
- Ne jamais écrire l’objectif libre dans obstacle.

Résultat attendu :
- Objectif dropdown = valeur matchée seulement si match fiable.
- Obstacle = uniquement obstacle explicite.
- Objectif libre = préservé dans champ objectif libre ou notes acteur.

====================================================
3. FIX SÉVÉRITÉ MOYENNE — TITRE ET PROJECT TITLE DOIVENT RESTER SYNCHRONISÉS
====================================================

Problème :
L’import remplit sceneName/title mais ne met projectTitle que s’il est vide. Un ré-import peut laisser deux titres contradictoires.

À faire :
- Quand l’import contient un titre de scène valide :
  - mettre à jour le champ titre visible principal
  - mettre à jour aussi projectTitleCtrl ou équivalent
- Ne pas laisser projectTitle ancien après import.
- Si le projet distingue volontairement “titre scène” et “titre projet”, alors :
  - si le prompt contient seulement TITRE DE LA SCÈNE, synchroniser les deux
  - si le prompt contient aussi TITRE DU PROJET, utiliser TITRE DU PROJET pour projectTitle
- Ajouter ce mapping :
  - TITRE DE LA SCÈNE -> sceneName/title + projectTitle si pas de titre projet séparé
  - TITRE DU PROJET -> projectTitle uniquement

====================================================
4. DURCIR LE PARSEUR — NE PAS CASSER SUR DES SOUS-CHAMPS GÉNÉRIQUES
====================================================

Problème :
Des headings très génériques peuvent casser l’extraction. Exemple :
PERSONNAGE À JOUER PAR L’UTILISATEUR
Nom : Malik
Objectif : nier les faits
Profil : suspect...

Le parseur ne doit pas considérer “Objectif:” ou “Profil:” comme une nouvelle section globale.

À faire :
- Séparer clairement :
  1. headings globaux de sections
  2. sous-champs internes avec “clé : valeur”
- Les sous-champs suivants ne doivent PAS être dans la liste des headings globaux :
  - Nom
  - Âge
  - Age
  - Profil
  - Objectif
  - Ton
  - Sous-texte
  - État émotionnel
  - Etat émotionnel
  - Dialogue
  - Région
  - Region
- Les headings globaux acceptés doivent être des intitulés complets :
  - TITRE DE LA SCÈNE
  - TITRE DU PROJET
  - CATÉGORIE
  - GENRE
  - TYPE DE SCÈNE
  - DIFFICULTÉ
  - DURÉE CIBLE
  - PAYS / RÉGION
  - LIEU
  - LOGLINE
  - SYNOPSIS COURT
  - INTENTION DE RÉALISATION
  - PERSONNAGE À JOUER PAR L’UTILISATEUR
  - PERSONNAGE IA / INTRO
  - TEXTE / DIALOGUE ACTEUR
  - CONSIGNES DE JEU
  - RYTHME
  - PROMPT VEO POUR LA VIDÉO IA D’INTRO 15 SECONDES
  - PROMPT VEO VERSION FRANÇAISE
  - TIMELINE TAKE60 GUIDÉE JSON
  - NOTES TECHNIQUES
  - MOTS-CLÉS
  - OBJECTIF TEST PAGE AJOUT SCÈNE
- Matching heading :
  - trim
  - normalisation accents/casse
  - ligne seule ou ligne finissant par “:”
  - ne pas matcher une phrase longue contenant le mot
- Ne pas considérer “Dialogue: ...” dans un JSON ou une timeline comme heading global.

====================================================
5. TESTS À AJOUTER OU COMPLÉTER
====================================================

Ajouter des tests ciblés, idéalement sur le parseur et/ou widget admin :

Test 1 — VEO locked :
- état avec prompt VEO verrouillé / preview existante
- importer un prompt contenant PROMPT VEO
- vérifier que veoPromptCtrl ne change pas
- vérifier warning présent ou état ignoredFields

Test 2 — objectif libre :
- importer :
  PERSONNAGE À JOUER PAR L’UTILISATEUR
  Objectif : nier les faits
- vérifier que obstacle n’est pas “nier les faits”
- vérifier que l’objectif libre est préservé dans notes/objective free field

Test 3 — ré-import titre :
- formulaire avec ancien projectTitle
- importer TITRE DE LA SCÈNE “Interrogatoire sous tension”
- vérifier sceneName/title == “Interrogatoire sous tension”
- vérifier projectTitle == “Interrogatoire sous tension”

Test 4 — parser sous-champs :
- section personnage avec Nom, Profil, Objectif, Ton
- vérifier que toute la section reste dans userCharacter
- vérifier que l’extraction des sections suivantes continue correctement

====================================================
6. VALIDATION
====================================================

Après correction :
- flutter analyze
- test ciblé admin/importeur
- aucun warning métier lié à ces trois cas

À la fin, donne :
1. fichiers modifiés
2. fonctions modifiées
3. règles métier appliquées
4. tests ajoutés
5. résultat flutter analyze