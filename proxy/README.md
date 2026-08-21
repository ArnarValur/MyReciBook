# Extraction proxy (D2)

Holds the Gemini key server-side so it never ships in the APK (senior review
F3). Transparent relay for the one call the app makes; refuses everything else.
Request bodies are never stored or logged (context.md constraint 3).

Hardened 2026-08-21 against the pre-launch audit — see
[`docs/pre-launch-audit-2026-08-21.md`](../docs/pre-launch-audit-2026-08-21.md)
findings B1–B3. Cap and control design:
[`docs/ai-cap-mechanics.md`](../docs/ai-cap-mechanics.md) §1, §3, §4.

## What it does, in order

1. **Shape check** — POST only, `v1beta/models/<model>:generateContent` only,
   model on the allowlist, body under 25 MB counted as it streams. A leaked
   proxy URL is not a general-purpose Gemini key.
2. **App Check** — verifies a Firebase App Check JWT (Play Integrity attests
   the caller is really this app on a real device). Behind
   `APP_CHECK_ENFORCE`; **fails closed** when on.
3. **Reserve** — one atomic Firestore transaction walks the spending ladder
   (grace → included allowance → top-up → gentle stop), applies the per-bucket
   minute and DAY limits and the global daily breaker, and charges the slot **before**
   Gemini is called. Parallel batch items cannot overshoot a nearly-empty cap.
4. **Relay** — the request goes upstream with the key as an `x-goog-api-key`
   header, never in a URL.
5. **Refund** — any failure (timeout, unreachable, upstream 4xx/5xx) hands the
   slot back. "A failed extraction is 0 rescues" is kept by this step.
6. **Report** — a success returns `"quota": {used, cap, …}` alongside Gemini's
   content, so the app's counter UI stays current with no extra call.

## Run locally

```sh
cd proxy
dart pub get
GEMINI_API_KEY=<dev key> dart run bin/server.dart
# smoke: curl -s localhost:8080/health
```

Local runs use the **in-memory** ledger and say so on boot. That is honest for
a single process and wrong for anything else — which is exactly why the
deployed proxy refuses to start if it cannot reach Firestore.

## Deploy

```sh
./deploy.sh                          # App Check off (closed track)
APP_CHECK_ENFORCE=true ./deploy.sh   # the flip, once the app carries tokens
```

**Never run yet** — gcloud was not installed on PlutoII as of 2026-08-21.
One-time setup (Firestore rules, Secret Manager, IAM, budgets) is in
[`docs/runbook-dev-deploy.md`](../docs/runbook-dev-deploy.md).

## Wire the app to it

Put `EXTRACTION_PROXY_URL=https://…` in `app/dev.env` and **remove
`GEMINI_API_KEY`** from it. Without the define the app talks to Gemini directly
with a key on the device — dev only, never a shipped build.

## Env

| Var | Default | Meaning |
|---|---|---|
| `GEMINI_API_KEY` | — (required) | server-held key; Secret Manager on Cloud Run |
| `GOOGLE_CLOUD_PROJECT` | — | injected by Cloud Run; its presence selects the Firestore ledger |
| `YEARLY_CAP` | `1200` | per-bucket fair-use cap |
| `PER_MINUTE_LIMIT` | `10` | per-bucket rate limit (§3 layer 2) |
| `PER_DAY_LIMIT` | `50` | per-bucket daily ceiling — nobody drains a year in an afternoon |
| `GRACE_DAYS` | `14` | the free fortnight |
| `GLOBAL_DAILY_LIMIT` | `2000` | circuit breaker across all buckets (§3 layer 3) |
| `APP_CHECK_ENFORCE` | `false` | require a verified App Check token |
| `FIREBASE_PROJECT_NUMBER` | — | needed to verify App Check `iss`/`aud` |
| `ALLOWED_MODELS` | `gemini-3.5-flash-lite` | comma-separated allowlist |
| `PORT` | `8080` | injected by Cloud Run |

## Ledger document

`quota/{bucketKey}` — one per buyer. Pre-billing the key is the install id;
after billing it becomes `sha256(purchaseToken)`, which is a one-line change
because the ledger only ever sees an opaque string.

```
status  cap  used  graceUsed  topupBalance  resetsAt  graceUntil
windowStart  windowCount  day  dayCount  test
```

`control/global` holds `{day, count}` for the breaker. Counters, timestamps and
a status — no recipe content, ever.

## Abuse surface, stated honestly

With App Check **enforced**, a caller needs a Play-Integrity-attested device
running this app, signed by a registered certificate. That is the real gate.

With App Check **off** — the current closed-track setting — anyone holding the
URL can spend capped extractions against a bucket id they invent. The cap,
rate limit and daily breaker bound the damage; they do not prevent it. This is
acceptable only while the URL has not shipped anywhere public.

**The offer:** first two weeks free, then 1200 over the year. Free spending is
recorded in `graceUsed` — free is not unmeasured — with a quiet ceiling of 300
that falls through to normal counting rather than stopping.

**The governor:** 50/bucket/day, applied during grace as well. At 1200/year the
honest average is ~3/day, so 50 is generous for a cook and ruinous for a
scraper: a floor of 6 days on the 300 free rescues, 24 days on a full year. It
answers "not today", never "never" — the refusal says the allowance is
untouched and resets tomorrow.
