#!/usr/bin/env bash
# Deploy the website to Cloud Run STAGING on MyReciBook-Dev.
# Agreed 2026-08-28: live staging on the dev project before production.
# NOT run yet — prepared 2026-08-29, waits for Arnar's go.
#
# Usage: ./deploy-staging.sh
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-gen-lang-client-0166122901}"   # docs/gcp-project-facts.md
REGION="${REGION:-europe-west1}"
SERVICE="${SERVICE:-myrecibook-website-staging}"

export PATH="$HOME/google-cloud-sdk/bin:$PATH"           # gcloud lives off-PATH on PlutoII
command -v gcloud >/dev/null || { echo "gcloud not found"; exit 1; }

echo "── 1/3 static build"
pnpm generate

echo "── 2/3 build + push via Cloud Build"
gcloud builds submit --project "$PROJECT_ID" --tag "$REGION-docker.pkg.dev/$PROJECT_ID/cloud-run-source-deploy/$SERVICE"

echo "── 3/3 deploy"
gcloud run deploy "$SERVICE" \
  --project "$PROJECT_ID" \
  --region "$REGION" \
  --image "$REGION-docker.pkg.dev/$PROJECT_ID/cloud-run-source-deploy/$SERVICE" \
  --allow-unauthenticated \
  --port 8080 \
  --memory 128Mi \
  --max-instances 2

gcloud run services describe "$SERVICE" --project "$PROJECT_ID" --region "$REGION" --format 'value(status.url)'
