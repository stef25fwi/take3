#!/usr/bin/env bash
set -euo pipefail

#───────────────────────────────────────────────
#  Take60 Firebase Hosting — build root + deploy
#───────────────────────────────────────────────

ROOT="$(cd "$(dirname "$0")" && pwd)"
FLUTTER_DIR="$ROOT/take30"
FLUTTER_BIN="${FLUTTER_BIN:-}"
BUILD_ARGS=(--release --base-href /)

if [[ -n "${TAKE30_ADMIN_ID:-}" ]]; then
  BUILD_ARGS+=(--dart-define "TAKE30_ADMIN_ID=$TAKE30_ADMIN_ID")
fi

if [[ -n "${TAKE30_ADMIN_PASSWORD:-}" ]]; then
  BUILD_ARGS+=(--dart-define "TAKE30_ADMIN_PASSWORD=$TAKE30_ADMIN_PASSWORD")
fi

if [[ -z "$FLUTTER_BIN" ]]; then
  if command -v flutter >/dev/null 2>&1; then
    FLUTTER_BIN="$(command -v flutter)"
  elif [[ -x "/home/codespace/flutter/bin/flutter" ]]; then
    FLUTTER_BIN="/home/codespace/flutter/bin/flutter"
  else
    echo "❌ Flutter introuvable. Définis FLUTTER_BIN ou ajoute flutter au PATH."
    exit 1
  fi
fi

echo "══════════════════════════════════════════"
echo "  🚀  Take60 — FIREBASE HOSTING DEPLOY"
echo "══════════════════════════════════════════"

echo ""
echo "▸ [0/4] Flutter pub get..."
cd "$FLUTTER_DIR"
"$FLUTTER_BIN" pub get
echo "  ✓ Dépendances OK"

echo ""
echo "▸ [1/4] Flutter analyze..."
"$FLUTTER_BIN" analyze --no-fatal-infos --no-fatal-warnings
echo "  ✓ Analyse OK"

echo ""
echo "▸ [2/4] Flutter build web pour take60.web.app..."
"$FLUTTER_BIN" build web "${BUILD_ARGS[@]}"
echo "  ✓ Build OK — base-href=/"

echo ""
echo "▸ [3/4] Firebase deploy hosting:take60..."
firebase deploy --project take30 --only hosting
echo "  ✓ Firebase Hosting OK"

echo ""
echo "══════════════════════════════════════════"
echo "  ✅  Déploiement terminé : https://take60.web.app"
echo "══════════════════════════════════════════"