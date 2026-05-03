# Audit UI/UX — Page Admin « Ajout scène »

Source de vérité code :
- [take30/lib/admin/take30_admin_scene_flow.dart](/workspaces/take3/take30/lib/admin/take30_admin_scene_flow.dart)

Objectif du document :
- lister tout le contenu visible de la page
- expliciter la fonction attendue de chaque section
- fournir une base de contrôle pour un audit UI/UX complet côté admin utilisateur

## Portée de la page

La page « Ajout scène » est un formulaire admin long, structuré en :
- une carte d’import de prompt scénario
- 16 sections principales, dont une section 15bis pour la timeline dialoguée
- une barre d’actions fixe en bas
- un menu latéral d’aide à la navigation sur grand écran

Le comportement attendu couvre :
- création et édition d’une scène
- enrichissement automatique depuis un prompt scénario complet
- dictée vocale du texte
- génération et validation d’une vidéo IA d’introduction
- édition d’une timeline Take60
- prévisualisation finale avant brouillon / attente / publication

## Navigation et structure globale

### Menu latéral desktop
Contenu attendu :
- liste des sections 1 à 16
- repère visuel de navigation sur grand écran

Fonction attendue :
- aider l’utilisateur à comprendre la progression du formulaire
- refléter l’architecture réelle de la page

Points d’audit :
- cohérence entre les intitulés du menu et les intitulés des cartes
- lisibilité du sommaire
- utilité réelle pour les écrans larges

### Scroll principal
Contenu attendu :
- page en `ListView` verticale
- cartes espacées et scannables

Fonction attendue :
- permettre un remplissage séquentiel sans rupture visuelle
- garder les actions critiques accessibles via la barre fixe basse

Points d’audit :
- densité de contenu
- clarté des transitions entre sections
- charge cognitive sur mobile

## Bloc 0 — Importer un prompt scénario

### Contenu visible
- titre : `Importer un prompt scénario`
- sous-titre : collage d’un scénario complet Take60 pour préremplir la fiche
- bouton d’expansion / réduction
- bouton `Coller un prompt complet` / `Masquer le prompt complet`
- grand champ `Prompt scénario complet`
- bouton `Remplir automatiquement`
- bouton `Effacer le prompt`
- bouton `Insérer exemple police`
- résumé après import avec chips :
  - nombre de champs détectés
  - timeline JSON détectée
  - prompt VEO détecté
  - prompt VEO non importé
  - dialogue détecté
- message persistant si prompt VEO ignoré car vidéo déjà validée

### Fonction attendue
- permettre le collage d’un prompt complet externe
- parser proprement les sections du prompt
- hydrater les champs compatibles du formulaire
- ne jamais casser les données déjà validées côté VEO
- ignorer les timelines invalides au lieu de polluer le formulaire

### Points d’audit
- clarté du wording pour un admin non technique
- feedback après import suffisamment explicite
- distinction claire entre import réussi, partiel, ou ignoré
- visibilité des cas bloquants : VEO verrouillé, timeline invalide

## 1) Informations générales

### Contenu
- `Titre du projet`
- `Nom de la scène`
- `Catégorie`
- `Genre`
- dropdown `Niveau recommandé`
  - débutant
  - intermédiaire
  - confirmé
  - avancé
- `Numéro de scène / prise`
- `Date du tournage`
- `Lieu`
- `Réalisateur / direction d’acteur`
- `Durée visée`

### Fonction attendue
- définir l’identité éditoriale de la scène
- fournir les métadonnées minimales pour classement, filtrage et affichage

### Points d’audit
- priorisation des champs requis
- cohérence entre `Titre du projet` et `Nom de la scène`
- compréhension du `Niveau recommandé`

## 2) Identité du personnage

### Contenu
- `Nom du personnage`
- `Âge apparent`
- `Genre du personnage`
- `Profil / rôle`
- `Lien avec les autres personnages`
- `État au début de la scène`
- `Résumé personnage en 1 phrase`

### Fonction attendue
- poser les bases de jeu et de casting
- contextualiser la voix, l’énergie et la posture du personnage

### Points d’audit
- clarté entre identité, rôle et état émotionnel
- suffisance des champs pour un acteur ou un réalisateur

## 3) Contexte immédiat de la scène

### Contenu
- `Ce qu’il vient de se passer juste avant`
- `Où nous sommes`
- `Avec qui`
- `Pourquoi ce moment est important`
- `Résumé du contexte en 2 lignes`

