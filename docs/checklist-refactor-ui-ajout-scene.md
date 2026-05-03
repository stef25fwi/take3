# Checklist — Refonte UI/UX admin « Ajout scène »

Fichier cible : [take30/lib/admin/take30_admin_scene_flow.dart](../take30/lib/admin/take30_admin_scene_flow.dart)

Objectif : vérifier que la page admin « Ajout scène » devient un parcours plus clair, premium, rapide à utiliser et moins intimidant, sans casser les données ni les fonctionnalités existantes.

## 0. Contraintes de sécurité à respecter

- [ ] Aucun champ existant supprimé
- [ ] Aucun contrôleur existant cassé ou remplacé inutilement
- [ ] Aucun mock utilisé à la place de l’admin réel
- [ ] Modèle de données inchangé, sauf nécessité mineure justifiée
- [ ] Parsing de prompt scénario conservé
- [ ] Dictée vocale speech-to-text conservée
- [ ] Génération VEO / vidéo IA conservée
- [ ] Timeline Take60 conservée
- [ ] Preview finale conservée
- [ ] Statuts conservés : brouillon / en attente / publié
- [ ] Style premium préservé
- [ ] Hiérarchie visuelle améliorée
- [ ] Actions plus claires
- [ ] `flutter analyze` passe sans issue

## 1. Structure globale en 4 étapes

- [ ] La page n’est plus présentée comme un seul long formulaire linéaire
- [ ] La page affiche 4 étapes visibles :
  - [ ] Étape 1 — Base de la scène
  - [ ] Étape 2 — Jeu et texte
  - [ ] Étape 3 — Enrichissements avancés
  - [ ] Étape 4 — Vérification et sortie
- [ ] Un composant de progression est visible en haut de page
- [ ] Le composant de progression affiche le numéro de chaque étape
- [ ] Le composant de progression affiche le titre de chaque étape
- [ ] Le composant de progression indique l’état : à faire / en cours / complété / incomplet
- [ ] La navigation par étapes fonctionne sur mobile
- [ ] La navigation par étapes fonctionne sur desktop
- [ ] Le header affiche `Créer une scène`
- [ ] Le header affiche `Complétez les informations essentielles, puis enrichissez la scène si nécessaire.`
- [ ] Le badge de statut courant est visible : Brouillon / En attente de validation / Publié

## 2. Étape 1 — Base de la scène

### Structure

- [ ] L’étape affiche `Import rapide de scénario`
- [ ] L’étape affiche `Informations générales`
- [ ] L’étape affiche `Identité du personnage`
- [ ] L’étape affiche `Contexte immédiat de la scène`

### Import rapide de scénario

- [ ] Le titre `Importer un prompt scénario` est remplacé par `Import rapide de scénario`
- [ ] Le texte d’aide est présent : `Vous avez déjà un scénario complet ? Collez-le ici pour préremplir automatiquement la fiche.`
- [ ] Le champ prompt complet est conservé
- [ ] Le bouton coller / masquer le prompt complet est conservé
- [ ] Le bouton `Remplir automatiquement` est conservé
- [ ] Le bouton `Effacer le prompt` est conservé
- [ ] Le bouton `Insérer exemple police` est conservé
- [ ] Le résumé d’import est conservé
- [ ] La détection de timeline JSON est conservée
- [ ] La détection de prompt VEO est conservée
- [ ] La détection de dialogue est conservée
- [ ] Le prompt VEO n’écrase pas une vidéo déjà validée
- [ ] Les messages d’import sont compréhensibles par un admin non technique
- [ ] Message possible : `Import terminé : X champs ont été préremplis.`
- [ ] Message possible : `Timeline détectée et ajoutée.`
- [ ] Message possible : `Prompt vidéo IA détecté.`
- [ ] Message possible : `Prompt vidéo IA ignoré : une vidéo est déjà validée pour cette scène.`
- [ ] Message possible : `Timeline ignorée : le format n’est pas valide.`

### Informations générales

