# Take60 — CDN Google Cloud pour HLS

Objectif : servir les assets HLS Take60 (`.m3u8`, `.ts`) via Google Cloud CDN devant le bucket Firebase Storage `take30.firebasestorage.app`.

## Scripts

- Déploiement infra CDN : `scripts/deploy_take60_cdn.sh`
- Audit post-déploiement : `scripts/audit_take60_cdn.sh`

## Déploiement sans domaine

Prépare le backend bucket CDN et l’URL map, sans créer le certificat SSL ni le proxy HTTPS :

```bash
bash scripts/deploy_take60_cdn.sh
```

## Déploiement avec domaine

Choisir un domaine, par exemple `cdn.example.com`, puis lancer :

```bash
TAKE60_CDN_DOMAIN=cdn.example.com bash scripts/deploy_take60_cdn.sh
```

Ou avec un certificat SSL global déjà existant :

```bash
TAKE60_SSL_CERT_NAME=TAKE60_SSL_CERT_NAME bash scripts/deploy_take60_cdn.sh
```

Le script affiche l’IP globale à configurer dans le DNS :

```text
cdn.example.com A <IP_GLOBALE>
```

Le certificat Google-managed peut prendre plusieurs minutes à devenir actif après la propagation DNS.

Configurer ensuite le transcodeur Cloud Run avec :

```text
TAKE60_CDN_BASE_URL=https://cdn.example.com
```

Quand cette variable est définie, les nouvelles URLs HLS écrites en Firestore et les références internes des playlists pointent vers le CDN au lieu des URLs Firebase Storage tokenisées.

## Audit post-déploiement

Lister les ressources CDN et échantillonner les headers Storage :

```bash
bash scripts/audit_take60_cdn.sh
```

Tester une URL CDN réelle :

```bash
TAKE60_CDN_TEST_URL=https://cdn.example.com/take60/processed/<videoId>/master.m3u8 \
  bash scripts/audit_take60_cdn.sh
```

Le script vérifie notamment :

- `gcloud compute backend-buckets list`
- `gcloud compute backend-buckets describe`
- `gcloud compute url-maps list`
- `gcloud compute target-https-proxies list`
- `gcloud compute forwarding-rules list --global`
- `gsutil ls -L` sur `.m3u8` et `.ts`
- `curl -I` pour `Cache-Control`, `Content-Type`, `Age`, `Via`, `x-cache` ou équivalent

## Cache-Control attendu

Le transcodeur applique :

- `.m3u8` : `public, max-age=60`
- `.ts` : `public, max-age=31536000, immutable`

## Sécurité premium

Ne pas rendre tout le bucket public par défaut : le bucket Firebase contient aussi des chemins non-HLS. Le script ne modifie pas l’IAM public sauf si `TAKE60_CDN_ALLOW_PUBLIC_BUCKET_READ=1` est explicitement fourni.

Pour une sécurité premium stricte, préférer une des deux options :

1. bucket dédié aux assets HLS publiables, ou
2. Cloud CDN signed URLs / signed cookies avec génération d’URL côté backend.

Le code Flutter continue de résoudre les URLs via le backend/fallback existant : gratuit en 720p, premium via master/1080p.

Important : les vidéos transcodées avant l’activation de `TAKE60_CDN_BASE_URL` peuvent contenir des playlists qui référencent encore Firebase Storage. Relancer le transcodage ou backfiller les URLs HLS si nécessaire.