### Fonction attendue
- donner le contexte de jeu immédiat
- éviter une scène isolée sans tension narrative

### Points d’audit
- redondance éventuelle entre les champs
- lisibilité de la progression narrative

## 4) Objectif de jeu

### Contenu
- dropdown `Objectif principal du personnage`
  - convaincre
  - séduire
  - se défendre
  - cacher sa peur
  - cacher la vérité
  - récupérer la confiance
  - impressionner
  - faire rire
  - dominer la situation
  - demander pardon
  - retenir quelqu’un
- `Obstacle principal`
- `Enjeu`

### Fonction attendue
- cadrer l’intention dramatique principale
- forcer l’identification d’un obstacle et d’un enjeu concrets

### Points d’audit
- précision des objectifs disponibles
- utilité de la liste versus un champ libre
- articulation claire objectif / obstacle / enjeu

## 5) Direction émotionnelle

### Contenu
- dropdown `Émotion dominante`
- dropdown `Émotion secondaire`
- dropdown `Niveau d’intensité`
- `Évolution émotionnelle — début`
- `Évolution émotionnelle — milieu`
- `Évolution émotionnelle — fin`
- `Nuance importante`

Options émotion dominante / secondaire :
- colère
- colère contenue
- tristesse
- peur
- joie
- détermination
- fragilité
- tension
- stress
- admiration
- honte
- doute
- espoir

Intensité :
- faible
- moyen
- fort
- progressif

### Fonction attendue
- structurer l’arc émotionnel du jeu
- éviter une performance plate ou monotone

### Points d’audit
- valeur réelle de l’émotion secondaire
- compréhension des transitions début / milieu / fin

## 6) Ton et style de jeu

### Contenu
- sélecteur de styles recherchés
  - très naturel
  - réaliste
  - sobre
  - intense
  - dramatique
  - pub / commercial
  - cinéma
  - série
  - réseaux sociaux
  - humoristique
  - élégant / premium
  - nerveux / tendu
  - minimaliste
- `Consigne de jeu`
- `Références éventuelles`

### Fonction attendue
- donner un cadre esthétique et performatif
- permettre des références de ton très explicites

### Points d’audit
- compréhension des différences entre style et émotion
- surcharge possible du sélecteur multi-choix

## 7) Texte

### Contenu
- dropdown `Type de texte`
  - texte exact à respecter
  - texte semi-libre
  - improvisation guidée
  - dialogue
- champ `Dialogue / monologue`
- bouton micro intégré dans le suffixe du champ
- états speech-to-text : préparation, écoute, succès, erreur
- `Mots ou phrases à accentuer`
- `Mot / phrase clé à ne pas manquer`

### Fonction attendue
- centraliser le texte à jouer
- permettre la dictée vocale avec permission micro, écoute et retour d’état
- enrichir l’interprétation avec accents et points de vigilance

### Points d’audit
- visibilité et compréhension du micro
- clarté du feedback speech-to-text
- distinction texte principal / mots accentués / phrase clé

## 8) Intentions par bloc

### Contenu
- bloc 1 — 0:00 à 0:20
  - `Intention`
  - `Énergie`
  - `Regard`
  - `Rythme`
- bloc 2 — 0:20 à 0:40
  - mêmes champs
- bloc 3 — 0:40 à 1:00
  - mêmes champs

### Fonction attendue
- découper la minute en trois temps jouables
- guider précisément la montée ou variation de la performance

### Points d’audit
- utilité perçue de ce niveau de granularité
- facilité de compréhension temporelle

## 9) Actions physiques

### Contenu
- `Position de départ`
- `Déplacement prévu`
- `Gestes autorisés / attendus`
- `Objets utilisés`
- `Moment précis d’une action importante`
- `Consigne corporelle`

### Fonction attendue
- cadrer le corps en plus du texte
- limiter les incohérences de mouvement au tournage

### Points d’audit
- niveau de détail utile versus trop directif
- cohérence avec cadrage / caméra

## 10) Regard / caméra

### Contenu
- dropdown `Type de cadrage`
  - gros plan
  - plan rapproché
  - plan poitrine
  - plan taille
  - plan américain
  - plan large
- dropdown `Rapport caméra`
  - face caméra
  - légèrement hors caméra
  - scène dialoguée
  - regard interdit caméra