- [ ] `Titre du projet` conservé
- [ ] `Nom de la scène` conservé
- [ ] `Catégorie` conservé
- [ ] `Genre` conservé
- [ ] `Niveau recommandé` conservé
- [ ] `Numéro de scène / prise` conservé
- [ ] `Date du tournage` conservé
- [ ] `Lieu` conservé
- [ ] `Réalisateur / direction d’acteur` conservé
- [ ] `Durée visée` conservé
- [ ] `Nom de la scène` marqué `Requis`
- [ ] `Catégorie` marqué `Recommandé`
- [ ] `Genre` marqué `Recommandé`
- [ ] `Niveau recommandé` marqué `Recommandé`
- [ ] `Durée visée` marqué `Recommandé`

### Identité du personnage

- [ ] `Nom du personnage` conservé
- [ ] `Âge apparent` conservé
- [ ] `Genre du personnage` conservé
- [ ] `Profil / rôle` conservé
- [ ] `Lien avec les autres personnages` conservé
- [ ] `État au début de la scène` conservé
- [ ] `Résumé personnage en 1 phrase` conservé
- [ ] `Nom du personnage` marqué `Requis`
- [ ] `Profil / rôle` marqué `Recommandé`
- [ ] `État au début` marqué `Recommandé`
- [ ] `Résumé personnage` marqué `Recommandé`

### Contexte immédiat

- [ ] `Ce qu’il vient de se passer juste avant` conservé
- [ ] `Où nous sommes` conservé
- [ ] `Avec qui` conservé
- [ ] `Pourquoi ce moment est important` conservé
- [ ] `Résumé du contexte en 2 lignes` conservé
- [ ] `Résumé du contexte` marqué `Requis`
- [ ] `Où nous sommes` marqué `Recommandé`
- [ ] `Pourquoi ce moment est important` marqué `Recommandé`

### Validation étape 1

- [ ] Passage à l’étape 2 vérifie nom de scène ou titre projet
- [ ] Passage à l’étape 2 vérifie nom du personnage
- [ ] Passage à l’étape 2 vérifie contexte minimal
- [ ] Les champs manquants ne bloquent pas brutalement
- [ ] Une alerte douce est affichée : `Il manque encore quelques informations essentielles pour créer une scène exploitable.`

## 3. Étape 2 — Jeu et texte

### Structure

- [ ] L’étape affiche `Objectif de jeu`
- [ ] L’étape affiche `Direction émotionnelle`
- [ ] L’étape affiche `Ton et style de jeu`
- [ ] L’étape affiche `Texte`
- [ ] L’étape affiche `Intentions par bloc`
- [ ] La section `Texte` est visuellement prioritaire

### Objectif de jeu

- [ ] `Objectif principal du personnage` conservé
- [ ] `Obstacle principal` conservé
- [ ] `Enjeu` conservé
- [ ] `Objectif principal` marqué `Requis`
- [ ] `Obstacle principal` marqué `Recommandé`
- [ ] `Enjeu` marqué `Recommandé`

### Direction émotionnelle

- [ ] `Émotion dominante` conservé
- [ ] `Émotion secondaire` conservé
- [ ] `Niveau d’intensité` conservé
- [ ] `Évolution émotionnelle — début` conservé
- [ ] `Évolution émotionnelle — milieu` conservé
- [ ] `Évolution émotionnelle — fin` conservé
- [ ] `Nuance importante` conservé
- [ ] Phrase de bénéfice affichée : `Aide l’acteur à comprendre l’évolution émotionnelle de la scène.`
- [ ] `Émotion dominante` marqué `Requis` ou `Recommandé fort`
- [ ] `Émotion secondaire` marqué `Recommandé`
- [ ] `Intensité` marqué `Recommandé`
- [ ] Évolution début / milieu / fin marquée `Avancé`

### Ton et style de jeu

- [ ] Sélecteur multi-styles conservé
- [ ] `Consigne de jeu` conservé
- [ ] `Références éventuelles` conservé
- [ ] Phrase de bénéfice affichée : `Définit le style de jeu attendu : naturel, intense, cinéma, série ou réseaux sociaux.`
- [ ] Style principal marqué `Recommandé`
- [ ] Consigne de jeu marquée `Recommandé`
- [ ] Références marquées `Avancé`

