#!/usr/bin/env bash
set -euo pipefail

#───────────────────────────────────────────────
#  Take30 — Add · Commit · Push · Build · Deploy
#───────────────────────────────────────────────

ROOT="$(cd "$(dirname "$0")" && pwd)"
FLUTTER_DIR="$ROOT/take30"
COMMIT_MSG="${1:-feat: update Take30}"

echo "══════════════════════════════════════════"
echo "  🚀  Take30  —  ADD · COMMIT · PUSH · BUILD · DEPLOY"
echo "══════════════════════════════════════════"

# ── 1. Flutter analyze ──────────────────────
echo ""
echo "▸ [1/5] Flutter analyze..."
cd "$FLUTTER_DIR"
flutter analyze
echo "  ✓ Analyse OK"

# ── 2. Flutter build web ────────────────────
echo ""
echo "▸ [2/5] Flutter build web..."
flutter build web --release --base-href /take3/
echo "  ✓ Build OK"

# ── 3. Git add ──────────────────────────────
echo ""
echo "▸ [3/5] Git add..."
cd "$ROOT"
git add -A
echo "  ✓ Fichiers ajoutés"

# ── 4. Git commit ───────────────────────────
echo ""
echo "▸ [4/5] Git commit..."
if git diff --cached --quiet; then
  echo "  ⚠  Rien à commiter — on continue."
else
  git commit -m "$COMMIT_MSG"
  echo "  ✓ Commit OK"
fi

# ── 5. Git push → déclenche GitHub Actions deploy ──
echo ""
echo "▸ [5/5] Git push origin main..."
git push origin main
echo "  ✓ Push OK — GitHub Actions va déployer sur Pages."

echo ""
echo "══════════════════════════════════════════"
echo "  ✅  Terminé ! Déploiement en cours sur GitHub Pages."
echo "  📎  https://github.com/stef25fwi/take3/actions"
echo "══════════════════════════════════════════"
