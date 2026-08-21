# Runbook — deploy the extraction proxy to MyReciBook-Dev

*Written 2026-08-21, then partly executed the same evening once gcloud turned
up. Steps are marked DONE as they actually complete — anything not marked DONE
has not happened.*

**gcloud lives at `~/google-cloud-sdk/bin` and is NOT on PATH.** Prefix it, or:
`export PATH="$HOME/google-cloud-sdk/bin:$PATH"`.

Project identifiers: [gcp-project-facts.md](gcp-project-facts.md).
Cap and control design: [ai-cap-mechanics.md](ai-cap-mechanics.md) §1, §3, §4.

---

## What is already true

- **DONE** — Firestore `(default)` database exists on MyReciBook-Dev (Arnar,
  2026-08-21). Billing is Blaze.
- **DONE** — the proxy code is written and tested: durable Firestore ledger,
  App Check verification behind a flag, per-bucket minute AND day limits,
  global daily breaker, reserve-before-Gemini with refund on failure. 30 tests
  green, and it boots and answers correctly locally (in-memory ledger).
- **DONE** — App Check registered for `com.merkurialstudio.myrecibook` with the
  Play Integrity provider, upload + debug fingerprints added (Arnar,
  2026-08-21). Enforcement is still OFF, which is correct until a build
  carrying tokens is on the internal track.
- **DONE 2026-08-21** — **the proxy is DEPLOYED and verified end to end.**
  `https://myrecibook-proxy-213431165631.europe-west1.run.app`, revision
  00003. A real Gemini call went through it, the Firestore ledger persisted
  (`quota/{id}` + `control/global`), and the 10/min limiter refused calls
  11-13 live. Gemini key is in Secret Manager only — a release APK was built
  and contains no `AIza` string.
- **NOT DONE** — budgets and prepay credits (Arnar's), google-services.json,
  Play App Signing fingerprint, App Check enforcement.

---

## 0 · gcloud — DONE

SDK 570.0.0 at `~/google-cloud-sdk/bin`, authed as arnarvalurjonsson@gmail.com
(arnarvalur@avj.info is also credentialed but not active). The `core/project`
config points at a different project, so **every command here passes
`--project` explicitly** rather than relying on it.

## 0b · APIs — DONE 2026-08-21

Enabled on MyReciBook-Dev: `run`, `secretmanager`, `cloudbuild`,
`artifactregistry`, `firebaseappcheck`. Firestore and generativelanguage were
already on. Billing account `01C8DA-8CC208-A7AA68`, active.

---

## 1 · Firestore security rules — lock clients out

Firebase console → **Firestore → Rules**. Replace with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} { allow read, write: if false; }
  }
}
```

**Publish.** The proxy reaches Firestore as a service account, which bypasses
rules entirely — so denying every client is correct, not restrictive. Without
this, the quota ledger is world-writable and the cap means nothing.

---

## 2 · The Gemini key → Secret Manager — DONE 2026-08-21

Secret `gemini-api-key` created (version 1, enabled), and
`roles/secretmanager.secretAccessor` granted to the Cloud Run runtime account.
`app/dev.env` no longer holds the key — it holds `EXTRACTION_PROXY_URL`
instead, and a release build proved the APK carries no key.

**The existing key is fine here** (Arnar, 2026-08-21). This is the dev/test
project and its testers; a fresh key gets minted and stored for **prod**, as
part of the prod project's own setup — not this one.

> Carry into the PROD setup, not here: §4 item 2 — classic API keys are
> rejected from **September 2026**. The prod key must be an "auth key",
> service-account bound and restricted to the Generative Language API.

Google Cloud console → **Security → Secret Manager → Create secret**
- Name: `gemini-api-key`
- Secret value: the key, no quotes, no trailing newline
- Create

Then let Cloud Run read it:

```sh
PROJECT_NUMBER=213431165631
gcloud secrets add-iam-policy-binding gemini-api-key \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

---

## 3 · Let Cloud Run write the ledger — DONE 2026-08-21

`roles/datastore.user` granted to
`213431165631-compute@developer.gserviceaccount.com`, the Cloud Run runtime
service account.

Without this the proxy **refuses to boot** rather than running unmetered —
that refusal is deliberate (audit B2).

---

## 4 · Deploy — DONE 2026-08-21

```sh
cd proxy
./deploy.sh
```

Two traps hit on the first run, both fixed in code — do not re-introduce them:

1. **Cloud Run reserves `/healthz`.** Its frontend answers with its own 404
   HTML and never forwards to the container. The health endpoint is `/health`.
2. **Cloud Run does NOT set `GOOGLE_CLOUD_PROJECT`** (that is App Engine and
   Cloud Functions). Revision 1 silently fell back to the in-memory ledger —
   the exact failure audit B2 exists to prevent. `deploy.sh` now passes the
   variable explicitly, the server falls back to the metadata server, and it
   **refuses to boot** if it is on Cloud Run with no durable ledger.

Also needed once, and now granted: `cloudbuild.builds.builder`,
`storage.objectViewer`, `artifactregistry.writer`, `logging.logWriter` on the
compute service account, or the source deploy fails on a storage 403.

App Check stays OFF here. The script prints the service URL and runs two smoke
checks (`/health`, and a disallowed model that must be refused).

Firestore is **`eur3`** (Europe multi-region: Belgium + Netherlands), so
`deploy.sh` defaults to **`europe-west1`** to keep ledger reads local. Checked
2026-08-21 — do not "fix" it back to europe-north1.