- `Point de regard`
- `Consigne visage`

### Fonction attendue
- expliciter l’intention cadre / axe / regard
- aider au tournage ou à l’auto-enregistrement

### Points d’audit
- clarté de `Rapport caméra`
- redondance avec actions physiques et direction de jeu

## 11) Rythme et respiration

### Contenu
- dropdown `Tempo global`
  - lent
  - lent puis instable
  - posé
  - fluide
  - nerveux
  - progressif
  - punchy
- `Silences à garder`
- `Montée dramatique`

### Fonction attendue
- encadrer le débit, le souffle, les ruptures et la tension

### Points d’audit
- articulation entre tempo global et blocs 8

## 12) Repères techniques

### Contenu
- `Marque au sol / position`
- `Top départ`
- `Signal de mouvement`
- `Moment exact de fin`
- `Durée idéale du texte`
- `Contraintes son / lumière / cadre`

### Fonction attendue
- transformer la scène en consignes tournables
- anticiper les contraintes de plateau ou d’enregistrement maison

### Points d’audit
- clarté opérationnelle pour un acteur seul
- niveau de jargon technique acceptable

## 13) Ce que doit ressentir le spectateur

### Contenu
- `À la fin de la minute, le spectateur doit ressentir...`

### Fonction attendue
- recentrer toute la scène sur l’effet produit, pas seulement sur l’exécution

### Points d’audit
- visibilité de cette intention dans la hiérarchie de page

## 14) Note finale du réalisateur

### Contenu
- `Vision globale de la scène`

### Fonction attendue
- synthèse libre, plus qualitative, de l’intention générale

### Points d’audit
- doit-elle apparaître plus tôt ou rester en synthèse finale ?

## 15) Vidéo IA d’introduction

### Contenu
- texte explicatif sur le rôle de la vidéo IA
- champ `Prompt VEO3`
- bloc `Exemple de prompt`
- bloc `Aide prompt VEO3` avec règles :
  - 15 secondes recommandées
  - format 16:9
  - décrire décor, ambiance, lumière, mouvement de caméra, raccord final
  - éviter visages identifiables, texte à l’image, logos
  - vidéo IA pensée comme introduction émotionnelle
- chips de statut VEO et d’opération si présents
- historique de prompts testés ré-injectables
- panneau succès / erreur / statut
- bouton `Valider et générer la preview`
- si preview générée :
  - composant de preview vidéo admin
  - bouton `Corriger le prompt`
  - bouton `Valider cette vidéo`

### Fonction attendue
- créer et piloter la vidéo IA d’introduction
- verrouiller le prompt si nécessaire
- distinguer génération, correction et validation finale

### Points d’audit
- compréhension du rôle exact de la vidéo IA
- lisibilité du statut VEO
- pertinence du wording `Valider et générer la preview`
- friction entre test, correction, validation

## 15bis) Montage automatique dialogué (timeline Take 60)

### Contenu
- texte explicatif sur la timeline guidée
- éditeur visuel de timeline
- message helper : `Le champ timeline doit contenir uniquement un tableau JSON : [ ... ].`

Éditeur timeline — contenu fonctionnel visible attendu :
- état vide avec message d’aide
- lignes de marqueurs réordonnables et supprimables
- durée totale affichée sur 60 secondes
- alerte si dépassement
- compteur de plans
- bouton `Ajouter un plan IA`
- bouton `Ajouter un plan utilisateur`
- bouton `Insérer un modèle 60 s`

Types de plans pris en charge :
- intro cinéma (IA)
- réplique IA
- réponse IA
- réaction IA
- plan réaction
- transition
- conclusion IA
- plan final IA
- intro utilisateur
- réplique utilisateur
- réponse utilisateur
- émotion utilisateur
- action silencieuse utilisateur
- plan rapproché (utilisateur)
- plan moyen (utilisateur)
- sur-épaule (utilisateur)

### Fonction attendue
- construire une alternance IA / utilisateur sur 60 secondes maximum
- persister la timeline en JSON propre
- proposer un template rapide réutilisable

### Points d’audit
- complexité de l’éditeur
- compréhension immédiate des types de plans
- lisibilité mobile
- cohérence avec la preview finale

## 16) Prévisualisation de la page détail de scène