### Texte

- [ ] `Type de texte` conservé
- [ ] Champ dialogue / monologue conservé
- [ ] Micro intégré conservé
- [ ] États speech-to-text conservés
- [ ] `Mots ou phrases à accentuer` conservé
- [ ] `Mot / phrase clé à ne pas manquer` conservé
- [ ] La section texte utilise une carte plus visible
- [ ] La section texte utilise un titre plus fort
- [ ] La section texte porte un badge `Requis`
- [ ] Le champ texte est plus grand ou visuellement prioritaire
- [ ] Le micro est plus visible
- [ ] Le champ `Dialogue / monologue` est renommé `Texte à jouer`
- [ ] Sous-texte ajouté : `Écrivez le dialogue, le monologue ou les consignes d’improvisation.`
- [ ] Tooltip ou label micro : `Dicter le texte`

### Speech-to-text

- [ ] Message préparation : `Préparation du micro…`
- [ ] Message écoute : `Écoute en cours… parlez maintenant.`
- [ ] Message succès : `Texte ajouté depuis la dictée.`
- [ ] Message erreur : `La dictée n’a pas fonctionné. Vérifiez l’autorisation micro ou réessayez.`
- [ ] La logique existante de dictée vocale n’est pas cassée

### Intentions par bloc

- [ ] Les 3 blocs sont conservés
- [ ] Bloc `0:00 à 0:20` conservé
- [ ] Bloc `0:20 à 0:40` conservé
- [ ] Bloc `0:40 à 1:00` conservé
- [ ] Chaque bloc conserve `Intention`
- [ ] Chaque bloc conserve `Énergie`
- [ ] Chaque bloc conserve `Regard`
- [ ] Chaque bloc conserve `Rythme`
- [ ] La section est repliée par défaut
- [ ] Titre cible : `Affiner le jeu minute par minute`
- [ ] Phrase de bénéfice : `Permet de guider la progression de l’acteur sur les 60 secondes.`
- [ ] Badge `Avancé`

### Validation étape 2

- [ ] Passage à l’étape 3 ou 4 vérifie objectif principal
- [ ] Passage à l’étape 3 ou 4 vérifie texte à jouer
- [ ] Émotion dominante absente affiche un avertissement si nécessaire

## 4. Étape 3 — Enrichissements avancés

### Structure

- [ ] L’étape est clairement présentée comme optionnelle ou avancée
- [ ] Titre : `Enrichissements avancés`
- [ ] Sous-titre : `Ajoutez les consignes de tournage, la vidéo IA et la timeline Take60 si nécessaire.`
- [ ] Sous-groupe repliable `Direction de tournage`
- [ ] Sous-groupe repliable `Intention finale`
- [ ] Sous-groupe repliable `Enrichissements IA`

### Direction de tournage

- [ ] Phrase de bénéfice : `Ces informations aident à rendre la scène plus claire à tourner et plus cohérente à l’écran.`
- [ ] `Actions physiques` inclus
- [ ] `Regard / caméra` inclus
- [ ] `Rythme et respiration` inclus
- [ ] `Repères techniques` inclus
- [ ] Tous les champs de ces sections sont conservés
- [ ] Chaque section est marquée `Avancé`

### Intention finale

- [ ] Phrase de bénéfice : `Ces champs aident à vérifier que la scène produit le bon effet émotionnel.`
- [ ] `Ce que doit ressentir le spectateur` inclus
- [ ] `Note finale du réalisateur` inclus
- [ ] `À la fin de la minute, le spectateur doit ressentir...` conservé
- [ ] `Vision globale de la scène` conservé
- [ ] Ces sections sont marquées `Recommandé`

### Enrichissements IA

- [ ] Phrase de bénéfice : `Ajoutez une vidéo d’introduction et une timeline guidée pour enrichir l’expérience Take60.`
- [ ] Section vidéo IA incluse
- [ ] Section montage guidé Take60 incluse