---

## 5 · Point the dev build at it — DONE 2026-08-21

`app/dev.env` (gitignored, never committed) now reads:

```
EXTRACTION_PROXY_URL=https://myrecibook-proxy-213431165631.europe-west1.run.app
```

with `GEMINI_API_KEY` removed. Verified on a real release build: the APK
contains the proxy URL and no `AIza` string anywhere.

To re-check after any build:

```sh
unzip -q -o build/app/outputs/flutter-apk/app-release.apk -d /tmp/apkcheck
grep -rhoaE 'AIza[A-Za-z0-9_-]{35}' /tmp/apkcheck   # must print nothing
```

---

## 6 · Spend caps — do these before real traffic

Google Cloud console → **Billing → Budgets & alerts**.

| Budget | Scope | Amount | Type |
|---|---|---|---|
| Gemini | Generative Language API | $50/mo | spend-cap |
| Cloud Run | Cloud Run | $10/mo | spend-cap |
| Tripwire | whole billing account | Arnar's number | alerts only |

Also: **prepay Gemini credits with auto-reload OFF** (§3 layer 4). Balance hits
zero → the key stops. A runaway bill becomes structurally impossible rather
than merely monitored. This is the layer that actually caps the downside;
everything else is a speed bump.

Cost ceiling Arnar set: ~100–200 NOK/mo acceptable, expected spend ≈ 0.

---

## 7 · Crashlytics — the config file

Firebase console → **Crashlytics** → Add Firebase to your Android app.

- Android package name: `com.merkurialstudio.myrecibook`
- App nickname: anything
- Register → download `google-services.json`
- Put it at **`app/android/app/google-services.json`**

Skip the console's SDK and Gradle steps — already in the code. The Gradle
plugins apply only when that file exists, so the build works with or without
it; dropping the file in is the entire switch.

The in-app toggle (Settings → Crash reports) ships **OFF**. Flipping the
default is one constant: `kCrashReportingDefaultOn` in
`app/lib/data/crash_reporter.dart`. **OPEN — Arnar's call.**

---

## 8 · App Check — the flip that closes the billing hole

This is audit B1: until it is on, anyone who pulls the proxy URL out of the APK
can spend Gemini on Arnar's card, because `X-Install-Id` is a header the client
makes up.

1. **DONE 2026-08-21** — App Check → Apps → MyReciBook registered with the
   **Play Integrity** provider. It asks for SHA-256 certificate fingerprints;
   add all of these, or builds signed with the missing one cannot attest:

   | Key | SHA-256 | Where it comes from |
   |---|---|---|
   | Upload | `86:05:F0:D3:25:E6:8A:13:60:22:59:48:46:DF:E1:20:F6:ED:30:8B:E3:A7:90:B0:05:EB:11:0C:96:A6:C6:A7` | `~/keystores/myrecibook-upload.jks` (added 2026-08-21) |
   | Debug | `86:C8:8C:1A:61:AF:4D:0C:DE:8F:E4:7B:F8:C5:2F:CD:0E:95:6B:3A:22:4D:7F:06:6D:38:E7:17:04:56:F5:C6` | `~/.android/debug.keystore` (added 2026-08-21) |
   | **Play App Signing** | **NEEDS ARNAR — not yet known** | Play Console → Setup → App signing, after the first upload |

   The third one is the trap: Play re-signs every upload with its own key, so
   an app installed FROM Play is signed by a certificate neither of the first
   two rows covers. Add it right after the first bundle upload.

   Re-read the fingerprints any time with:
   ```sh
   keytool -list -v -keystore ~/keystores/myrecibook-upload.jks -alias upload | grep SHA256:
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey \
     -storepass android | grep SHA256:
   ```
2. For dev builds: App Check → **Manage debug tokens** → add the token the app
   prints in logcat on first run with the debug provider.
3. Leave enforcement OFF until a build carrying App Check tokens is on the
   internal track. Then, the one line:

```sh
cd proxy && APP_CHECK_ENFORCE=true ./deploy.sh
```

The proxy fails **closed** once enforced: no valid token, no extraction. Verify
before trusting it — a plain `curl` to the extraction path must come back 401.

> **DONE 2026-08-21** — the app side is wired: `firebase_app_check` is a
> dependency, `app/lib/data/app_check.dart` activates it (Play Integrity in
> release, debug provider in debug), and `gemini_extractor.dart` attaches the
> `X-Firebase-AppCheck` header on every proxy call. With no Firebase config
> the header is simply absent, which is why the flip must wait for a build
> that actually carries `google-services.json`.

---

## 9 · Still open, not done here

- **Voided Purchases cron** (§1 step 4) — needs billing to exist first.
- **Purchase-token bucket keys** — the ledger already takes an opaque key;
  switching from install id to `sha256(purchaseToken)` is one line in
  `proxy/lib/proxy.dart` plus the app sending it.
- **Grace window seeding.** The offer is 14 days free then 1200/year, and
  that is what ships. Pre-billing the window starts at first contact; once
  billing exists it MUST be seeded from Google's `purchaseTimeMillis` (§1) or
  a reinstall restarts the free fortnight.
- **Spend-rate governor:** 50/bucket/day (`PER_DAY_LIMIT`), applied during
  grace too. Free spending is still recorded in `graceUsed` — free is not
  unmeasured.
- **Production GCP project** — §4 item 9 wants prod separate from test.
