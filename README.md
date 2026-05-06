# Take30

La structure complète de l’application a été mise en place dans le dossier Take30 Flutter.

## Emplacement principal
- take30 : application mobile Flutter complète
- take30/lib/screens : écrans principaux
- take30/lib/router : navigation
- take30/lib/services : données et logique de base
- take30/lib/widgets : composants partagés

## Point de départ
- ouvrir take30/lib/main.dart
- vérifier la configuration dans take30/pubspec.yaml

## Build et déploiement
- un workflow GitHub Actions construit et déploie automatiquement sur GitHub Pages à chaque push sur main
- le site GitHub Pages cible est prévu pour https://stef25fwi.github.io/take3/ et utilise un build Flutter avec `--base-href /take3/`
- le site Firebase Hosting https://take60.web.app se déploie séparément avec `bash ./deploy_take60_hosting.sh`, qui reconstruit Flutter avec `--base-href /` avant `firebase deploy --project take30 --only hosting`
