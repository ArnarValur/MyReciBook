# Senior Architecture Review — MyReciBook
*2026-08-08 · full codebase pass (lib/data, lib/domain, lib/ui, Kotlin bridges, tests, Android config) · every finding below was adversarially re-verified against the code, not taken from a first read. Refuted claims are listed at the bottom so they don't resurface.*

## Verdict

**The architecture is right and needs no rework before alpha.** Layering is clean (pure domain → injectable data → Provider UI), test ratio is healthy (~300 cases, test:code ≈ 1:1), native side is small and defensive. The dangerous findings are all in **Android release config**, not in the Dart — two of them will hard-block the 19 Oct closed track if untouched.

---

## 1. What is good — do not churn

| Area | Why it's right | Evidence |
|---|---|---|
| Domain purity | `lib/domain/` has zero Flutter imports; grocery engine is pure functions returning new state | [grocery.dart](app/lib/domain/grocery.dart) |
| DI seams | Every platform edge (MethodChannel, http, file paths, clock/waits) is injected; `buildApp()` is an explicit test seam | [main.dart:149](app/lib/main.dart) |
| Atomic writes | tmp+rename everywhere app-private state persists | [token_store.dart:50](app/lib/data/token_store.dart), [sync_engine.dart:188](app/lib/data/sync_engine.dart) |
| Error philosophy | Three tiers: degrade (foreign/corrupt files), retry (transient IO → offline state), escalate (GrantLost → re-pick flow). No load path can crash on bad data | [saf_store.dart:131](app/lib/data/saf_store.dart), [recipe_store.dart:68](app/lib/data/recipe_store.dart) |
| OAuth | Public client + PKCE S256 + state check; no secrets in the APK; placeholder creds fail honestly as `notConfigured` | [oauth.dart:164-206](app/lib/data/oauth.dart) |
| StorageModel honesty rule | Never claims "synced" without a completed pass — this is the single best defense against sync bug reports you can't reproduce | [storage_model.dart:140](app/lib/ui/storage_model.dart) |
| State management | Plain Provider + ChangeNotifier, models never reference each other (glue lives in main.dart), granular `watch` scopes, careful disposal. Right-sized for solo dev; Riverpod migration would be churn, not improvement | [main.dart:163-214](app/lib/main.dart) |
| UI hygiene | No god-widgets (largest screen 736 lines, mostly helpers), no whole-tree rebuilds, feature flags instead of dead-end surfaces | [features.dart](app/lib/features.dart) |
| Native bridges | 518 lines Kotlin total; intent routing dedupes history relaunches, auth redirect can never reach ShareBridge | [MainActivity.kt](app/android/app/src/main/kotlin/com/merkurialstudio/myrecibook/MainActivity.kt) |

**Senior take:** this is an unusually disciplined codebase for a pre-alpha solo project. The comments explain *why* at every decision point, invariants are documented where they're enforced, and known debt is labeled with its payoff date. Whatever process produced this — keep it.

---

## 2. Findings — verified, ranked

### 🔴 F1 — Release build has no network. Blocks 19 Oct.
`INTERNET` permission exists only in the **debug** and **profile** manifests. The main manifest has zero `<uses-permission>` lines, and no plugin contributes it. Your debug APKs work; the release AAB you must upload for the closed track will fail every network call — Gemini extraction, OAuth, Drive, Dropbox — silently, as IO errors.
**Fix (2 min):** add `<uses-permission android:name="android.permission.INTERNET"/>` to [app/android/app/src/main/AndroidManifest.xml](app/android/app/src/main/AndroidManifest.xml).
**If ignored:** the first release build looks completely broken on testers' phones and burns closed-test days on a config bug.

### 🔴 F2 — Release signing is the debug keystore. Blocks 19 Oct.
[build.gradle.kts:29-33](app/android/app/build.gradle.kts) still has the Flutter template's `signingConfig = signingConfigs.getByName("debug")` TODO. No `key.properties`, no keystore in the repo. Play Console rejects debug-signed uploads.
**Fix (~30 min):** generate an upload keystore, wire `key.properties` (gitignored), enroll in Play App Signing at first upload. Pulse already tracks the Play-signing SHA-1 → Drive client errand; this is its prerequisite.
**If ignored:** you discover it the night you try to upload the alpha.

### 🟠 F3 — Gemini API key ships in the binary, and rides the URL.
[gemini_extractor.dart:18](app/lib/data/gemini_extractor.dart) compiles the key in via `--dart-define`; verified extractable with `strings` from the built APK (survives `--obfuscate` — that only renames identifiers). It's also sent as `?key=` query param, so it lands in any intermediary's request logs. Known and scheduled (D2 proxy before 11 Dec) — the verification confirms **no proxy code exists yet**, so the ~1 h client swap plus the Cloud Run deploy is all still ahead of you.
**Bar:** fine for the closed track; a public release with this key is a billable-key leak. D2 stays a hard pre-launch gate.

### 🟠 F4 — Plaintext refresh tokens meet default backup.
[token_store.dart:50](app/lib/data/token_store.dart) is known debt (parked in pulse), but the manifest has no `allowBackup`/`dataExtractionRules`, so Android's default **backs `tokens.json` up** into Google Auto Backup and D2D transfers. Scopes are narrow (drive.file, app-folder) and backups are lockscreen-encrypted since Android 9, so severity is low — but the fix is cheap.
**Fix (10 min now):** `dataExtractionRules` excluding `tokens.json`; keystore-backed storage stays the pre-prod hardening item.

