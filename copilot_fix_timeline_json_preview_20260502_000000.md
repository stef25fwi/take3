# FIX COPILOT — Ajout scène Take60 — Erreur Timeline JSON preview

Contexte :
Sur la page admin Ajout scène, le bouton “Valider et générer la preview” peut afficher :
“Unexpected token ... is not valid JSON”.

Fichier principal :
take30/lib/admin/take30_admin_scene_flow.dart

Objectif :
Corriger définitivement le parsing de la timeline guidée JSON pour que l’importeur, l’éditeur timeline et le bouton preview ne crashent jamais avec du texte non JSON.

IMPORTANT :
- Ne casse pas VEO.
- Ne casse pas le speech-to-text.
- Ne casse pas les boutons brouillon / publier.
- Ne casse pas l’importeur de prompt.
- Ne casse pas l’admin réel existant.
- `flutter analyze` doit rester vert.

====================================================
1. Ajouter une extraction JSON robuste
====================================================

Ajouter une fonction privée :

String _extractFirstJsonBlock(String raw)

Elle doit :
- trim le texte
- supprimer les fences markdown :
  ```json       - si le texte contient un tableau JSON, extraire uniquement du premier `[` au dernier `]`
- sinon si le texte contient un objet JSON, extraire uniquement du premier `{` au dernier `}`
- sinon retourner le texte trim
- ne jamais throw

====================================================
2. Ajouter un decode sécurisé timeline
====================================================

Ajouter une fonction privée dans le State du formulaire :

List<dynamic>? _tryDecodeGuidedTimelineJson({
required bool showError,
})

Elle doit :
- lire markersJsonCtrl.text
- si vide : considérer `[]`
- appeler _extractFirstJsonBlock
- faire jsonDecode dans try/catch
- accepter uniquement une List
- si valide :
- reformater markersJsonCtrl.text avec JsonEncoder.withIndent('  ')
- retourner la List
- si invalide :
- si showError true, afficher SnackBar :
  “Timeline JSON invalide : colle uniquement un tableau JSON qui commence par [ et finit par ].”
- retourner null
- ne jamais crash

====================================================
3. Bloquer la preview si timeline invalide
====================================================

Dans _generatePreviewVideo(), tout au début :
- appeler _tryDecodeGuidedTimelineJson(showError: true)
- si null : return
- ne pas appeler VEO
- ne pas modifier _generatedPreviewVideo
- ne pas modifier _validatedPreviewVideo

But :
Le bouton “Valider et générer la preview” ne doit plus déclencher VEO si la timeline est invalide.

====================================================
4. Sécuriser la génération / publication scène
====================================================

Dans _generateScene() ou la fonction qui persiste la scène :
- si markersJsonCtrl.text n’est pas vide :
- appeler _tryDecodeGuidedTimelineJson(showError: true)
- si null : bloquer la sauvegarde/publication avec un message clair
- autoriser `[]`

But :
Ne jamais sauvegarder une timeline invalide dans SceneFormData / Firestore.

====================================================
5. Corriger l’importeur prompt
====================================================

Dans _applyPromptImport(), à l’endroit où parsed.guidedTimelineJson est utilisé :

Actuellement il y a un jsonDecode direct.

Remplacer par :
- extraire uniquement le JSON avec _extractFirstJsonBlock(parsed.guidedTimelineJson)
- try/catch jsonDecode
- si c’est une List :
- markersJsonCtrl.text = JsonEncoder.withIndent('  ').convert(decoded)
- sinon :
- ne pas mettre tout le bloc brut dans markersJsonCtrl
- afficher warning :
  “Timeline détectée mais JSON invalide : champ non importé.”
- ne jamais remplir markersJsonCtrl avec des sections comme NOTES TECHNIQUES, MOTS-CLÉS, OBJECTIF TEST, etc.

====================================================
6. Sécuriser _GuidedTimelineEditor
====================================================

Dans _GuidedTimelineEditorState :
- tout jsonDecode du controller.text doit être dans try/catch
- si invalide :
- afficher timeline vide
- ne pas crash
- préserver le texte dans le controller
- si valide :
- charger les marqueurs

====================================================
7. Helper UI sous le champ timeline
====================================================

Sous _GuidedTimelineEditor ou dans sa zone :
Ajouter un petit texte :
“Le champ timeline doit contenir uniquement un tableau JSON : [ ... ].”

====================================================
8. Tests
====================================================

Ajouter ou compléter un test ciblé si possible :
- import prompt avec texte avant/après JSON
- markersJsonCtrl doit finir avec uniquement le tableau JSON formaté
- preview avec JSON invalide ne doit pas appeler VEO
- flutter analyze doit passer

====================================================
Résultat attendu
====================================================

Après correction :
- Coller un prompt complet ne pollue plus markersJsonCtrl
- La timeline est extraite proprement
- Le bouton preview ne crash plus
- Si JSON invalide : message clair, pas d’appel VEO
- flutter analyze : No issues found

À la fin, donne :
1. fonctions ajoutées
2. lignes modifiées
3. comportement avant/après
4. résultat flutter analyze
