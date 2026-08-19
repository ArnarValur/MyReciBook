# Extraction proxy (D2)

Holds the Gemini key server-side so it never ships in the APK (senior review
F3). Transparent relay for the one call the app makes; refuses everything
else. State = the per-install fair-use counter, nothing more — request bodies
are never stored or logged (context.md constraint 3).

## Run locally

```sh
cd proxy
dart pub get
GEMINI_API_KEY=<dev key> dart run bin/server.dart
# smoke: curl -s localhost:8080/healthz
```

## Deploy (Cloud Run — NOT DONE YET, needs Arnar: gcloud auth + billing on
gen-lang-client-0166122901; free tier covers closed-track volume)

```sh
gcloud run deploy myrecibook-proxy --source proxy/ \
  --region europe-north1 --allow-unauthenticated \
  --set-secrets GEMINI_API_KEY=gemini-api-key:latest \
  --max-instances 1
```

`--max-instances 1` = cost ceiling AND keeps the in-memory cap counter
coherent. A durable counter store is a later decision (pulse: cap counter 4d).

## Wire the app to it

Build with `--dart-define=EXTRACTION_PROXY_URL=https://<cloud-run-url>` and
drop `GEMINI_API_KEY` from the build. Without the define, the app talks to
Gemini directly (dev mode, key on device — closed-track OK, production NO).

## Env

| Var | Default | Meaning |
|---|---|---|
| `GEMINI_API_KEY` | — (required) | server-held key |
| `ALLOWED_MODELS` | `gemini-3.5-flash-lite` | comma-separated allowlist |
| `FREE_MONTHLY_CAP` | `100` | per-install/month backstop — strawman, Arnar sets the listed number |
| `PORT` | `8080` | injected by Cloud Run |

## Abuse surface, stated honestly

Anyone with the URL + a well-formed install id can spend capped extractions.
Raising the bar further (Play Integrity attestation) is a production errand,
not an alpha one — parked alongside Dropbox production approval.
