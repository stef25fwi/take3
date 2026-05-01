#!/usr/bin/env bash
set -euo pipefail

DART_FILE="lib/firebase_options.dart"
API_KEY=$(grep "apiKey:" "$DART_FILE" | head -1 | sed -E "s/.*apiKey: '([^']+)'.*/\1/")

echo "===== 1. DIAGNOSTIC CONFIG VEO3 ====="
VEO_STATUS_RAW=$(curl -sS "https://veostatus-hykin5mi5q-ew.a.run.app?token=veo3-diag-2026")
echo "$VEO_STATUS_RAW" | python3 -m json.tool 2>/dev/null || echo "Reponse brute : $VEO_STATUS_RAW"

echo ""
echo "===== 2. CONNEXION USER ADMIN ====="
SIGNIN=$(curl -sS \
  "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"email":"test.take60.1777598090@take60.app","password":"Take60Test!2026","returnSecureToken":true}')

TOKEN=$(echo "$SIGNIN" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('idToken',''))" 2>/dev/null || true)
USER_ID=$(echo "$SIGNIN" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('localId',''))" 2>/dev/null || true)

if [ -z "$TOKEN" ]; then
  echo "ERREUR connexion : $(echo "$SIGNIN" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('error',{}).get('message','?'))" 2>/dev/null)"
  exit 1
fi
echo "USER_ID : $USER_ID"
echo "Token   : ${TOKEN:0:40}..."

echo ""
echo "===== 3. TEST startVeoSceneGeneration ====="
START=$(curl -sS -w "\nHTTP_CODE:%{http_code}" \
  -X POST "https://europe-west1-take30.cloudfunctions.net/startVeoSceneGeneration" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"data":{"sceneId":"veo3_audit_final","prompt":"Plan cinematique 16:9, ambiance dramatique, camera stable, 15 secondes.","durationSeconds":15,"aspectRatio":"16:9"}}')

HTTP_CODE=$(echo "$START" | grep "HTTP_CODE:" | sed 's/HTTP_CODE://')
BODY=$(echo "$START" | sed '/HTTP_CODE:/d')
echo "HTTP  : $HTTP_CODE"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"

SCENE_ID=$(echo "$BODY" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    r=d.get('result') or d.get('data') or {}
    print(r.get('sceneId') or '')
except: print('')
" 2>/dev/null || true)

PROVIDER=$(echo "$BODY" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    r=d.get('result') or d.get('data') or {}
    print(r.get('provider') or '')
except: print('')
" 2>/dev/null || true)

if [ -z "$SCENE_ID" ]; then
  echo ""
  echo "STOP : sceneId absent — VEO3 n'a pas demarre."
  exit 1
fi

echo ""
echo "Job cree : sceneId=$SCENE_ID  provider=$PROVIDER"

if [ "$PROVIDER" = "mock" ]; then
  echo ""
  echo "MODE MOCK : VERTEX_LOCATION / VEO_MODEL_ID non configures en production."
fi

echo ""
echo "===== 4. POLL checkVeoSceneGeneration (10 x 20s) ====="
VIDEO_URL=""
for i in 1 2 3 4 5 6 7 8 9 10; do
  echo ""
  echo "--- Check $i/10 ---"
  CHECK=$(curl -sS -w "\nHTTP_CODE:%{http_code}" \
    -X POST "https://europe-west1-take30.cloudfunctions.net/checkVeoSceneGeneration" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{\"data\":{\"sceneId\":\"$SCENE_ID\"}}")

  CHECK_BODY=$(echo "$CHECK" | sed '/HTTP_CODE:/d')
  echo "$CHECK_BODY" | python3 -m json.tool 2>/dev/null || echo "$CHECK_BODY"

  STATUS=$(echo "$CHECK_BODY" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    r=d.get('result') or d.get('data') or {}
    print(r.get('status') or '')
except: print('')
" 2>/dev/null || true)

  VIDEO_URL=$(echo "$CHECK_BODY" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    r=d.get('result') or d.get('data') or {}
    print(r.get('videoUrl') or '')
except: print('')
" 2>/dev/null || true)

  echo "status=$STATUS  videoUrl=$VIDEO_URL"

  if echo "$VIDEO_URL" | grep -qE "^https://"; then
    break
  fi
  sleep 20
done

echo ""
echo "===== VERDICT ====="
if echo "$VIDEO_URL" | grep -qE "^https://"; then
  echo "VEO3 OPERATIONNEL — videoUrl=$VIDEO_URL"
else
  echo "VEO3 PAS ENCORE VALIDE (status final: $STATUS)"
fi
