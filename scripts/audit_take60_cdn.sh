#!/usr/bin/env bash
set -euo pipefail

# Audit post-déploiement Cloud CDN + HLS Take60.
# Variables:
#   PROJECT_ID                 Projet GCP. Défaut: projet gcloud actif.
#   TAKE60_BUCKET              Bucket source. Défaut: take30.firebasestorage.app
#   TAKE60_CDN_NAME            Préfixe ressources. Défaut: take60-hls
#   TAKE60_CDN_DOMAIN          Domaine CDN, optionnel.
#   TAKE60_CDN_TEST_URL        URL CDN complète à tester avec curl -I, optionnel.
#   TAKE60_CDN_OBJECT_PATH     Chemin objet pour construire une URL depuis le domaine.
#                              Ex: take60/processed/<videoId>/master.m3u8

PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null || true)}"
TAKE60_BUCKET="${TAKE60_BUCKET:-take30.firebasestorage.app}"
TAKE60_CDN_NAME="${TAKE60_CDN_NAME:-take60-hls}"
TAKE60_CDN_DOMAIN="${TAKE60_CDN_DOMAIN:-}"
TAKE60_CDN_OBJECT_PATH="${TAKE60_CDN_OBJECT_PATH:-}"
TAKE60_CDN_TEST_URL="${TAKE60_CDN_TEST_URL:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPORT="${REPO_ROOT}/take30/audit_gcp_cdn_take60_hls_$(date +%Y%m%d_%H%M%S).txt"

if [[ -n "${TAKE60_CDN_DOMAIN}" && -n "${TAKE60_CDN_OBJECT_PATH}" && -z "${TAKE60_CDN_TEST_URL}" ]]; then
  TAKE60_CDN_TEST_URL="https://${TAKE60_CDN_DOMAIN}/${TAKE60_CDN_OBJECT_PATH#/}"
fi

{
  echo "===== GCP CDN TAKE60 HLS VALIDATION ====="
  date
  echo ""
  echo "===== GCLOUD PROJECT ====="
  echo "${PROJECT_ID:-<non défini>}"
  [[ -n "${PROJECT_ID}" ]] && gcloud config set project "${PROJECT_ID}" >/dev/null 2>&1 || true
  echo ""
  echo "===== AUTH ACCOUNT ====="
  gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null || true
  echo ""
  echo "===== STORAGE BUCKETS ====="
  gsutil ls 2>/dev/null || true
  echo ""
  echo "===== BACKEND BUCKETS ====="
  gcloud compute backend-buckets list 2>/dev/null || true
  echo ""
  echo "===== BACKEND BUCKET DETAILS ====="
  for b in $(gcloud compute backend-buckets list --format='value(name)' 2>/dev/null); do
    echo "--- BACKEND BUCKET: ${b} ---"
    gcloud compute backend-buckets describe "${b}" --format='yaml(name,bucketName,enableCdn,cdnPolicy)' 2>/dev/null || true
  done
  echo ""
  echo "===== URL MAPS ====="
  gcloud compute url-maps list 2>/dev/null || true
  echo ""
  echo "===== HTTPS PROXIES ====="
  gcloud compute target-https-proxies list 2>/dev/null || true
  echo ""
  echo "===== GLOBAL FORWARDING RULES ====="
  gcloud compute forwarding-rules list --global 2>/dev/null || true
  echo ""
  echo "===== HLS CACHE-CONTROL SAMPLE (.m3u8) ====="
  gsutil -m ls -L "gs://${TAKE60_BUCKET}/**.m3u8" 2>/dev/null | grep -E 'gs://|Cache-Control|Content-Type' | head -120 || true
  echo ""
  echo "===== HLS CACHE-CONTROL SAMPLE (.ts) ====="
  gsutil -m ls -L "gs://${TAKE60_BUCKET}/**.ts" 2>/dev/null | grep -E 'gs://|Cache-Control|Content-Type' | head -120 || true
  echo ""
  echo "===== CURL CDN HEADERS ====="
  if [[ -n "${TAKE60_CDN_TEST_URL}" ]]; then
    echo "URL: ${TAKE60_CDN_TEST_URL}"
    curl -I -L --max-time 30 "${TAKE60_CDN_TEST_URL}" 2>/dev/null | grep -Ei '^(HTTP/|cache-control:|content-type:|age:|via:|x-cache:|x-served-by:|server:)' || true
  else
    echo "Aucune URL CDN fournie. Définir TAKE60_CDN_TEST_URL ou TAKE60_CDN_DOMAIN + TAKE60_CDN_OBJECT_PATH."
  fi
} 2>&1 | tee "${REPORT}"

echo ""
echo "✅ Rapport généré : ${REPORT}"