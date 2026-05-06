#!/usr/bin/env bash
set -euo pipefail

# Provisionne l'infrastructure Google Cloud CDN pour les assets HLS Take60.
#
# Variables principales :
#   PROJECT_ID                 Projet GCP. Défaut: projet gcloud actif.
#   TAKE60_BUCKET              Bucket GCS/Firebase Storage source.
#                              Défaut: take30.firebasestorage.app
#   TAKE60_CDN_NAME            Préfixe des ressources CDN.
#                              Défaut: take60-hls
#   TAKE60_CDN_DOMAIN          Domaine public du CDN, ex: cdn.take60.app.
#                              Si absent, le script prépare backend bucket + URL map
#                              puis s'arrête avant SSL/proxy/forwarding rule.
#   TAKE60_CDN_IP_NAME         Nom de l'IP globale réservée.
#                              Défaut: ${TAKE60_CDN_NAME}-ip
#   TAKE60_SSL_CERT_NAME       Nom d'un certificat SSL global existant.
#                              Si absent, le script crée/emploie ${TAKE60_CDN_NAME}-cert.
#   TAKE60_CDN_ALLOW_PUBLIC_BUCKET_READ=1
#                              Option dangereuse: rend tout le bucket lisible par
#                              allUsers. Désactivée par défaut pour ne pas exposer
#                              les uploads bruts/admin.
#
# Note sécurité:
#   Un backend bucket Cloud CDN ne doit pas rendre tout le bucket public en prod
#   si le bucket contient aussi des objets privés. Pour une vraie sécurité premium,
#   utiliser un bucket dédié aux HLS publics ou ajouter des URL signées CDN.

PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null || true)}"
TAKE60_BUCKET="${TAKE60_BUCKET:-take30.firebasestorage.app}"
TAKE60_CDN_NAME="${TAKE60_CDN_NAME:-take60-hls}"
TAKE60_CDN_DOMAIN="${TAKE60_CDN_DOMAIN:-}"
TAKE60_CDN_IP_NAME="${TAKE60_CDN_IP_NAME:-${TAKE60_CDN_NAME}-ip}"
TAKE60_SSL_CERT_NAME="${TAKE60_SSL_CERT_NAME:-}"

BACKEND_BUCKET_NAME="${TAKE60_CDN_NAME}-backend"
URL_MAP_NAME="${TAKE60_CDN_NAME}-url-map"
CERT_NAME="${TAKE60_SSL_CERT_NAME:-${TAKE60_CDN_NAME}-cert}"
HTTPS_PROXY_NAME="${TAKE60_CDN_NAME}-https-proxy"
FORWARDING_RULE_NAME="${TAKE60_CDN_NAME}-forwarding-rule"

if [[ -z "${PROJECT_ID}" ]]; then
  echo "❌ PROJECT_ID introuvable. Définis PROJECT_ID ou connecte gcloud à un projet." >&2
  exit 1
fi

echo "===== TAKE60 CDN DEPLOY ====="
echo "Project: ${PROJECT_ID}"
echo "Bucket: gs://${TAKE60_BUCKET}"
echo "Prefix: ${TAKE60_CDN_NAME}"
echo "Domain: ${TAKE60_CDN_DOMAIN:-<non défini>}"
echo ""

gcloud config set project "${PROJECT_ID}" >/dev/null

if ! gsutil ls -b "gs://${TAKE60_BUCKET}" >/dev/null 2>&1; then
  echo "❌ Bucket introuvable ou inaccessible: gs://${TAKE60_BUCKET}" >&2
  exit 1
fi

if [[ "${TAKE60_CDN_ALLOW_PUBLIC_BUCKET_READ:-0}" == "1" ]]; then
  echo "⚠️  Activation lecture publique bucket demandée explicitement."
  gsutil iam ch allUsers:objectViewer "gs://${TAKE60_BUCKET}"
else
  echo "ℹ️  Lecture publique bucket non modifiée. Préférer bucket HLS dédié ou URL signées CDN."
fi

if gcloud compute backend-buckets describe "${BACKEND_BUCKET_NAME}" >/dev/null 2>&1; then
  echo "✅ Backend bucket existe: ${BACKEND_BUCKET_NAME}"
  gcloud compute backend-buckets update "${BACKEND_BUCKET_NAME}" \
    --gcs-bucket-name="${TAKE60_BUCKET}" \
    --enable-cdn \
    --cache-mode=CACHE_ALL_STATIC \
    --default-ttl=3600 \
    --max-ttl=31536000 \
    --client-ttl=3600 >/dev/null
else
  echo "➕ Création backend bucket CDN: ${BACKEND_BUCKET_NAME}"
  gcloud compute backend-buckets create "${BACKEND_BUCKET_NAME}" \
    --gcs-bucket-name="${TAKE60_BUCKET}" \
    --enable-cdn \
    --cache-mode=CACHE_ALL_STATIC \
    --default-ttl=3600 \
    --max-ttl=31536000 \
    --client-ttl=3600 >/dev/null
