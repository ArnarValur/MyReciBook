# Scratchpad

Arnar's notes. Conductor never writes here.

- Grocery list needs a bit of a revamp — ask Arnar what he wants changed.
- Internationalization: can we offer languages?
- Export recipes as PDF? If Google Drive connected, open in Google Docs?
- Need a way for users to send feedback / error reports.
- App update mechanism for installed app — presume Google Play standard update flow, confirm.
- Can we import recipes from other apps? Research feasibility.

## 2026-08-20 — crash visibility, discussed

- Feedback received: the ring-buffer log only leaves the phone if a tester copies it
  out by hand, so in production real failure rates stay invisible.
- Play Console → Android vitals already collects crash and ANR rates for free, no
  code, no SDK. TODO: go look at it for 0.6.0+3.
- Firebase Crashlytics is the Flutter/Google standard for stack traces and for
  handled-but-wrong errors that never kill the app. Free tier.
- Constraint 3 "no backend" means no custom server or CMS Arnar maintains — not
  managed Google infra. Firebase joins the existing GCP project that holds the
  Gemini key. Arnar's reading, agreed.
- TODO (later session, before the closed test widens): two packages,
  google-services.json, two Gradle plugins, error hooks in app startup, ring buffer
  wired in as breadcrumbs, recipe text scrubbed before upload. Startup and build
  config only — no screen or recipe code touched.
- OPEN, Arnar's call: crash reporting on by default with an off switch in settings,
  versus off until the user opts in. It is a promise to users, not a technical choice.
- No Dart obfuscation — it would make crash reports unreadable to us too.
  deploy-s21.sh is already correct; nothing to change.
- App Check becomes available once Firebase is on the project. It gates who can call
  endpoints but does NOT replace the proxy's per-purchase cap counter. Do not chase.
- Arnar decided: remove the delete-screenshot toggle from import review altogether
  (app/lib/ui/import_review_screen.dart, currently off by default). If deletion ever
  misfires the original screenshot is gone for good.
- Scratchpad line "need a way for users to send feedback / error reports" is what
  this thread was about — Crashlytics covers the error half, feedback still open.
