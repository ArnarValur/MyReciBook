# Prod setup plan — myrecibook-prod (GCP + Firebase)

*Written 2026-08-31. Address book: docs/gcp-project-facts.md. Everything below
targets project `myrecibook-prod` (number 283856393795). Nothing here touches
MyReciBook-Dev, and nothing here blocks this week's internal test — the
internal build rides dev on purpose.*

## Slice 1 — website live on myrecibook.com (unblocks the Play paperwork)

The closed-test forms need a public privacy-policy URL. That is this slice.

1. **Billing** — link a billing account to myrecibook-prod. NEEDS ARNAR (console).
2. **Budget alert** — set a budget (suggest $10/mo, alerts at 50/90/100%).
   NEEDS ARNAR (amount is his call).
3. **Enable APIs** — run.googleapis.com, cloudbuild.googleapis.com,
   artifactregistry.googleapis.com. One gcloud command.
4. **Deploy website** — `PROJECT_ID=myrecibook-prod SERVICE=myrecibook-website
   website/deploy-staging.sh` (script is already parameterized; consider a
   deploy-prod.sh wrapper so the name stops saying staging).
5. **Map the domain** — Cloud Run domain mapping for myrecibook.com + www,
   then the DNS records it prints go into Namecheap. Cert is automatic,
   propagation up to a day. NEEDS ARNAR (Namecheap login).
6. **Contact form target** — the site posts to the DEV proxy URL today. Either
   leave it (form keeps working, mail still lands) or repoint at the prod proxy
   when Slice 2 exists. Origin allowlist on the dev proxy already includes
   myrecibook.com, so leaving it needs no change. Decision, not work.

## Slice 2 — prod proxy + Firebase (before anyone pays; NOT needed for testers)

7. **Enable APIs** — secretmanager, firestore, generativelanguage.
8. **Gemini key** — new API key created inside myrecibook-prod, into Secret
   Manager as `gemini-api-key`. NEEDS ARNAR (key creation). Dev key stays dev.
9. **Brevo key** — same Brevo account, copy the REST key into prod Secret
   Manager as `brevo-api-key` (or mint a second key at Brevo, cleaner).
10. **Firestore** — create `(default)` database, multi-region `eur3`
    (matches europe-west1, same as dev). Holds only the cap ledger.
11. **Deploy proxy** — `PROJECT_ID=myrecibook-prod
    FIREBASE_PROJECT_NUMBER=283856393795 proxy/deploy.sh`. Script already
    takes both. Note the new URL.
12. **Firebase on prod** — add Firebase to myrecibook-prod, register Android
    app `com.merkurialstudio.myrecibook` (same package in two Firebase
    projects is allowed), download the prod google-services.json.
13. **google-services.json switch** — app has ONE google-services.json (dev).
    Needs a per-build swap (flavors, or a copy step in the release script)
    so dev builds keep dev Crashlytics and release builds report to prod.
    Small task, decide the mechanism when Slice 2 starts.
14. **App Check** — register Play Integrity provider with the **Play App
    Signing SHA-256** from Play Console. That fingerprint only exists after
    the first .aab upload — today's internal upload unlocks this step.
15. **prod.env** — `EXTRACTION_PROXY_URL=<prod URL>` + prod dart-defines;
    release builds switch from dev.env to prod.env.
16. **Drive OAuth** — the Drive client lives in the DEV project (its number
    is baked in AndroidManifest.xml). Prod needs its own OAuth consent screen
    + client, and Drive scopes trigger Google's app-verification review,
    which can take weeks. LOUD GATE: start this early, do not leave it for
    launch week. NEEDS ARNAR (consent screen owner).

## Order of operations
Slice 1 now (paperwork gate) → internal test runs on dev the whole time →
Slice 2 when the paywall/billing seam work starts → App Check enforce flip
(`APP_CHECK_ENFORCE=true`) last, after release builds prove themselves.
