#!/usr/bin/env bash
# Vérifie l'accès VEO3 et les logs de la dernière erreur
set -euo pipefail

echo "===== veoStatus (probe modèle live) ====="
curl -sS "https://veostatus-hykin5mi5q-ew.a.run.app?token=veo3-diag-2026" | python3 -m json.tool

echo ""
echo "===== Logs startVeoSceneGeneration (dernières 30 lignes) ====="
firebase functions:log --only startVeoSceneGeneration --project take30 -n 30 2>/dev/null || \
  echo "(firebase CLI non dispo — voir https://console.cloud.google.com/logs pour les logs Cloud Run)"