### Contenu
- texte explicatif sur la prévisualisation admin
- composant `_SceneDetailPreview` alimenté par les données courantes du formulaire
- bouton `Modifier les informations`
- bouton `Modifier le prompt VEO3`
- bouton `Régénérer la vidéo`
- choix du statut cible avec `ChoiceChip` :
  - Brouillon
  - En attente de publication
  - Publié
- CTA de publication :
  - `Enregistrer en brouillon`
  - `Envoyer en attente de publication`
  - `Publier`

### Fonction attendue
- vérifier l’affichage final avant persistance
- permettre un dernier aller-retour vers les sections critiques
- contrôler l’état de publication avant enregistrement final

### Points d’audit
- la preview reflète-t-elle vraiment le résultat final ?
- les CTA de fin sont-ils assez distincts ?
- le statut cible est-il compréhensible sans formation ?

## Barre d’actions fixe basse

### Contenu
- bouton `Brouillon`
- bouton `Générer la scène`

### Fonction attendue
- garder les deux actions majeures toujours accessibles
- offrir un chemin rapide sans remonter en haut de page

### Points d’audit
- risque de doublon avec les CTA de la section 16
- clarté entre `Générer la scène` et `Publier`

## États, validations et comportements transverses attendus

### Validation formulaire
- le formulaire doit refuser les champs critiques manquants
- la fiche acteur doit au minimum contenir un personnage et un texte
- la timeline JSON doit être valide avant preview / génération / sauvegarde
- la génération finale de scène exige une vidéo IA validée

### Import de prompt
- le parsing doit préremplir sans casser les données existantes sensibles
- un prompt VEO ne doit pas écraser une vidéo déjà validée
- une timeline invalide ne doit pas polluer `markersJson`

### Dictée vocale
- permission micro demandée proprement
- états visibles : préparation, écoute, succès, erreur
- arrêt/reprise clairs pour l’utilisateur

### VEO
- statuts visibles
- génération bloquée si timeline invalide
- erreurs backend transformées en messages intelligibles côté admin

### Preview et publication
- preview cohérente avec les données courantes
- brouillon, attente et publication clairement séparés
- possibilité de revenir corriger les informations ou le prompt

## Checklist d’audit UX recommandée

### Clarté
- l’utilisateur comprend-il immédiatement la finalité de chaque section ?
- la hiérarchie visuelle aide-t-elle à prioriser ?

### Charge cognitive
- la longueur du formulaire est-elle supportable ?
- faut-il regrouper, replier ou scénariser davantage ?

### Feedback
- chaque action importante renvoie-t-elle un état clair ?
- les erreurs sont-elles actionnables ?

### Cohérence
- les termes scène / projet / preview / vidéo / génération / publication sont-ils cohérents partout ?
- les CTA fixes et les CTA de section 16 racontent-ils la même chose ?

### Mobile / desktop
- la page reste-t-elle praticable sur petit écran ?
- le menu latéral desktop apporte-t-il une vraie valeur ?

### Sécurité produit
- aucune action destructive ne doit arriver sans feedback clair
- aucun état VEO invalide ne doit pouvoir être publié par erreur

## Résultat attendu d’un audit complet

L’audit final devrait produire :
- une cartographie des sections trop denses
- une liste des termes ambigus ou redondants
- les CTA à fusionner, renommer ou repositionner
- les messages d’erreur / succès à clarifier
- les points de friction mobile et desktop
- les priorités de simplification du parcours admin

## Lecture produit — priorités UX déduites de la page actuelle

Cette section ne décrit plus seulement le contenu de la page. Elle formule une lecture produit du parcours tel qu’il est aujourd’hui, en priorisant les zones qui risquent de ralentir un admin réel.

### Synthèse exécutive
- la page veut résoudre trop de jobs à la fois dans un seul flux : saisie éditoriale, import intelligent, direction d’acteur, préparation tournage, montage timeline, génération VEO, preview, brouillon et publication
- la structure est complète, mais elle crée un coût cognitif élevé avant même que l’utilisateur comprenne quelles étapes sont vraiment obligatoires
- la plus forte friction probable n’est pas un manque d’information, mais un manque de hiérarchie entre les informations critiques, optionnelles et expertes

## Priorité 1 — Trop de décisions dans un seul écran

### Constats
- l’utilisateur traverse plus de 15 blocs avant d’arriver à la décision finale
- plusieurs blocs servent à enrichir la qualité, mais sont présentés avec le même poids visuel que les champs indispensables
- la page mélange données de base, enrichissements, éléments avancés et publication sans changement net de phase