fi

if gcloud compute url-maps describe "${URL_MAP_NAME}" >/dev/null 2>&1; then
  echo "✅ URL map existe: ${URL_MAP_NAME}"
  gcloud compute url-maps set-default-service "${URL_MAP_NAME}" \
    --default-backend-bucket="${BACKEND_BUCKET_NAME}" >/dev/null
else
  echo "➕ Création URL map: ${URL_MAP_NAME}"
  gcloud compute url-maps create "${URL_MAP_NAME}" \
    --default-backend-bucket="${BACKEND_BUCKET_NAME}" >/dev/null
fi

if [[ -z "${TAKE60_CDN_DOMAIN}" && -z "${TAKE60_SSL_CERT_NAME}" ]]; then
  cat <<EOF

✅ Backend bucket + URL map prêts.
⏭️  SSL/proxy/forwarding rule ignorés car TAKE60_CDN_DOMAIN et TAKE60_SSL_CERT_NAME ne sont pas définis.

Prochaine étape:
  1. Choisir un domaine, ex: cdn.example.com
  2. Relancer avec:
     TAKE60_CDN_DOMAIN=cdn.example.com bash scripts/deploy_take60_cdn.sh
     ou TAKE60_SSL_CERT_NAME=<certificat-global-existant> bash scripts/deploy_take60_cdn.sh
  3. Pointer le DNS A du domaine vers l'IP globale affichée par le script.
EOF
  exit 0
fi

if gcloud compute addresses describe "${TAKE60_CDN_IP_NAME}" --global >/dev/null 2>&1; then
  echo "✅ IP globale existe: ${TAKE60_CDN_IP_NAME}"
else
  echo "➕ Réservation IP globale: ${TAKE60_CDN_IP_NAME}"
  gcloud compute addresses create "${TAKE60_CDN_IP_NAME}" --global >/dev/null
fi

CDN_IP="$(gcloud compute addresses describe "${TAKE60_CDN_IP_NAME}" --global --format='value(address)')"

if gcloud compute ssl-certificates describe "${CERT_NAME}" --global >/dev/null 2>&1; then
  echo "✅ Certificat SSL managé existe: ${CERT_NAME}"
else
  if [[ -n "${TAKE60_SSL_CERT_NAME}" ]]; then
    echo "❌ Certificat SSL existant introuvable: ${TAKE60_SSL_CERT_NAME}" >&2
    exit 1
  fi
  if [[ -z "${TAKE60_CDN_DOMAIN}" ]]; then
    echo "❌ TAKE60_CDN_DOMAIN requis pour créer un certificat SSL managé." >&2
    exit 1
  fi
  echo "➕ Création certificat SSL managé: ${CERT_NAME}"
  gcloud compute ssl-certificates create "${CERT_NAME}" \
    --domains="${TAKE60_CDN_DOMAIN}" \
    --global >/dev/null
fi

if gcloud compute target-https-proxies describe "${HTTPS_PROXY_NAME}" >/dev/null 2>&1; then
  echo "✅ HTTPS proxy existe: ${HTTPS_PROXY_NAME}"
  gcloud compute target-https-proxies update "${HTTPS_PROXY_NAME}" \
    --ssl-certificates="${CERT_NAME}" >/dev/null
  gcloud compute target-https-proxies set-url-map "${HTTPS_PROXY_NAME}" \
    --url-map="${URL_MAP_NAME}" >/dev/null
else
  echo "➕ Création HTTPS proxy: ${HTTPS_PROXY_NAME}"
  gcloud compute target-https-proxies create "${HTTPS_PROXY_NAME}" \
    --ssl-certificates="${CERT_NAME}" \
    --url-map="${URL_MAP_NAME}" >/dev/null
fi

if gcloud compute forwarding-rules describe "${FORWARDING_RULE_NAME}" --global >/dev/null 2>&1; then
  echo "✅ Forwarding rule existe: ${FORWARDING_RULE_NAME}"
else
  echo "➕ Création forwarding rule HTTPS: ${FORWARDING_RULE_NAME}"
  gcloud compute forwarding-rules create "${FORWARDING_RULE_NAME}" \
    --global \
    --address="${TAKE60_CDN_IP_NAME}" \
    --target-https-proxy="${HTTPS_PROXY_NAME}" \
    --ports=443 >/dev/null
fi

cat <<EOF

✅ CDN Take60 préparé.

DNS à configurer:
  ${TAKE60_CDN_DOMAIN} A ${CDN_IP}

Vérification certificat:
  gcloud compute ssl-certificates describe ${CERT_NAME} --global

Audit post-déploiement:
  TAKE60_CDN_DOMAIN=${TAKE60_CDN_DOMAIN} bash scripts/audit_take60_cdn.sh

Configuration transcodeur Cloud Run à appliquer ensuite:
  TAKE60_CDN_BASE_URL=https://${TAKE60_CDN_DOMAIN}
EOF