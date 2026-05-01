#!/usr/bin/env bash
# Script de test VEO3 corrigé
# Corrections apportées :
#   1. cors: true ajouté aux Cloud Functions (à redéployer)
#   2. durationSeconds: 15 (la valeur minimale acceptée : 15 ou 30)
#   3. checkVeoSceneGeneration attend sceneId, pas jobId
#   4. L'utilisateur test doit avoir le rôle admin dans Firestore

set -euo pipefail

PROJECT_ID="take30"
REGION="europe-west1"
TEST_EMAIL="test.take60.$(date +%s)@take60.app"
TEST_PASSWORD="Take60Test!2026"
SCENE_ID="audit_scene_veo3_real"
REPORT="creation_user_test_veo3_$(date +%Y%m%d_%H%M%S).txt"

{
echo "===== CRÉATION UTILISATEUR TEST FIREBASE + TEST VEO3 ====="
echo "Email test : $TEST_EMAIL"
echo ""

# ── 1. API KEY ────────────────────────────────────────────────────────────────
echo "===== 1. EXTRACTION API KEY ====="
API_KEY=$(grep -A20 "static const FirebaseOptions web" lib/firebase_options.dart \
  | grep "apiKey:" | head -1 | sed -E "s/.*apiKey: '([^']+)'.*/\1/")
if [ -z "$API_KEY" ]; then
  API_KEY=$(grep "apiKey:" lib/firebase_options.dart | head -1 \
    | sed -E "s/.*apiKey: '([^']+)'.*/\1/")
fi
if [ -z "$API_KEY" ]; then
  echo "❌ API_KEY introuvable dans lib/firebase_options.dart"
  exit 1
fi
echo "✅ API_KEY trouvée"
echo ""

# ── 2. CRÉATION UTILISATEUR ──────────────────────────────────────────────────
echo "===== 2. CRÉATION UTILISATEUR TEST VIA FIREBASE AUTH REST ====="
SIGNUP_RESPONSE=$(curl -sS \
  "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"returnSecureToken\":true}")

echo "$SIGNUP_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$SIGNUP_RESPONSE"

ID_TOKEN=$(echo "$SIGNUP_RESPONSE" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d.get('idToken',''))" 2>/dev/null || true)
LOCAL_ID=$(echo "$SIGNUP_RESPONSE" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d.get('localId',''))" 2>/dev/null || true)
ERROR_MESSAGE=$(echo "$SIGNUP_RESPONSE" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d.get('error',{}).get('message',''))" 2>/dev/null || true)

if [ -z "$ID_TOKEN" ]; then
  echo ""
  echo "❌ Création utilisateur impossible. Erreur Firebase : $ERROR_MESSAGE"
  if echo "$ERROR_MESSAGE" | grep -q "OPERATION_NOT_ALLOWED"; then
    echo "➡️  Firebase Console → Authentication → Sign-in method → Email/Password → Enable"
  fi
  exit 1
fi

echo ""
echo "✅ Utilisateur créé"
echo "UID      : $LOCAL_ID"
echo "Email    : $TEST_EMAIL"
echo ""

# ── PRÉREQUIS ADMIN ──────────────────────────────────────────────────────────
echo "===== ⚠️  PRÉREQUIS : RÔLE ADMIN REQUIS ====="
echo ""
echo "La fonction startVeoSceneGeneration est réservée aux admins."
echo "Pour autoriser cet utilisateur, crée ce document dans Firebase Console :"
echo ""
echo "  Collection : admins"
echo "  Document   : $LOCAL_ID"
echo "  (le document peut être vide)"
echo ""
echo "Ou via Firestore REST :"
echo "  curl -X PATCH \\"
echo "    \"https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/(default)/documents/admins/$LOCAL_ID\" \\"
echo "    -H \"Authorization: Bearer \$ADMIN_TOKEN\" \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"fields\":{}}'"
echo ""
echo "Appuie sur Entrée une fois l'admin créé, ou Ctrl+C pour annuler."
read -r || true
echo ""

# ── 3. START VEO3 ─────────────────────────────────────────────────────────────
echo "===== 3. TEST AUTHENTIFIÉ startVeoSceneGeneration ====="
START_URL="https://${REGION}-${PROJECT_ID}.cloudfunctions.net/startVeoSceneGeneration"

# CORRECTION: durationSeconds doit valoir 15 ou 30 (pas 5)
START_RESPONSE=$(curl -sS -w "\nHTTP_CODE:%{http_code}\n" \
  -X POST "$START_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ID_TOKEN" \
  -d "{
    \"data\": {
      \"sceneId\": \"$SCENE_ID\",
      \"prompt\": \"Plan cinématique réaliste de 15 secondes, format 16:9, aucun texte, aucun logo, ambiance dramatique, caméra stable.\",
      \"durationSeconds\": 15,
      \"aspectRatio\": \"16:9\"
    }
  }")