### Risque produit
- abandon en cours de saisie
- remplissage partiel ou incohérent
- impression de complexité excessive pour un usage pourtant répétitif

### Recommandation
- regrouper le parcours en 4 phases explicites :
  - identité de scène
  - direction de jeu
  - enrichissements IA et timeline
  - vérification et publication
- afficher visuellement ce qui est requis pour créer une scène minimale exploitable
- replier par défaut les blocs experts ou secondaires

### Gain attendu
- baisse de la charge cognitive initiale
- meilleure vitesse de production pour les admins réguliers

## Priorité 2 — Ambiguïté des CTA finaux

### Constats
- la page possède une barre fixe basse avec `Brouillon` et `Générer la scène`
- la section 16 contient en plus `Enregistrer en brouillon`, `Envoyer en attente de publication` et `Publier`
- le mot `Générer` peut être compris comme : enregistrer, prévisualiser, publier, ou fabriquer la scène finale

### Risque produit
- erreur d’action au moment critique
- incompréhension entre sauvegarde, génération et publication
- manque de confiance dans le résultat final

### Recommandation
- renommer les actions selon leur effet exact
- éviter deux zones de fin qui semblent concurrentes
- adopter un système plus explicite du type :
  - `Enregistrer le brouillon`
  - `Préparer pour validation`
  - `Publier maintenant`
- si la barre fixe est conservée, elle doit contenir une seule action primaire contextuelle et une action secondaire stable

### Gain attendu
- réduction des erreurs de publication
- meilleure compréhension du statut final de la scène

## Priorité 3 — La section VEO concentre trop de complexité métier

### Constats
- la section 15 porte plusieurs usages en parallèle : apprendre le prompt, écrire le prompt, tester, corriger, relancer, lire un statut, valider la vidéo
- la terminologie suppose une compréhension implicite de VEO, preview, validation et verrouillage
- les feedbacks sont présents mais demandent un niveau d’attention élevé

### Risque produit
- blocage ou hésitation chez les admins peu techniques
- difficulté à savoir si la vidéo est optionnelle, recommandée ou obligatoire
- confusion entre `générer une preview`, `corriger`, `valider` et `régénérer`

### Recommandation
- transformer cette zone en mini workflow guidé en 3 étapes :
  - écrire ou importer le prompt
  - tester la vidéo
  - valider la vidéo choisie
- faire apparaître l’état courant de manière unique et très visible
- isoler les éléments d’aide avancée dans un panneau secondaire ou repliable

### Gain attendu
- meilleure compréhension de la logique VEO
- moins d’allers-retours improductifs

## Priorité 4 — La timeline dialoguée est puissante mais probablement trop experte

### Constats
- l’éditeur de timeline expose plusieurs types de plans, de durées, d’ordonnancement et de contraintes
- la logique est riche, mais l’entrée dans l’outil semble abrupte pour un admin qui veut juste créer une scène vite
- la présence d’un helper JSON reste nécessaire, ce qui signale une abstraction encore trop technique pour l’utilisateur final

### Risque produit
- peur de casser la scène
- non-utilisation de la fonctionnalité
- erreurs de configuration ou surcharge mentale en mobile

### Recommandation
- proposer deux modes clairs :
  - mode simple : template prêt à l’emploi, éditable légèrement
  - mode avancé : éditeur complet de marqueurs
- faire du template 60 s l’entrée recommandée
- masquer au maximum la dimension JSON dans l’expérience normale

### Gain attendu
- hausse d’adoption de la timeline
- baisse du sentiment d’outil technique

## Priorité 5 — Le formulaire distingue mal l’essentiel du premium

### Constats
- plusieurs champs améliorent fortement la qualité, mais ne sont pas tous nécessaires au premier passage
- aujourd’hui, le même niveau d’attention visuelle est donné à des champs critiques et à des champs de raffinement

### Risque produit
- l’utilisateur ne sait pas où mettre son énergie
- effort excessif pour produire une scène pourtant suffisante

### Recommandation
- catégoriser visuellement les champs :
  - requis
  - recommandé
  - avancé
- permettre un mode `création rapide` puis `raffinage`

### Gain attendu
- meilleure conversion de création
- meilleure qualité progressive au lieu d’une complexité imposée dès le départ

## Priorité 6 — Le bénéfice de certaines sections n’est pas immédiatement visible

