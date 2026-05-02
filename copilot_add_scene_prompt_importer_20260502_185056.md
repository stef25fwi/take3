# PROMPT COPILOT — Take60 / Admin Ajout scène — Import automatique depuis prompt scénario

Tu es un senior Flutter engineer. Objectif : ajouter au début de la page admin “Ajout scène” un outil permettant de coller un prompt scénario complet, puis de remplir automatiquement les champs existants de la page.

IMPORTANT :
- Ne supprime aucune logique existante.
- Garde l’admin réel existant.
- Ne casse pas la génération VEO.
- Ne casse pas le speech-to-text de l’étape 7.
- Ne casse pas les boutons “Enregistrer en brouillon”, “Envoyer en attente”, “Publier”.
- Le code doit passer `flutter analyze`.
- Tout doit rester dans l’architecture actuelle.
- Fichier principal probable : take30/lib/admin/take30_admin_scene_flow.dart

====================================================
OBJECTIF PRODUIT
====================================================

Ajouter tout en haut du formulaire “Ajout scène”, avant “1) Informations générales”, une carte premium :

Titre :
“Importer un prompt scénario”

Sous-titre :
“Colle un scénario complet Take60, puis remplis automatiquement les champs de la fiche.”

Contenu :
- Un bouton ou accordéon “Coller un prompt complet”
- Un grand TextField multi-lignes
- Bouton principal : “Remplir automatiquement”
- Bouton secondaire : “Effacer le prompt”
- Message succès : “Champs remplis automatiquement.”
- Message erreur : “Aucune donnée exploitable détectée.”

Le TextField doit accepter des prompts structurés avec des sections comme :

TITRE DE LA SCÈNE
Interrogatoire sous tension

CATÉGORIE
Policier

GENRE
Drame / Thriller

TYPE DE SCÈNE
Interrogatoire / Confrontation

DIFFICULTÉ
Intense

DURÉE CIBLE
60 secondes

PAYS / RÉGION
France / Guadeloupe

LIEU
Salle d’interrogatoire sobre...

LOGLINE
...

SYNOPSIS COURT
...

INTENTION DE RÉALISATION
...

PERSONNAGE À JOUER PAR L’UTILISATEUR
Nom : Malik Darcel
Âge : 28-40 ans
Profil : suspect intelligent...
Objectif : nier les faits...
État émotionnel : méfiance...
Sous-texte : ...

PERSONNAGE IA / INTRO
Nom : Lieutenant Moreau
Profil : enquêtrice...
Objectif : ...
Ton : ...

TEXTE / DIALOGUE ACTEUR
...

CONSIGNES DE JEU
...

RYTHME
...

PROMPT VEO POUR LA VIDÉO IA D’INTRO 15 SECONDES
...

PROMPT VEO VERSION FRANÇAISE
...

TIMELINE TAKE60 GUIDÉE JSON
[
  {
    "id": "intro_ai_001",
    "type": "ai_intro",
    "role": "ai",
    "startSecond": 0,
    "endSecond": 15,
    "durationSeconds": 15,
    "camera": "...",
    "dialogue": "",
    "direction": "..."
  }
]

NOTES TECHNIQUES
...

MOTS-CLÉS
...

====================================================
FONCTIONNALITÉS À IMPLÉMENTER
====================================================

1. Ajouter un controller :
- TextEditingController importPromptCtrl

2. Ajouter un bool :
- bool _showPromptImporter = true ou bool _isPromptImporterExpanded = true

3. Bien disposer le controller :
- importPromptCtrl.dispose()

4. Créer un widget :
- Widget _promptImporterCard()

Ce widget doit être placé au début du ListView du formulaire, avant :
_section('1) Informations générales', ...)

5. Créer une fonction :
- void _applyPromptImport()

Cette fonction doit :
- lire importPromptCtrl.text
- parser les sections
- remplir automatiquement les TextEditingController existants
- ne jamais crash si une section est absente
- garder les champs existants non remplacés si la section correspondante est vide
- appeler setState()
- afficher un SnackBar de succès

6. Créer un parseur robuste :
- _ParsedScenePrompt _parseScenePrompt(String raw)
- String _extractSection(String raw, List<String> headings, List<String> allHeadings)
- String? _extractJsonArrayAfterHeading(String raw, List<String> headings)
- Map<String, String> _extractColonFields(String block)

Le parseur doit être tolérant :
- accepter majuscules/minuscules
- accepter accents
- accepter “TITRE”, “TITRE DE LA SCÈNE”, “Titre de la scène”
- accepter “PROMPT VEO”, “PROMPT VEO POUR LA VIDÉO IA D’INTRO 15 SECONDES”, “PROMPT VEO VERSION FRANÇAISE”
- accepter “TIMELINE TAKE60 GUIDÉE JSON”, “TIMELINE JSON”, “MONTAGE GUIDÉ JSON”
- extraire le JSON même s’il contient des retours ligne

