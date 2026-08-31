# GCP / Firebase project facts — MyReciBook

*Written down 2026-08-21 because Arnar had supplied these repeatedly and they
kept living in chat instead of a file. Workflow law 2: not in a repo file =
does not exist. Check values live before trusting them; this file is the
address book, not the source of truth for anything that changes.*

## MyReciBook-Dev — the dev/test project

| Field | Value |
|---|---|
| Project name | MyReciBook-Dev |
| Project ID | `gen-lang-client-0166122901` |
| Project number | `213431165631` |
| Parent org | merkurial-studio.com |
| Support email | arnarvalurjonsson@gmail.com |
| Billing | Blaze (pay as you go) |
| Firestore | `(default)` database, created 2026-08-21 |

The project number is also the prefix of the Drive OAuth client already in
`app/android/app/src/main/AndroidManifest.xml`
(`com.googleusercontent.apps.213431165631-…`) — same project, as expected.

## MyReciBook (prod) — created 2026-08-31

| Field | Value |
|---|---|
| Project name | MyReciBook |
| Project ID | `myrecibook-prod` |
| Project number | `283856393795` |
| Parent org | merkurial-studio.com |
| Firebase | linked 2026-08-31, environment type **Production** |
| Billing | linked 2026-08-31, account `01C8DA-8CC208-A7AA68` |
| Cloud Run | `myrecibook-website`, europe-west1, live 2026-08-31 |

Website deployed 2026-08-31 via `website/deploy-prod.sh` —
https://myrecibook-website-283856393795.europe-west1.run.app. Domain mapping
to myrecibook.com pending. The production proxy and Firestore land here
before anyone pays. `gen-lang-client-0166122901` stays the dev/test
project — do not point release builds at it.

## Where these values are consumed

| Value | Used by |
|---|---|
| Project ID | `proxy/deploy.sh` (`PROJECT_ID`), Cloud Run injects it as `GOOGLE_CLOUD_PROJECT` for the Firestore ledger |
| Project number | `FIREBASE_PROJECT_NUMBER` env var — App Check token `iss`/`aud` verification (`proxy/lib/app_check.dart`) |
| Android package | `com.merkurialstudio.myrecibook` — Firebase app registration, Play Console |

## Production still missing

**Everything except the website is still dev/test.** Prod still needs its own: Gemini auth key, Secret Manager secret,
Firestore database, Cloud Run service and URL, budgets, and App Check
registration with the Play App Signing fingerprint. The only thing shared is
the source. §4 item 9 of `docs/ai-cap-mechanics.md` calls for two
projects, prod and test, with separate keys and separate caps. NEEDS ARNAR when
the internal track graduates.