### Constats
- plusieurs sections fines sont pertinentes pour la qualité de jeu, mais leur valeur n’est pas auto-évidente lors d’une première utilisation
- l’utilisateur peut percevoir certains blocs comme administratifs plutôt que comme utiles à la scène

### Risque produit
- saisie superficielle
- contenu répétitif ou générique

### Recommandation
- ajouter, pour certaines sections, une phrase de bénéfice orientée usage :
  - ce que cela améliore dans le jeu
  - ce que cela améliore dans la preview
  - ce que cela améliore pour la publication

### Gain attendu
- meilleure qualité des entrées
- moins de champs remplis mécaniquement

## Quick wins recommandés

- renommer `Générer la scène` si l’action sauvegarde ou publie plus qu’elle ne génère
- distinguer visuellement les blocs requis des blocs avancés
- replier par défaut l’aide VEO et certaines sections secondaires
- faire du template timeline 60 s l’entrée recommandée
- clarifier le statut de la vidéo IA : optionnelle, requise, ou requise pour certains cas
- fusionner ou clarifier les actions finales pour éviter la concurrence entre barre basse et section 16

## Refactor produit recommandé

### Version cible du parcours
1. Créer la base de la scène
2. Définir le jeu et le texte
3. Ajouter les enrichissements IA et timeline si nécessaire
4. Vérifier l’aperçu final
5. Choisir un statut de sortie clair

### Principe directeur
La page doit donner l’impression qu’une scène peut être créée rapidement, puis améliorée progressivement. Aujourd’hui, elle donne davantage l’impression qu’il faut tout comprendre avant de pouvoir terminer.

## Proposition concrète — nouvelle architecture de l’écran

Cette proposition décrit une version cible plus simple de la page, sans retirer la richesse métier existante. Le principe est de séparer clairement la création minimale d’une scène, les enrichissements, puis la validation finale.

## Vue d’ensemble de l’écran cible

### Structure générale proposée
- un header fixe léger avec titre, statut courant et actions de sauvegarde
- un parcours en 4 étapes visibles
- des sections repliables avec progression
- une seule zone d’action principale persistante

### Étapes proposées
1. Base de la scène
2. Jeu et texte
3. Enrichissements avancés
4. Vérification et sortie

### Comportement général attendu
- l’utilisateur peut créer une scène exploitable sans remplir tous les blocs avancés
- les étapes 1 et 2 suffisent pour produire un brouillon complet
- l’étape 3 est optionnelle ou contextualisée
- l’étape 4 ne présente que des actions finales sans ambiguïté

## Header cible

### Contenu
- titre de page : `Créer une scène`
- sous-titre court : projet en cours ou mode `création` / `édition`
- badge de statut courant : brouillon, en attente, publié
- action secondaire : `Enregistrer le brouillon`
- action primaire : `Continuer` ou `Publier` selon l’étape

### Pourquoi
- supprimer la confusion entre barre basse et CTA internes
- rendre l’état courant visible en permanence

## Étape 1 — Base de la scène

### Objectif
Créer rapidement une fiche scène exploitable en quelques champs obligatoires.

### Sections affichées
- Import rapide de prompt
- Informations générales
- Identité du personnage
- Contexte immédiat

### Ordre recommandé
1. Import rapide de prompt
2. Informations générales
3. Identité du personnage
4. Contexte immédiat

### Règles UX proposées
- l’import de prompt est proposé au début comme accélérateur, pas comme passage obligatoire
- chaque section affiche clairement les champs requis
- la page affiche un résumé de complétion de l’étape

### Champs minimums pour passer à l’étape 2
- titre du projet ou nom de la scène
- personnage
- contexte minimal

### Mapping depuis l’écran actuel
- Bloc 0 → reste en entrée d’étape
- Section 1 → conservée mais raccourcie visuellement
- Section 2 → conservée
- Section 3 → conservée

## Étape 2 — Jeu et texte

### Objectif
Donner à l’acteur une matière claire pour jouer la scène.

### Sections affichées
- Objectif de jeu
- Direction émotionnelle
- Ton et style de jeu
- Texte
- Intentions par bloc

### Règles UX proposées
- `Texte` devient la section centrale de l’étape
- le micro de dictée reste proche du champ principal
- `Intentions par bloc` peut être replié par défaut sous un libellé `affiner le jeu minute par minute`