echo "$START_RESPONSE"

# CORRECTION: la réponse retourne sceneId/operationId, pas jobId
SCENE_ID_RESP=$(echo "$START_RESPONSE" | sed '/HTTP_CODE:/d' | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    r=d.get('result') or d.get('data') or {}
    print(r.get('sceneId') or '')
except Exception:
    print('')
" 2>/dev/null || true)

OPERATION_ID=$(echo "$START_RESPONSE" | sed '/HTTP_CODE:/d' | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    r=d.get('result') or d.get('data') or {}
    print(r.get('operationId') or '')
except Exception:
    print('')
" 2>/dev/null || true)

if [ -z "$SCENE_ID_RESP" ]; then
  echo ""
  echo "❌ Aucun sceneId retourné. VEO3 n'a pas démarré."
  EXIT_CODE=1
else
  echo ""
  echo "✅ Job VEO3 créé"
  echo "sceneId     : $SCENE_ID_RESP"
  echo "operationId : $OPERATION_ID"
  EXIT_CODE=0
fi

if [ "$EXIT_CODE" -ne 0 ]; then exit 1; fi

# ── 4. CHECK VEO3 ─────────────────────────────────────────────────────────────
echo ""
echo "===== 4. CHECK VEO3 ====="
CHECK_URL="https://${REGION}-${PROJECT_ID}.cloudfunctions.net/checkVeoSceneGeneration"

VIDEO_URL=""

for i in 1 2 3 4 5 6 7 8 9 10; do
  echo ""
  echo "--- Vérification $i / 10 ---"

  # CORRECTION: passe sceneId (pas jobId)
  CHECK_RESPONSE=$(curl -sS -w "\nHTTP_CODE:%{http_code}\n" \
    -X POST "$CHECK_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ID_TOKEN" \
    -d "{\"data\":{\"sceneId\":\"$SCENE_ID_RESP\"}}")

  echo "$CHECK_RESPONSE"

  STATUS=$(echo "$CHECK_RESPONSE" | sed '/HTTP_CODE:/d' | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    r=d.get('result') or d.get('data') or {}
    print(r.get('status') or '')
except Exception:
    print('')
" 2>/dev/null || true)

  VIDEO_URL=$(echo "$CHECK_RESPONSE" | sed '/HTTP_CODE:/d' | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    r=d.get('result') or d.get('data') or {}
    print(r.get('videoUrl') or '')
except Exception:
    print('')
" 2>/dev/null || true)

  echo "STATUS=$STATUS"
  echo "VIDEO_URL=$VIDEO_URL"

  if echo "$VIDEO_URL" | grep -qE "^https://"; then
    echo ""
    echo "✅ VEO3 OPÉRATIONNEL : vidéo générée avec URL réelle"
    break
  fi

  sleep 20
done

echo ""
echo "===== VERDICT ====="
if echo "$VIDEO_URL" | grep -qE "^https://"; then
  echo "✅ VEO3 EST OPÉRATIONNEL EN RÉEL"
  echo "Vidéo : $VIDEO_URL"
else
  echo "🔴 VEO3 PAS ENCORE VALIDÉ EN RÉEL"
fi

echo ""
echo "✅ Rapport généré : $REPORT"
} | tee "$REPORT"
