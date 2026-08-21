#!/usr/bin/env bash
# Deploy the extraction proxy to Cloud Run on MyReciBook-Dev.
#
# NOT run yet — gcloud was not installed on PlutoII when this was written
# (2026-08-21), so nothing here has been executed against a live project.
# docs/runbook-dev-deploy.md carries the console click-paths and the one-time
# setup this script assumes is already done.
#
# Usage:
#   ./deploy.sh                 # deploy with App Check OFF (closed track)
#   APP_CHECK_ENFORCE=true ./deploy.sh   # the one-line flip, once the app ships
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-gen-lang-client-0166122901}"
REGION="${REGION:-europe-west1}"  # matches the eur3 Firestore multi-region
SERVICE="${SERVICE:-myrecibook-proxy}"
SECRET="${SECRET:-gemini-api-key}"

# Fair-use and abuse settings — the numbers from docs/ai-cap-mechanics.md §3.
YEARLY_CAP="${YEARLY_CAP:-1200}"
PER_MINUTE_LIMIT="${PER_MINUTE_LIMIT:-10}"
PER_DAY_LIMIT="${PER_DAY_LIMIT:-50}"
GRACE_DAYS="${GRACE_DAYS:-14}"
GLOBAL_DAILY_LIMIT="${GLOBAL_DAILY_LIMIT:-2000}"
APP_CHECK_ENFORCE="${APP_CHECK_ENFORCE:-false}"

# Verifies App Check token iss/aud. See docs/gcp-project-facts.md.
FIREBASE_PROJECT_NUMBER="${FIREBASE_PROJECT_NUMBER:-213431165631}"

command -v gcloud >/dev/null || {
  echo "gcloud not installed. See docs/runbook-dev-deploy.md step 0." >&2
  exit 1
}

echo "==> deploying $SERVICE to $PROJECT_ID / $REGION"
echo "    cap $YEARLY_CAP/yr · free $GRACE_DAYS days · $PER_MINUTE_LIMIT/min · $PER_DAY_LIMIT/day"
echo "    global breaker $GLOBAL_DAILY_LIMIT/day"
echo "    app check enforced: $APP_CHECK_ENFORCE"

# --allow-unauthenticated: the APP is the caller and has no Google identity;
#   App Check is what proves it is really our app, not IAM.
# --max-instances 4: a cost ceiling. The ledger is durable now, so instances
#   no longer have to be capped at 1 to keep counts coherent (audit B2).
# --min-instances 0: scale to zero. Cold start is sub-second against 2-5s of
#   model time, so there is nothing to buy here.
# The Gemini key arrives from Secret Manager and is never a literal.
gcloud run deploy "$SERVICE" \
  --project "$PROJECT_ID" \
  --source . \
  --region "$REGION" \
  --allow-unauthenticated \
  --min-instances 0 \
  --max-instances 4 \
  --concurrency 40 \
  --timeout 180s \
  --memory 512Mi \
  --set-secrets "GEMINI_API_KEY=${SECRET}:latest" \
  --set-env-vars "GOOGLE_CLOUD_PROJECT=${PROJECT_ID},YEARLY_CAP=${YEARLY_CAP},PER_MINUTE_LIMIT=${PER_MINUTE_LIMIT},PER_DAY_LIMIT=${PER_DAY_LIMIT},GRACE_DAYS=${GRACE_DAYS},GLOBAL_DAILY_LIMIT=${GLOBAL_DAILY_LIMIT},APP_CHECK_ENFORCE=${APP_CHECK_ENFORCE}${FIREBASE_PROJECT_NUMBER:+,FIREBASE_PROJECT_NUMBER=$FIREBASE_PROJECT_NUMBER}"

URL="$(gcloud run services describe "$SERVICE" \
  --project "$PROJECT_ID" --region "$REGION" --format 'value(status.url)')"

echo
echo "==> deployed: $URL"
echo "==> smoke test"
curl -fsS "$URL/health" && echo "  health ok"

# A POST with no body must be refused, not forwarded — proves the guard rails
# are live without spending a Gemini call.
code="$(curl -s -o /dev/null -w '%{http_code}' -X POST "$URL/v1beta/models/nope:generateContent")"
[[ "$code" == "403" || "$code" == "404" ]] && echo "  model guard ok ($code)"

echo
echo "Next: put this in app/dev.env"
echo "  EXTRACTION_PROXY_URL=$URL"