## 5. Vidéo IA / VEO

- [ ] Titre cible : `Vidéo IA d’introduction`
- [ ] Sous-titre : `Créez une courte vidéo d’ambiance qui introduit la scène avant la prise utilisateur.`
- [ ] `Prompt VEO3` renommé `Prompt vidéo IA`
- [ ] `Valider et générer la preview` remplacé par `Tester la vidéo IA`
- [ ] `Corriger le prompt` remplacé par `Modifier le prompt`
- [ ] `Valider cette vidéo` remplacé par `Utiliser cette vidéo pour la scène`
- [ ] `Régénérer la vidéo` remplacé par `Tester une nouvelle version`
- [ ] Workflow visible en 3 étapes : écrire le prompt / tester / utiliser
- [ ] Statut unique visible : aucun prompt vidéo
- [ ] Statut unique visible : prompt prêt à tester
- [ ] Statut unique visible : génération en cours
- [ ] Statut unique visible : preview générée
- [ ] Statut unique visible : vidéo validée
- [ ] Statut unique visible : erreur de génération
- [ ] Aide longue repliée par défaut
- [ ] Titre aide : `Conseils pour un bon prompt vidéo IA`
- [ ] Contenu aide VEO conservé
- [ ] Exemple compact visible avec titre `Exemple court`
- [ ] Exemple compact : `Plan large nocturne d’un commissariat, lumière froide, ambiance tendue, caméra lente vers une porte entrouverte, fin sur un couloir silencieux.`
- [ ] Brouillon autorisé sans vidéo IA validée si logique métier actuelle le permet
- [ ] Publication bloquée si vidéo IA requise et non validée
- [ ] Message publication bloquée : `Vous devez valider une vidéo IA avant de publier cette scène.`

## 6. Timeline Take60

- [ ] Titre renommé `Montage guidé Take60`
- [ ] Sous-titre : `Organisez l’alternance entre vidéo IA et jeu utilisateur sur 60 secondes.`
- [ ] Mode simple créé
- [ ] Mode avancé créé
- [ ] Mode simple visible par défaut
- [ ] Mode simple affiche résumé de la timeline actuelle
- [ ] Mode simple affiche durée totale
- [ ] Mode simple affiche nombre de plans
- [ ] Mode simple affiche alerte si dépassement 60 s
- [ ] Bouton principal : `Créer une timeline 60 s automatiquement`
- [ ] JSON non affiché comme expérience principale
- [ ] Mode avancé affiche l’éditeur complet existant
- [ ] Bouton `Ajouter un plan IA` renommé `Ajouter un plan vidéo IA`
- [ ] Bouton `Ajouter un plan utilisateur` renommé `Ajouter un plan acteur`
- [ ] Bouton `Insérer un modèle 60 s` renommé `Créer une timeline 60 s automatiquement`
- [ ] Message JSON affiché uniquement en mode avancé
- [ ] Message JSON : `La timeline est enregistrée en JSON automatiquement. Modifiez-la uniquement si vous savez ce que vous faites.`
- [ ] Timeline vide ne bloque pas le brouillon
- [ ] Timeline invalide bloque preview, génération finale et publication
- [ ] Message timeline invalide : `La timeline contient une erreur. Corrigez-la ou revenez au modèle automatique 60 s.`

## 7. Étape 4 — Vérification et sortie

- [ ] Titre : `Vérification et sortie`
- [ ] Sous-titre : `Vérifiez la scène avant de choisir son statut final.`
- [ ] Preview scène conservée
- [ ] Boutons de correction conservés
- [ ] Choix du statut cible conservé
- [ ] Actions finales conservées mais clarifiées
- [ ] `Modifier les informations` devient `Revenir à la fiche scène`
- [ ] `Modifier le prompt VEO3` devient `Modifier la vidéo IA`
- [ ] `Régénérer la vidéo` devient `Tester une nouvelle vidéo IA`
- [ ] `Enregistrer en brouillon` devient `Enregistrer le brouillon`
- [ ] `Envoyer en attente de publication` devient `Envoyer pour validation`
- [ ] `Publier` devient `Publier maintenant`
- [ ] Choix `Brouillon` affiche une description
- [ ] Choix `En attente de validation` affiche une description
- [ ] Choix `Publié` affiche une description
- [ ] Une seule action primaire finale est visible
- [ ] L’action primaire finale change selon le statut sélectionné

