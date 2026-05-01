#!/usr/bin/env bash
# Lance depuis /workspaces/take3
# bash take30/fix_and_test_veo3.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FN_DIR="$ROOT/functions"
APP_DIR="$ROOT/take30"

echo "===== CONTENU ACTUEL functions/.env ====="
cat "$FN_DIR/.env" 2>/dev/null || echo "(fichier .env absent)"

echo ""
echo "===== CORRECTION : suppression FIRESTORE_EMULATOR_HOST du .env deployé ====="
if [ -f "$FN_DIR/.env" ] && grep -q "FIRESTORE_EMULATOR_HOST" "$FN_DIR/.env"; then
  # Sauvegarde
  cp "$FN_DIR/.env" "$FN_DIR/.env.bak"
  echo "Backup : $FN_DIR/.env.bak"

  # Déplace la ligne vers .env.local (local only, non déployé)
  grep "FIRESTORE_EMULATOR_HOST" "$FN_DIR/.env" >> "$FN_DIR/.env.local" 2>/dev/null || true

  # Supprime du .env déployé
  sed -i '/FIRESTORE_EMULATOR_HOST/d' "$FN_DIR/.env"

  echo "FIRESTORE_EMULATOR_HOST retiré du .env deployé → déplacé dans .env.local"
else
  echo "(FIRESTORE_EMULATOR_HOST absent du .env — autre cause)"
fi

echo ""
echo "===== .env après correction ====="
cat "$FN_DIR/.env" 2>/dev/null || echo "(vide)"

echo ""
echo "===== REDÉPLOIEMENT FONCTIONS ====="
cd "$ROOT"
firebase deploy --only functions --project take30

echo ""
echo "===== TEST VEO3 ====="
cd "$APP_DIR"
bash run_veo3_check.sh