### Champs minimums pour passer à l’étape 3 ou à la vérification finale
- objectif principal
- texte ou dialogue
- émotion dominante

### Mapping depuis l’écran actuel
- Section 4 → conservée
- Section 5 → conservée
- Section 6 → conservée mais simplifiée visuellement
- Section 7 → priorisée
- Section 8 → déplacée en sous-section avancée de l’étape 2

## Étape 3 — Enrichissements avancés

### Objectif
Ajouter les éléments utiles au tournage, à la vidéo IA et au montage guidé sans bloquer la création d’un brouillon.

### Sections affichées
- Actions physiques
- Regard / caméra
- Rythme et respiration
- Repères techniques
- Ce que doit ressentir le spectateur
- Note finale du réalisateur
- Vidéo IA d’introduction
- Timeline dialoguée

### Sous-groupes recommandés
- Sous-groupe `Direction de tournage`
  - actions physiques
  - regard / caméra
  - rythme et respiration
  - repères techniques
- Sous-groupe `Intention finale`
  - ressenti spectateur
  - note du réalisateur
- Sous-groupe `Enrichissements IA`
  - vidéo IA
  - timeline dialoguée

### Règles UX proposées
- les sous-groupes sont repliés par défaut sauf si la scène exige ces options
- la vidéo IA devient un mini workflow en 3 écrans internes ou 3 états visibles : écrire, tester, valider
- la timeline propose d’abord un `mode simple` avec template 60 s, puis un basculement `mode avancé`

### Mapping depuis l’écran actuel
- Sections 9 à 14 → regroupées par usage métier
- Section 15 → garde son rôle, mais dans un sous-groupe expert
- Section 15bis → garde son rôle, mais derrière un mode simple par défaut

## Étape 4 — Vérification et sortie

### Objectif
Relire le résultat final, corriger si besoin, puis choisir une sortie claire.

### Sections affichées
- Preview scène
- Contrôles de correction
- Choix du statut final

### Contenu recommandé
- preview compacte mais fidèle
- bouton `Modifier la fiche`
- bouton `Modifier la vidéo IA` seulement si la vidéo existe ou est requise
- sélecteur de sortie avec wording orienté action

### CTA recommandés
- `Enregistrer le brouillon`
- `Envoyer pour validation`
- `Publier maintenant`

### Règles UX proposées
- aucun autre CTA concurrent sur la page à ce stade
- le statut choisi doit modifier clairement l’action primaire affichée

### Mapping depuis l’écran actuel
- Section 16 → conservée mais recentrée sur la décision finale
- bottom sheet → supprimé au profit d’un header ou footer d’étape unique

## Composants transverses à ajouter

### Indicateur de progression
- barre ou stepper `Étape 1 sur 4`
- état : à faire, en cours, complété

### Résumé latéral desktop
- résumé des champs manquants
- statut VEO
- statut timeline
- raccourci vers la preview finale

### Système de badges de complexité
- `Requis`
- `Recommandé`
- `Avancé`

### Messages de bénéfice
- une phrase courte en tête des sections complexes pour expliquer pourquoi l’utilisateur devrait les remplir

## Proposition de libellés à corriger

### Libellés actuels à risque
- `Générer la scène`
- `Valider et générer la preview`
- `Modifier les informations`

### Libellés cibles proposés
- `Créer le brouillon de scène`
- `Tester la vidéo IA`
- `Revenir à la fiche scène`

## Version MVP recommandée

Si la refonte doit rester limitée, la version MVP devrait faire seulement ceci :
- regrouper visuellement le formulaire en 4 étapes
- replier par défaut les sections 8 à 15bis
- clarifier tous les CTA finaux
- convertir VEO en mini workflow plus lisible
- introduire un mode simple pour la timeline

## Ordre de mise en œuvre recommandé

1. Clarifier les CTA et supprimer la concurrence entre actions finales
2. Ajouter la hiérarchie `requis / recommandé / avancé`
3. Regrouper la page en 4 étapes visibles sans casser le modèle de données
4. Simplifier l’entrée VEO
5. Simplifier l’entrée timeline

## Résultat cible attendu

Dans cette version, un admin doit pouvoir :
- créer une scène brouillon en quelques minutes
- comprendre immédiatement ce qui est obligatoire
- enrichir la scène plus tard sans se perdre
- publier avec confiance car la sortie finale est unique et claire