### 🟠 F5 — Two-device sync is silently last-writer-wins.
[sync_engine.dart](app/lib/data/sync_engine.dart) is an honest, documented one-way mirror — and it's *safer* than a first read suggests (verified: it never deletes remote-only files it didn't upload, and restore-down can't clobber local files). But: a recipe edited on device B, or directly in Drive/Dropbox, is silently overwritten next time device A edits it, and diverged copies never reconcile. `RemoteEntry.rev` exists and is never checked.
**Bar:** correct v1 scope — do **not** build 2-way sync now. Two cheap mitigations before launch: state "one phone at a time" in the listing/FAQ, and consider a rev-mismatch check that skips + surfaces instead of overwriting (small, uses the field you already have).

### 🟡 F6 — Crash visibility is zero, and telemetry is ruled out.
No `FlutterError.onError`, `PlatformDispatcher.onError`, or `runZonedGuarded` anywhere. With D8 (no telemetry) as a standing decision, an uncaught release error during the 14-day closed test vanishes — 12 testers, no crash story, no repro.
**Fix (~1 h, respects D8):** ring-buffer handler writing the last N errors to an app-private file + "share logs" row in Settings. Testers self-serve the evidence; nothing leaves the device without a deliberate share.

### 🟡 F7 — Small verified oddments
- **Orphaned images accumulate forever:** save writes images before JSON, so a mid-save failure leaves unreferenced image files; nothing ever scans or GCs them ([recipe_store.dart:104-124](app/lib/data/recipe_store.dart)). Graceful, invisible, unbounded. Post-alpha: sweep on rescan.
- **Recipe JSON has no tmp+rename:** app-private stores do it; the recipe files themselves don't — a mid-write kill leaves a truncated JSON that loads as "skipped" (never crashes, verified). Cheap parity fix when convenient; SAF makes it harder (create+write, no rename), so don't force it pre-alpha.
- **Schema forward-compat:** a future `schema_version: 2` file is silently skipped from the library (blocking-problem path, verified — no crash). Fine now; write the read-tolerant policy before any v2 format ships.
- **ShareBridge filename:** cache file extension derives from sender-controlled `DISPLAY_NAME` without stripping `/` ([ShareBridge.kt:160](app/android/app/src/main/kotlin/com/merkurialstudio/myrecibook/ShareBridge.kt)). The 5-char cap bounds it; one-line sanitize anyway.
- **`GoogleFonts.config.allowRuntimeFetching = false`** is set in test config only, not [main.dart](app/lib/main.dart) — one line, guarantees offline font honesty in release.
- **Lints:** stock `flutter_lints`, no `strict-casts`/`strict-raw-types`. One-time `analysis_options.yaml` tightening; do it on a quiet evening, not mid-feature.
- **Accessibility:** zero `Semantics`/`tooltip` in lib/; Play's pre-launch report will flag bare `IconButton`s. ~1 evening pass before store listing (16 Nov window), not before alpha.

---

## 3. Path to release — mapped to the existing schedule

**Now → 19 Oct (alpha):**
1. F1 + F2 the next time the repo is open — they're the only true blockers. *(~45 min)*
2. F4 backup-exclusion line while the manifest is open. *(10 min)*
3. Storage smoke on the S21 (already queued in pulse) — it validates OAuth + sync end-to-end, which this review could only read, not run.
4. F6 crash ring-buffer before testers install — it pays for itself with the first weird report. *(~1 h)*

**19 Oct → 11 Dec (production):**
5. D2 proxy (Cloud Run) + key out of the client — already parked with the right deadline; F3 confirms nothing is built yet, so budget the deploy, not just the "~1 h client swap".
6. Token hardening (keystore-backed) + Dropbox production approval + Play-signing SHA-1 on the Drive client — all already in pulse's parked list; this review adds nothing new there, which is itself a good sign.
7. F5 listing copy ("one phone at a time") + optional rev-check; F7 accessibility pass in the 16 Nov–10 Dec listing window.

**Explicitly not recommended:** state-management migration, go_router, 2-way sync, schema v2, repo restructure. All would be churn against a sound design. Gate 3's bar is 1,000 downloads / $500 — every hour must go to shipping, not re-architecting.

---

## 4. Claims checked and refuted (so they don't come back)

- **"GroceryStore write queue can persist stale state / swallows errors dangerously"** — REFUTED. State mutates before enqueue, every write serializes the full snapshot FIFO, the returned future does propagate errors, and GroceryModel awaits them; only the internal chain-continuation swallows, which is the correct anti-poisoning pattern. Un-awaited UI calls are safe by design. ([grocery_store.dart:120-134](app/lib/data/grocery_store.dart))
- **"fromJson crashes on missing schema_version"** — refuted; every path pre-validates or catch-alls to null/skip.
- **"Sync can delete a second device's files / restore-down can clobber local"** — refuted; deletes are gated on device-owned manifest names, restore-down is strictly additive. The real risk is the narrower F5.