## 8. Footer contextuel

- [ ] Ancienne ambiguïté `Brouillon` / `Générer la scène` supprimée
- [ ] Footer contextuel unique créé
- [ ] Étapes 1 à 3 : bouton secondaire `Enregistrer le brouillon`
- [ ] Étapes 1 à 3 : bouton primaire `Continuer`
- [ ] Étape 4 : bouton secondaire `Revenir`
- [ ] Étape 4 : bouton primaire dépend du statut choisi
- [ ] Le libellé `Générer la scène` n’apparaît plus de manière ambiguë

## 9. Badges requis / recommandé / avancé

- [ ] Widget réutilisable `_FieldRequirementBadge` créé ou équivalent existant
- [ ] Type `required` présent
- [ ] Type `recommended` présent
- [ ] Type `advanced` présent
- [ ] Libellé `Requis` présent
- [ ] Libellé `Recommandé` présent
- [ ] Libellé `Avancé` présent
- [ ] Style discret et lisible
- [ ] Compatible clair / sombre ou au minimum lisible dans le thème actuel
- [ ] Badges utilisés dans les titres de sections
- [ ] Badges utilisés sur les labels de champs importants si possible
- [ ] Badges présents dans le résumé latéral desktop si pertinent

## 10. Résumé latéral desktop

- [ ] Le menu latéral ne liste plus seulement les sections
- [ ] Étape courante affichée
- [ ] Progression globale affichée
- [ ] Champs requis manquants affichés
- [ ] Statut vidéo IA affiché
- [ ] Statut timeline affiché
- [ ] Statut de sortie choisi affiché
- [ ] Raccourci vers preview affiché
- [ ] Sur mobile, le menu latéral complet n’est pas affiché
- [ ] Sur mobile, le stepper compact reste disponible en haut

## 11. Messages d’erreur et de succès

- [ ] Champs requis manquants : `Ajoutez un nom de scène, un personnage et un texte à jouer avant de continuer.`
- [ ] Timeline invalide : `La timeline contient une erreur. Corrigez-la ou recréez un modèle automatique 60 s.`
- [ ] Vidéo IA manquante : `Vous devez valider une vidéo IA avant de publier cette scène.`
- [ ] Import partiel : `Le prompt a été importé partiellement. Certains champs n’ont pas été reconnus.`
- [ ] Vidéo déjà validée : `Le prompt vidéo IA importé n’a pas remplacé la vidéo déjà validée.`
- [ ] Dictée vocale erreur : `La dictée n’a pas fonctionné. Vérifiez l’autorisation micro ou réessayez.`
- [ ] Brouillon : `Brouillon enregistré.`
- [ ] Validation : `Scène envoyée pour validation.`
- [ ] Publication : `Scène publiée.`

## 12. Validations produit

- [ ] Validation progressive implémentée
- [ ] Continuer depuis étape 1 vérifie nom scène ou titre projet
- [ ] Continuer depuis étape 1 vérifie personnage
- [ ] Continuer depuis étape 1 vérifie contexte minimal
- [ ] Continuer depuis étape 2 vérifie objectif principal
- [ ] Continuer depuis étape 2 vérifie texte à jouer
- [ ] Continuer depuis étape 2 avertit si émotion dominante absente
- [ ] Brouillon autorisé même partiel
- [ ] Brouillon affiche les champs manquants si nécessaire
- [ ] Envoi validation vérifie champs requis
- [ ] Envoi validation vérifie timeline si présente
- [ ] Publication vérifie champs requis complets
- [ ] Publication vérifie timeline valide si présente
- [ ] Publication vérifie vidéo IA validée si requise
- [ ] Publication silencieuse impossible avec timeline invalide
- [ ] Publication silencieuse impossible avec vidéo IA requise absente
- [ ] Publication silencieuse impossible avec texte vide
- [ ] Publication silencieuse impossible avec personnage vide

