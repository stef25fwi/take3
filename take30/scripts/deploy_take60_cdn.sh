#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-take30}"
TAKE60_BUCKET="${TAKE60_BUCKET:-take30.firebasestorage.app}"
TAKE60_CDN_DOMAIN="${TAKE60_CDN_DOMAIN:-}"

BACKEND_BUCKET="take60-hls-backend"
URL_MAP="take60-hls-url-map"
SSL_CERT="take60-hls-ssl-cert"
HTTPS_PROXY="take60-hls-https-proxy"
FORWARDING_RULE="take60-hls-forwarding-rule"

if [ -z "$TAKE60_CDN_DOMAIN" ] || [ "$TAKE60_CDN_DOMAIN" = "ton-domaine-cdn.example.com" ]; then
  echo "❌ TAKE60_CDN_DOMAIN doit être ton vrai domaine CDN."
  echo "Exemple : TAKE60_CDN_DOMAIN=cdn.take60.app bash scripts/deploy_take60_cdn.sh"
  exit 1
fi

gcloud config set project "$PROJECT_ID"

echo "== Backend bucket CDN =="
gcloud compute backend-buckets describe "$BACKEND_BUCKET" >/dev/null 2>&1 || \
gcloud compute backend-buckets create "$BACKEND_BUCKET" \
  --gcs-bucket-name="$TAKE60_BUCKET" \
  --enable-cdn

gcloud compute backend-buckets update "$BACKEND_BUCKET" --enable-cdn

echo "== URL map =="
gcloud compute url-maps describe "$URL_MAP" >/dev/null 2>&1 || \
gcloud compute url-maps create "$URL_MAP" \
  --default-backend-bucket="$BACKEND_BUCKET"

echo "== SSL managed certificate =="
gcloud compute ssl-certificates describe "$SSL_CERT" --global >/dev/null 2>&1 || \
gcloud compute ssl-certificates create "$SSL_CERT" \
  --domains="$TAKE60_CDN_DOMAIN" \
  --global

echo "== HTTPS proxy =="
gcloud compute target-https-proxies describe "$HTTPS_PROXY" >/dev/null 2>&1 || \
gcloud compute target-https-proxies create "$HTTPS_PROXY" \
  --url-map="$URL_MAP" \
  --ssl-certificates="$SSL_CERT"

echo "== Global forwarding rule =="
gcloud compute forwarding-rules describe "$FORWARDING_RULE" --global >/dev/null 2>&1 || \
gcloud compute forwarding-rules create "$FORWARDING_RULE" \
  --global \
  --target-https-proxy="$HTTPS_PROXY" \
  --ports=443

echo ""
echo "✅ CDN Take60 créé ou déjà existant."
echo ""
echo "Adresse IP à pointer dans ton DNS :"
gcloud compute forwarding-rules describe "$FORWARDING_RULE" \
  --global \
  --format="value(IPAddress)"

echo ""
echo "⚠️ Ajoute un enregistrement DNS A :"
echo "$TAKE60_CDN_DOMAIN -> IP ci-dessus"
echo ""
echo "Puis attends que le certificat passe ACTIVE :"
echo "gcloud compute ssl-certificates describe $SSL_CERT --global --format='get(managed.status)'"