7. Créer un modèle interne simple :
class _ParsedScenePrompt {
  final String title;
  final String category;
  final String genre;
  final String sceneType;
  final String difficulty;
  final String targetDuration;
  final String countryRegion;
  final String location;
  final String logline;
  final String synopsis;
  final String directorIntent;
  final String userCharacter;
  final String aiCharacter;
  final String dialogue;
  final String actingGuidance;
  final String rhythm;
  final String veoPrompt;
  final String veoPromptFrench;
  final String guidedTimelineJson;
  final String technicalNotes;
  final String keywords;
}

8. Mapping attendu vers les champs existants

Cherche les controllers actuels dans take30_admin_scene_flow.dart et remplis-les.

Mapping fonctionnel attendu :

- TITRE DE LA SCÈNE -> title controller existant
- CATÉGORIE -> category controller ou dropdown existant
- GENRE -> genre controller existant
- TYPE DE SCÈNE -> scene type controller existant
- DIFFICULTÉ -> difficulty controller existant
- DURÉE CIBLE -> duration controller existant
- PAYS / RÉGION -> champs country / region si existants
- LIEU -> location / whereAreWe controller existant
- LOGLINE -> logline controller existant
- SYNOPSIS COURT -> synopsis controller existant
- INTENTION DE RÉALISATION -> director intention / director note controller existant
- PERSONNAGE À JOUER PAR L’UTILISATEUR -> actor role / character / role instructions
- PERSONNAGE IA / INTRO -> ai intro character / intro notes si existant
- TEXTE / DIALOGUE ACTEUR -> dialogueTextCtrl
- CONSIGNES DE JEU -> acting instructions / performance guidance controller existant
- RYTHME -> rhythm controller existant
- PROMPT VEO POUR LA VIDÉO IA D’INTRO 15 SECONDES -> veoPromptCtrl
- PROMPT VEO VERSION FRANÇAISE -> si le prompt anglais est vide, utiliser celui-ci pour veoPromptCtrl, sinon l’ajouter dans notes
- TIMELINE TAKE60 GUIDÉE JSON -> markersJsonCtrl
- NOTES TECHNIQUES -> technical notes controller existant
- MOTS-CLÉS -> keywords / tags controller existant

Si un champ exact n’existe pas :
- ne crée pas de doublon inutile
- ajoute l’information dans le champ le plus proche déjà existant, par exemple notes / direction / actor sheet
- ne casse pas SceneFormData

9. Validation JSON timeline

Quand TIMELINE TAKE60 GUIDÉE JSON est détecté :
- vérifier que c’est un JSON valide avec jsonDecode
- si valide : mettre le JSON formaté dans markersJsonCtrl avec JsonEncoder.withIndent('  ')
- si invalide : ne pas crash, mettre le texte brut et afficher un SnackBar warning “Timeline JSON importée mais à vérifier.”

10. UX premium

Style de la carte :
- fond sombre premium
- bordure fine orange/bleu
- icône AutoAwesome / Magic
- bouton principal orange ou bleu Take60
- TextField avec minLines 5, maxLines 16
- helper text :
  “Exemple : titre, catégorie, dialogue, prompt VEO et timeline JSON.”

Ajouter un petit résumé après import :
- “12 champs détectés”
- “Timeline JSON détectée”
- “Prompt VEO détecté”
- “Dialogue détecté”

11. Bouton exemple

Ajouter un bouton discret :
“Insérer exemple police”

Quand on clique, remplir importPromptCtrl avec un exemple court mais complet :
- titre
- catégorie
- dialogue
- prompt VEO
- timeline JSON

Ne pas mettre un exemple trop long dans le code si cela alourdit trop le fichier. Utiliser une constante privée `_kExamplePoliceScenePrompt`.

12. Sécurité

- Ne pas envoyer ce prompt à une API.
- Tout se fait localement dans l’admin.
- Pas de secret.
- Pas de nouvelle dépendance.

13. Tests / audit

Après implémentation :
- lancer flutter analyze
- corriger toutes les erreurs
- ajouter si possible un petit test unitaire du parseur si la structure du projet le permet
- sinon ne pas forcer les tests Firebase

====================================================
RÉSULTAT ATTENDU
====================================================

Dans la page admin “Ajout scène” :
- en haut, je peux coller un prompt complet comme le scénario “Interrogatoire sous tension”
- je clique “Remplir automatiquement”
- les champs se remplissent :
  - titre
  - catégorie
  - genre
  - type
  - difficulté
  - durée
  - lieu
  - logline
  - synopsis
  - personnage
  - texte/dialogue étape 7
  - consignes
  - rythme
  - prompt VEO
  - timeline JSON
  - mots-clés
- je peux ensuite générer VEO
- je peux enregistrer en brouillon
- je peux publier
- flutter analyze = No issues found

À la fin, donne :
1. fichiers modifiés
2. fonctions ajoutées
3. mapping exact des sections vers controllers
4. résultat flutter analyze