## 13. Design UI premium

- [ ] Cartes plus aérées
- [ ] Titres plus courts
- [ ] Sous-titres explicatifs
- [ ] Badges discrets
- [ ] Sections avancées repliées ou moins intimidantes
- [ ] CTA plus clairs
- [ ] Densité réduite au premier affichage
- [ ] Meilleure séparation création rapide / options expertes
- [ ] Sections critiques visuellement mises en avant
- [ ] Mobile : pas trop de colonnes
- [ ] Mobile : champs confortables
- [ ] Mobile : footer non intrusif
- [ ] Mobile : stepper compact
- [ ] Desktop : résumé latéral utile
- [ ] Desktop : largeur de formulaire lisible

## 14. Ordre technique recommandé

- [ ] Identifier toutes les méthodes/widgets des sections 0 à 16
- [ ] Ne pas supprimer leur contenu
- [ ] Créer `_currentStep` ou équivalent
- [ ] Créer `_AdminSceneStep` ou structure équivalente
- [ ] Créer `_SceneCreationStepper` ou équivalent
- [ ] Créer `_FieldRequirementBadge` ou équivalent
- [ ] Créer `_ContextualActionFooter` ou équivalent
- [ ] Regrouper les sections dans `_buildBaseSceneStep()` ou équivalent
- [ ] Regrouper les sections dans `_buildActingAndTextStep()` ou équivalent
- [ ] Regrouper les sections dans `_buildAdvancedEnrichmentsStep()` ou équivalent
- [ ] Regrouper les sections dans `_buildReviewAndPublishStep()` ou équivalent
- [ ] Créer ou améliorer `_validateBaseStep()` ou équivalent
- [ ] Créer ou améliorer `_validateActingStep()` ou équivalent
- [ ] Créer ou améliorer `_validateTimelineIfPresent()` ou équivalent
- [ ] Créer ou améliorer `_validateBeforePublish()` ou équivalent
- [ ] Renommer les CTA
- [ ] Replier les sections avancées par défaut

## 15. Tests à exécuter

- [ ] `flutter analyze`
- [ ] Test sauvegarde brouillon
- [ ] Test import prompt
- [ ] Test speech-to-text
- [ ] Test génération VEO
- [ ] Test validation vidéo
- [ ] Test timeline simple
- [ ] Test timeline avancée
- [ ] Test preview finale
- [ ] Test envoi pour validation
- [ ] Test publication

## 16. Critères d’acceptation

- [ ] La page affiche clairement 4 étapes
- [ ] L’admin comprend immédiatement où il est
- [ ] Il peut enregistrer un brouillon sans remplir tous les champs avancés
- [ ] Les champs requis sont visibles
- [ ] Les sections avancées sont repliées ou moins intimidantes
- [ ] Le bouton `Générer la scène` n’apparaît plus de manière ambiguë
- [ ] Une seule action primaire est visible selon le contexte
- [ ] VEO est compréhensible en 3 étapes : écrire, tester, utiliser
- [ ] La timeline propose un mode simple par défaut
- [ ] Le JSON n’est pas exposé comme expérience principale
- [ ] La preview finale reste fidèle aux données saisies
- [ ] La publication est bloquée si une condition critique manque
- [ ] Aucun champ métier existant n’est perdu
- [ ] Le code passe `flutter analyze`

## 17. Livrable final attendu

- [ ] Modifier directement [take30/lib/admin/take30_admin_scene_flow.dart](../take30/lib/admin/take30_admin_scene_flow.dart)
- [ ] Ajouter seulement des helpers/widgets internes si possible
- [ ] Ne pas créer de gros système externe sans nécessité
- [ ] Fournir un résumé des changements effectués
- [ ] Fournir les fichiers modifiés
- [ ] Fournir les commandes de test à lancer
- [ ] Lister les éventuels points non traités